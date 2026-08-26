// Agrega noticias sobre pets de feeds RSS e publica na colecao `news` do
// Firestore, no mesmo formato que o app ja le hoje.
//
//   node agregar.js --simular   imprime o que seria publicado, sem escrever
//   node agregar.js             publica de verdade (exige credencial)
//
// A credencial vem da variavel de ambiente FIREBASE_SERVICE_ACCOUNT, com o
// JSON da conta de servico. No GitHub Actions ela e um secret do repositorio.

import Parser from 'rss-parser';
import { pathToFileURL } from 'node:url';
import {
  criarCliente,
  escolherModelo,
  extrairTexto,
  iaDisponivel,
  resumir,
  VERSAO_DA_DICA,
} from './resumir.js';
import {
  FEEDS,
  TERMOS_INCLUSAO,
  TERMOS_EXCLUSAO,
  LIMITE_DE_NOTICIAS,
  IDADE_MAXIMA_EM_DIAS,
  JANELA_EM_DIAS,
  MINIMO_DE_NOTICIAS,
  SINAIS_DE_GUIA,
  SINAIS_DE_NOTICIA,
} from './fontes.js';

const SIMULAR = process.argv.includes('--simular');

/**
 * User-Agent de navegador.
 *
 * Nao e disfarce por esporte: o WAF da Petz responde 403 para qualquer coisa
 * que nao siga o padrao de navegador - testei identificando o projeto e
 * tambem tomei 403. Sao feeds RSS publicos, feitos para serem lidos por
 * programa, e o bloqueio e por formato do cabecalho, nao por quem somos.
 */
const NAVEGADOR =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36';

const parser = new Parser();

/**
 * Baixa o XML do feed e entrega ao parser ja como texto.
 *
 * O rss-parser sabe buscar sozinho, mas o cliente HTTP interno dele toma 403
 * da Petz mesmo mandando os mesmos cabecalhos com que o fetch passa - a
 * diferenca esta abaixo do cabecalho, na assinatura da conexao. Buscar com
 * fetch resolve e ainda deixa um so caminho de rede no arquivo.
 */
async function baixarFeed(url) {
  const resposta = await fetch(url, {
    redirect: 'follow',
    signal: AbortSignal.timeout(20000),
    headers: { 'User-Agent': NAVEGADOR },
  });
  if (!resposta.ok) throw new Error(`status ${resposta.status}`);
  return parser.parseString(await resposta.text());
}

/** Remove acento e caixa, para o filtro nao depender de como foi escrito. */
function normalizar(texto) {
  return (texto || '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase();
}

/** Tira tags HTML e espaco sobrando das descricoes, que vem com markup. */
function limparTexto(html) {
  return (html || '')
    .replace(/<[^>]*>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * Tira o entulho que os feeds trazem no lugar de resumo: rodape de WordPress
 * ("O post X apareceu primeiro em Y") e cabecalho de data que o CFMV inclui
 * no corpo ("25/08/2026 - Atualizado em 25/08/2026 - 8:56am ...").
 */
function limparEntulho(texto) {
  return texto
    .replace(/\bO post .*?apareceu primeiro em .*$/i, '')
    .replace(/\bThe post .*?appeared first on .*$/i, '')
    .replace(/^\d{1,2}\/\d{1,2}\/\d{4}\s*[–-]\s*(Atualizado em\s*)?/i, '')
    .replace(/^\d{1,2}\/\d{1,2}\/\d{4}\s*[–-]\s*\d{1,2}:\d{2}\s*(am|pm)?\s*/i, '')
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * O Google Noticias repete o titulo no lugar do resumo, e ai a lista do app
 * mostra a mesma frase duas vezes. Detecta isso comparando o inicio dos dois.
 */
function ehSoOTituloRepetido(descricao, titulo) {
  const norm = (t) => normalizar(t).replace(/[^a-z0-9]/g, '');
  const d = norm(descricao);
  const t = norm(titulo);
  if (!d) return true;
  return d.startsWith(t.slice(0, 40)) || t.startsWith(d.slice(0, 40));
}

function encurtar(texto, limite) {
  if (texto.length <= limite) return texto;
  const corte = texto.slice(0, limite);
  const ultimoEspaco = corte.lastIndexOf(' ');
  return (ultimoEspaco > limite * 0.6 ? corte.slice(0, ultimoEspaco) : corte) + '...';
}

/**
 * Monta o teste de um termo da curadoria.
 *
 * Comparar por trecho solto nao serve: "pet" aparece dentro de "Petz" e de
 * "apetite", e foi assim que uma materia sobre limpar piscina entrou na aba de
 * noticias de pet. O termo precisa comecar em inicio de palavra.
 *
 * Termo terminado em "*" e raiz e casa com o que vier depois - "castra*" pega
 * castracao e CastraMovel. Sem o "*", tem de ser a palavra inteira.
 */
function testeDoTermo(termo) {
  const limpo = normalizar(termo);
  const raiz = limpo.endsWith('*');
  const semMarca = raiz ? limpo.slice(0, -1) : limpo;
  const corpo = semMarca.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return new RegExp('\\b' + corpo + (raiz ? '' : '\\b'));
}

// Compilado uma vez: sao ~50 termos contra centenas de itens por execucao.
const TESTES_INCLUSAO = TERMOS_INCLUSAO.map(testeDoTermo);
const TESTES_EXCLUSAO = TERMOS_EXCLUSAO.map((t) => [t, testeDoTermo(t)]);

export function ehSobrePets(texto) {
  const t = normalizar(texto);
  return TESTES_INCLUSAO.some((teste) => teste.test(t));
}

export function motivoDeDescarte(texto) {
  const t = normalizar(texto);
  return TESTES_EXCLUSAO.find(([, teste]) => teste.test(t))?.[0] || null;
}

/**
 * Decide se a materia e noticia ou guia de cuidado.
 *
 * Sao coisas diferentes e o leitor procura cada uma em momento diferente:
 * guia responde uma duvida e nao envelhece, noticia e um fato datado. Ficavam
 * as duas na mesma aba, e "Como acostumar gato a caixa de transporte"
 * aparecia como se fosse noticia do dia.
 *
 * O perfil da fonte e o ponto de partida; o titulo pode mudar. Fato datado
 * ganha do formato de guia, porque prefeitura explicando como agendar
 * castracao continua sendo noticia.
 */
export function classificar(titulo, perfilDaFonte) {
  const t = normalizar(titulo);
  if (SINAIS_DE_NOTICIA.some((sinal) => sinal.test(t))) return 'noticia';
  if (SINAIS_DE_GUIA.some((sinal) => sinal.test(t))) return 'cuidado';
  return perfilDaFonte === 'guias' ? 'cuidado' : 'noticia';
}

async function coletar() {
  const aprovados = [];
  const descartados = [];

  for (const feed of FEEDS) {
    let resultado;
    try {
      resultado = await baixarFeed(feed.url);
    } catch (erro) {
      // Um feed fora do ar nao pode derrubar a atualizacao inteira.
      console.error(`  [${feed.nome}] falhou: ${erro.message}`);
      continue;
    }

    const itens = resultado.items || [];
    let aceitosNesteFeed = 0;

    for (const item of itens) {
      const tituloBruto = limparTexto(item.title);
      const descricao = limparTexto(item.contentSnippet || item.content || item.summary);
      const textoParaFiltro = `${tituloBruto} ${descricao}`;

      const titulo = tituloBruto;
      const veiculo = feed.nome;

      if (!titulo || !item.link) continue;

      const bloqueio = motivoDeDescarte(textoParaFiltro);
      if (bloqueio) {
        descartados.push({ titulo, motivo: `contem "${bloqueio}"` });
        continue;
      }
      if (!ehSobrePets(textoParaFiltro)) {
        descartados.push({ titulo, motivo: 'nao fala de pets' });
        continue;
      }

      const data = item.isoDate ? new Date(item.isoDate) : new Date();
      const idadeEmDias = (Date.now() - data.getTime()) / 86400000;
      if (idadeEmDias > IDADE_MAXIMA_EM_DIAS) {
        descartados.push({ titulo, motivo: `tem ${Math.round(idadeEmDias)} dias` });
        continue;
      }

      // Quando nao ha resumo de verdade, o veiculo e a informacao mais util
      // que cabe ali: a lista do app mostra so titulo e descricao, entao
      // assim o leitor ao menos ve de onde a noticia veio.
      const resumo = limparEntulho(descricao);
      const temResumoProprio = !ehSoOTituloRepetido(resumo, titulo);

      aprovados.push({
        titulo,
        tipo: classificar(titulo, feed.perfil),
        // Fica vazio quando o feed nao deu resumo de verdade; o preview da
        // pagina tenta preencher depois, e o veiculo entra como ultimo caso.
        descricao: temResumoProprio ? encurtar(resumo, 400) : '',
        data,
        autor: veiculo,
        link: item.link,
        imagem: null,
        resumoPorIA: false,
      });
      aceitosNesteFeed++;
      if (feed.limite && aceitosNesteFeed >= feed.limite) break;
    }

    console.log(`  [${feed.nome}] ${itens.length} itens no feed, ${aceitosNesteFeed} aprovados`);
  }

  return { aprovados, descartados };
}

/**
 * Procura a capa da materia, tentando mais de um lugar.
 *
 * A og:image e a primeira opcao porque e a que o veiculo escolheu para o
 * preview de link. Nem todo site publica: alguns so tem a variante do Twitter,
 * outros so a tag antiga image_src, e ha os que nao declaram nada e sobra
 * procurar a maior imagem dentro do corpo da materia.
 */
function acharCapa(html, urlDaPagina) {
  const daMeta = (prop) => {
    const padroes = [
      new RegExp(`<meta[^>]+(?:property|name)=["']${prop}["'][^>]*content=["']([^"']{5,})`, 'i'),
      new RegExp(`<meta[^>]+content=["']([^"']{5,})["'][^>]*(?:property|name)=["']${prop}["']`, 'i'),
    ];
    for (const p of padroes) {
      const m = html.match(p);
      if (m) return m[1].trim();
    }
    return null;
  };

  const candidatos = [
    daMeta('og:image'),
    daMeta('og:image:secure_url'),
    daMeta('twitter:image'),
    daMeta('twitter:image:src'),
    /<link[^>]+rel=["']image_src["'][^>]*href=["']([^"']+)/i.exec(html)?.[1],
    primeiraImagemDoCorpo(html),
  ];

  for (const bruto of candidatos) {
    if (!bruto) continue;
    const absoluta = paraAbsoluta(bruto.trim(), urlDaPagina);
    // Icone, logo e pixel de rastreio aparecem como <img> no corpo e nao
    // servem de capa: viram um quadradinho esticado no topo da noticia.
    if (absoluta && !/sprite|logo|icon|avatar|placeholder|pixel|1x1|blank/i.test(absoluta)) {
      return absoluta;
    }
  }
  return null;
}

/** Endereco de imagem costuma vir relativo ("/media/foto.jpg"). */
function paraAbsoluta(endereco, urlDaPagina) {
  try {
    const u = new URL(endereco, urlDaPagina);
    return u.protocol === 'http:' || u.protocol === 'https:' ? u.href : null;
  } catch {
    return null;
  }
}

/**
 * Ultima tentativa: a maior imagem declarada no corpo da materia.
 *
 * "Maior" pela largura declarada no atributo, quando existe. Sem isso a
 * escolha cairia na primeira <img> da pagina, que costuma ser o logo do site.
 */
function primeiraImagemDoCorpo(html) {
  const corpo = /<article[\s\S]*?<\/article>/i.exec(html)?.[0] || html;
  let melhor = null;
  let maiorLargura = 0;
  for (const m of corpo.matchAll(/<img[^>]+>/gi)) {
    const tag = m[0];
    const src = /(?:^|\s)src=["']([^"']+)/i.exec(tag)?.[1];
    if (!src || src.startsWith('data:')) continue;
    const largura = Number(/\swidth=["']?(\d+)/i.exec(tag)?.[1] || 0);
    if (!melhor || largura > maiorLargura) {
      melhor = src;
      maiorLargura = largura;
    }
  }
  // Imagem pequena declarada e quase sempre icone.
  return maiorLargura > 0 && maiorLargura < 200 ? null : melhor;
}

/**
 * Busca og:image e og:description na pagina da noticia.
 *
 * Sao metatags que o proprio veiculo publica para preview de link, entao ler
 * isso e o uso pretendido delas - diferente de raspar o corpo da materia.
 *
 * Nao adianta tentar com link do Google Noticias: o endereco e um redirect
 * criptografado que so resolve no navegador, e a pagina devolve a metatag
 * generica do proprio Google.
 */
async function buscarPreview(url) {
  try {
    const resposta = await fetch(url, {
      redirect: 'follow',
      signal: AbortSignal.timeout(15000),
      headers: { 'User-Agent': NAVEGADOR },
    });
    if (!resposta.ok) return {};
    const html = (await resposta.text()).slice(0, 400000);

    const meta = (prop) => {
      const padroes = [
        new RegExp(`<meta[^>]+(?:property|name)=["']${prop}["'][^>]*content=["']([^"']{5,})`, 'i'),
        new RegExp(`<meta[^>]+content=["']([^"']{5,})["'][^>]*(?:property|name)=["']${prop}["']`, 'i'),
      ];
      for (const p of padroes) {
        const m = html.match(p);
        if (m) return m[1].trim();
      }
      return null;
    };

    return {
      imagem: acharCapa(html, url),
      resumo: meta('og:description') || meta('description'),
      // Guardado para a IA resumir.
      texto: extrairTexto(html),
    };
  } catch {
    // Pagina fora do ar ou lenta nao pode impedir a noticia de ser publicada.
    return {};
  }
}

/** Duas fontes publicam a mesma pauta; mantem a primeira ocorrencia. */
function removerDuplicatas(lista) {
  const vistos = new Set();
  return lista.filter((n) => {
    const chave = normalizar(n.titulo).replace(/[^a-z0-9]/g, '').slice(0, 60);
    if (vistos.has(chave)) return false;
    vistos.add(chave);
    return true;
  });
}

/** Id estavel a partir do link, para reexecucao nao duplicar documento. */
function idDoDocumento(link) {
  let hash = 0;
  for (let i = 0; i < link.length; i++) {
    hash = (hash * 31 + link.charCodeAt(i)) | 0;
  }
  return 'rss_' + Math.abs(hash).toString(36);
}

async function conectar() {
  const credencial = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!credencial) {
    console.error('FIREBASE_SERVICE_ACCOUNT nao definida. Use --simular para testar sem credencial.');
    process.exit(1);
  }
  const { initializeApp, cert } = await import('firebase-admin/app');
  const { getFirestore } = await import('firebase-admin/firestore');
  initializeApp({ credential: cert(JSON.parse(credencial)) });
  return getFirestore();
}

/**
 * Resumos ja gerados em execucoes anteriores, por id de documento.
 *
 * O job roda a cada 6 horas, mas as fontes publicam uma ou duas materias por
 * dia. Sem isso as mesmas materias voltariam para a IA quatro vezes ao dia,
 * todo dia - pagando de novo pelo mesmo resumo. O id do documento vem do
 * link, entao e estavel entre execucoes.
 */
async function carregarResumosJaFeitos(db) {
  const mapa = new Map();
  const docs = await db.collection('news').get();
  for (const doc of docs.docs) {
    const d = doc.data();
    // A dica sai da mesma chamada que o resumo, entao e reaproveitada junto.
    //
    // `dicaVersao` distingue "ainda nao passou pela IA pedindo dica" de
    // "passou e ela recusou". Sem essa diferenca, guia sobre tratamento -
    // que nunca rende dica, de proposito - voltaria para a IA em toda
    // execucao, para sempre, recebendo a mesma recusa. E, sendo numero em vez
    // de sim/nao, mudar as regras da dica reavalia os guias uma vez.
    if (d.aiSummary && d.description) {
      mapa.set(doc.id, {
        resumo: d.description,
        dica: d.dica || null,
        dicaVersao: Number(d.dicaVersao) || 0,
      });
    }
  }
  return mapa;
}

async function publicar(db, noticias) {
  const { Timestamp } = await import('firebase-admin/firestore');
  const colecao = db.collection('news');

  // Remove o que foi publicado por execucoes anteriores. Documentos escritos a
  // mao (sem o prefixo rss_) sao preservados de proposito.
  const antigos = await colecao.get();
  let removidos = 0;
  let lote = db.batch();
  let naLote = 0;
  for (const doc of antigos.docs) {
    if (!doc.id.startsWith('rss_')) continue;
    lote.delete(doc.ref);
    removidos++;
    if (++naLote === 400) { await lote.commit(); lote = db.batch(); naLote = 0; }
  }
  if (naLote > 0) await lote.commit();

  lote = db.batch();
  for (const n of noticias) {
    lote.set(colecao.doc(idDoDocumento(n.link)), {
      title: n.titulo,
      description: n.descricao,
      date: Timestamp.fromDate(n.data),
      author: n.autor,
      sourceUrl: n.link,
      imageUrl: n.imagem || '',
      aiSummary: n.resumoPorIA,
      // 'noticia' ou 'cuidado': decide em qual aba do app a materia aparece.
      tipo: n.tipo,
      // Acao pratica tirada do texto do guia. So existe em tipo 'cuidado', e
      // so quando a materia nao e sobre tratamento.
      dica: n.dica || '',
      // Sob quais regras a dica foi avaliada. Serve para uma recusa nao virar
      // nova tentativa a cada execucao, e para as regras mudarem sem deixar
      // dica velha presa ao criterio antigo.
      dicaVersao: Number(n.dicaVersao) || 0,
    });
  }
  await lote.commit();

  console.log(`\nPublicado: ${noticias.length} noticias (${removidos} anteriores removidas).`);
}

/**
 * Ordena da mais recente para a mais antiga e aplica a janela de dias.
 *
 * A janela nao e um corte seco: se o que saiu nos ultimos JANELA_EM_DIAS dias
 * nao chega ao minimo, a lista completa com as mais recentes que ficaram de
 * fora. Assim uma semana quieta nas fontes nao esvazia a aba, e a ordem
 * continua sendo da mais nova para a mais velha em qualquer caso.
 */
function porRecencia(lista) {
  const ordenada = [...lista].sort((a, b) => b.data - a.data);
  const limiteDaJanela = Date.now() - JANELA_EM_DIAS * 86400000;

  const dentroDaJanela = ordenada.filter((n) => n.data.getTime() >= limiteDaJanela);
  if (dentroDaJanela.length >= MINIMO_DE_NOTICIAS) return dentroDaJanela;

  const completando = ordenada.filter((n) => n.data.getTime() < limiteDaJanela);
  const faltam = MINIMO_DE_NOTICIAS - dentroDaJanela.length;
  if (completando.length > 0) {
    console.log(
      `  Janela de ${JANELA_EM_DIAS} dias rendeu ${dentroDaJanela.length}; ` +
        `completando com ate ${faltam} mais antigas.`,
    );
  }
  return [...dentroDaJanela, ...completando.slice(0, faltam)];
}

async function main() {
  console.log(SIMULAR ? '=== SIMULACAO (nada sera escrito) ===\n' : '=== Publicando no Firestore ===\n');

  const { aprovados, descartados } = await coletar();
  // Folga proposital sobre o limite: parte das candidatas cai no passo
  // seguinte, quando descobrimos que a pagina nao abriu. Sem a folga a lista
  // publicada ficaria menor que o limite toda vez que um site saisse do ar.
  const FOLGA = 10;
  const candidatas = porRecencia(removerDuplicatas(aprovados))
    .slice(0, LIMITE_DE_NOTICIAS + FOLGA);

  console.log(`
${aprovados.length} aprovados, ${descartados.length} descartados, ${candidatas.length} candidatas apos deduplicar.
`);

  // So agora busca o preview, e apenas das candidatas: enriquecer todas as
  // aprovadas seria desperdicio de requisicao.
  console.log('Buscando capa e resumo nas paginas...');
  const previewsBrutos = await Promise.all(candidatas.map((n) => buscarPreview(n.link)));

  // Descarta o que nao da para ler.
  //
  // Noticia sem nada para ler no app e so um titulo: abrir nao entrega nada e
  // o unico caminho e sair para o navegador. Melhor nao publicar. Basta ter
  // texto de materia (que a IA resume) ou o resumo do proprio veiculo.
  let ilegiveis = 0;
  const pares = candidatas
    .map((noticia, i) => ({ noticia, preview: previewsBrutos[i] || {} }))
    .filter(({ noticia, preview }) => {
      const temTexto = Boolean(preview.texto && preview.texto.length >= 400);
      const temResumoDoVeiculo = Boolean(
        preview.resumo && !ehSoOTituloRepetido(preview.resumo, noticia.titulo),
      );
      if (temTexto || temResumoDoVeiculo || noticia.descricao) return true;
      ilegiveis++;
      return false;
    })
    .slice(0, LIMITE_DE_NOTICIAS);

  const noticias = pares.map((par) => par.noticia);
  const previews = pares.map((par) => par.preview);
  if (ilegiveis > 0) {
    console.log(`  ${ilegiveis} descartadas por nao ter materia legivel.`);
  }

  let comCapa = 0;
  let resumoRecuperado = 0;
  noticias.forEach((n, i) => {
    const p = previews[i];
    if (p.imagem) { n.imagem = p.imagem; comCapa++; }
    if (!n.descricao && p.resumo && !ehSoOTituloRepetido(p.resumo, n.titulo)) {
      n.descricao = encurtar(limparEntulho(p.resumo), 400);
      resumoRecuperado++;
    }
  });
  console.log(`  ${comCapa} de ${noticias.length} com imagem de capa, ${resumoRecuperado} resumos recuperados da pagina.
`);

  // Conecta antes da IA para reaproveitar resumo ja gerado.
  const db = SIMULAR ? null : await conectar();

  // A IA entra depois do preview, e so onde ha texto de materia. Sem texto ela
  // teria de inventar, e num app de saude animal isso nao e aceitavel.
  if (!SIMULAR && iaDisponivel()) {
    const jaFeitos = await carregarResumosJaFeitos(db);
    const cliente = criarCliente();

    // Resolve o modelo uma vez: se falhar aqui, falharia igual em cada uma das
    // materias e encheria o log com o mesmo erro repetido.
    let modeloOk = true;
    try {
      await escolherModelo(cliente);
    } catch (erro) {
      console.error(`  nao foi possivel escolher modelo: ${erro.message}`);
      console.error('  seguindo sem resumo por IA.');
      modeloOk = false;
    }

    let resumidas = 0;
    let reaproveitadas = 0;
    let semTexto = 0;
    console.log('Resumindo com IA as materias que tem texto...');
    for (let i = 0; i < noticias.length; i++) {
      if (!modeloOk) break;
      const texto = previews[i]?.texto;
      if (!texto) { semTexto++; continue; }

      // Materia ja resumida antes: reusa. Sem isso o job pagaria de novo pelo
      // mesmo resumo a cada 6 horas, e as fontes publicam uma vez por dia.
      // So guia rende dica: ela aparece na aba Cuidados, e noticia datada nao
      // vira conselho pratico.
      const querDica = noticias[i].tipo === 'cuidado';

      const anterior = jaFeitos.get(idDoDocumento(noticias[i].link));
      // Guia resumido antes de a dica existir precisa passar pela IA de novo,
      // uma vez, senao o resumo em cache o impediria de ganhar dica para
      // sempre. A partir dai o cache volta a valer.
      if (anterior && (!querDica || anterior.dicaVersao === VERSAO_DA_DICA)) {
        noticias[i].descricao = anterior.resumo;
        noticias[i].dica = anterior.dica;
        noticias[i].dicaVersao = anterior.dicaVersao;
        noticias[i].resumoPorIA = true;
        reaproveitadas++;
        continue;
      }

      try {
        const saida = await resumir(cliente, noticias[i].titulo, texto, { querDica });
        if (saida) {
          noticias[i].descricao = saida.resumo;
          noticias[i].dica = saida.dica;
          noticias[i].dicaVersao = querDica ? VERSAO_DA_DICA : 0;
          noticias[i].resumoPorIA = true;
          resumidas++;
        }
      } catch (erro) {
        // Falha de IA nao pode derrubar a atualizacao: a noticia so fica com
        // o resumo que ja tinha.
        console.error(`  falhou em "${noticias[i].titulo.slice(0, 45)}": ${erro.message}`);
      }
    }
    const comDica = noticias.filter((n) => n.dica).length;
    console.log(`  ${resumidas} novas resumidas, ${reaproveitadas} reaproveitadas, ${semTexto} sem texto acessivel.`);
    console.log(`  ${comDica} guias renderam dica pratica.\n`);
  } else if (!SIMULAR) {
    console.log('GROQ_API_KEY nao definida: seguindo sem resumo por IA.\n');
  }

  // Rede de seguranca. Antes daqui a noticia ficava com o nome do veiculo no
  // lugar do resumo, o que so enchia linguica: agora ela sai da lista, pela
  // mesma razao das ilegiveis.
  const semResumo = noticias.filter((n) => !n.descricao || !n.descricao.trim());
  if (semResumo.length > 0) {
    console.log(`  ${semResumo.length} descartadas por ficar sem resumo.`);
  }
  const publicaveis = noticias.filter((n) => n.descricao && n.descricao.trim());

  if (SIMULAR) {
    console.log('--- SERIAM PUBLICADAS ---');
    publicaveis.forEach((n, i) => {
      console.log(`${String(i + 1).padStart(2)}. [${n.tipo === 'cuidado' ? 'CUIDADO' : 'NOTICIA'}] [${n.autor}] ${n.titulo}`);
      // A descricao aparece como subtitulo na lista do app, entao vale
      // conferir aqui se ela agrega algo ou so repete o titulo.
      console.log(`    resumo: ${n.descricao.slice(0, 90)}`);
      console.log(`    capa  : ${n.imagem ? n.imagem.slice(0, 70) : '(sem imagem)'}`);
      console.log(`    ${n.data.toISOString().slice(0, 10)} | ${n.link.slice(0, 60)}`);
    });
    console.log('\n--- DESCARTADAS (amostra) ---');
    descartados.slice(0, 15).forEach((d) => {
      console.log(`  x ${d.titulo.slice(0, 70)}`);
      console.log(`    motivo: ${d.motivo}`);
    });
    return;
  }

  const guias = publicaveis.filter((n) => n.tipo === 'cuidado').length;
  console.log(`  ${publicaveis.length - guias} noticias e ${guias} guias de cuidado.`);

  if (publicaveis.length === 0) {
    console.error('Nenhuma noticia aprovada. Abortando para nao esvaziar o app.');
    process.exit(1);
  }
  await publicar(db, publicaveis);
}

// So roda quando chamado direto. Importado - pelo teste da curadoria - o
// arquivo apenas expoe os filtros, sem sair buscando feed.
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((erro) => {
    console.error('Falhou:', erro);
    process.exit(1);
  });
}
