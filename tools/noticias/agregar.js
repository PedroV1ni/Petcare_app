// Agrega noticias sobre pets de feeds RSS e publica na colecao `news` do
// Firestore, no mesmo formato que o app ja le hoje.
//
//   node agregar.js --simular   imprime o que seria publicado, sem escrever
//   node agregar.js             publica de verdade (exige credencial)
//
// A credencial vem da variavel de ambiente FIREBASE_SERVICE_ACCOUNT, com o
// JSON da conta de servico. No GitHub Actions ela e um secret do repositorio.

import Parser from 'rss-parser';
import {
  FEEDS,
  TERMOS_INCLUSAO,
  TERMOS_EXCLUSAO,
  LIMITE_DE_NOTICIAS,
  IDADE_MAXIMA_EM_DIAS,
} from './fontes.js';

const SIMULAR = process.argv.includes('--simular');

const parser = new Parser({
  timeout: 20000,
  headers: { 'User-Agent': 'PetCare/1.0 (+https://github.com/PedroV1ni/Petcare_app)' },
  // O <source> do Google Noticias traz o veiculo em campo proprio. Sem
  // declarar aqui o rss-parser descarta a tag, e sobraria cortar o titulo
  // no ultimo " - " - que erra quando o proprio nome do veiculo tem hifen.
  customFields: { item: [['source', 'fonteRss']] },
});

/** O <source> vem como string ou como objeto com atributos, conforme o feed. */
function veiculoDoItem(item) {
  const f = item.fonteRss;
  if (!f) return null;
  if (typeof f === 'string') return f.trim() || null;
  return (f._ || f['#text'] || '').trim() || null;
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
 * O Google Noticias devolve titulos no formato "Manchete - Veiculo".
 * Separa os dois para o veiculo virar o autor da noticia no app.
 */
function separarTituloEVeiculo(titulo, veiculoPadrao) {
  const posicao = titulo.lastIndexOf(' - ');
  if (posicao > 20) {
    return {
      titulo: titulo.slice(0, posicao).trim(),
      veiculo: titulo.slice(posicao + 3).trim(),
    };
  }
  return { titulo: titulo.trim(), veiculo: veiculoPadrao };
}

function ehSobrePets(texto) {
  const t = normalizar(texto);
  return TERMOS_INCLUSAO.some((termo) => t.includes(normalizar(termo)));
}

function motivoDeDescarte(texto) {
  const t = normalizar(texto);
  return TERMOS_EXCLUSAO.find((termo) => t.includes(normalizar(termo))) || null;
}

async function coletar() {
  const aprovados = [];
  const descartados = [];

  for (const feed of FEEDS) {
    let resultado;
    try {
      resultado = await parser.parseURL(feed.url);
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

      // Prefere o <source> do feed; so recorre a cortar o titulo quando ele
      // nao vem, que e o caso de alguns agregadores.
      const veiculoDeclarado = veiculoDoItem(item);
      let titulo = tituloBruto;
      let veiculo = feed.nome;

      if (feed.tipoDeTitulo === 'com-sufixo-do-veiculo') {
        if (veiculoDeclarado) {
          veiculo = veiculoDeclarado;
          const sufixo = ` - ${veiculoDeclarado}`;
          if (titulo.endsWith(sufixo)) titulo = titulo.slice(0, -sufixo.length).trim();
        } else {
          ({ titulo, veiculo } = separarTituloEVeiculo(tituloBruto, feed.nome));
        }
      }

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
        // Fica vazio quando o feed nao deu resumo de verdade; o preview da
        // pagina tenta preencher depois, e o veiculo entra como ultimo caso.
        descricao: temResumoProprio ? encurtar(resumo, 400) : '',
        data,
        autor: veiculo,
        link: item.link,
        imagem: null,
      });
      aceitosNesteFeed++;
      if (feed.limite && aceitosNesteFeed >= feed.limite) break;
    }

    console.log(`  [${feed.nome}] ${itens.length} itens no feed, ${aceitosNesteFeed} aprovados`);
  }

  return { aprovados, descartados };
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
  if (url.includes('news.google.com')) return {};
  try {
    const resposta = await fetch(url, {
      redirect: 'follow',
      signal: AbortSignal.timeout(15000),
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36',
      },
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

    const imagem = meta('og:image');
    return {
      imagem: imagem && imagem.startsWith('http') ? imagem : null,
      resumo: meta('og:description') || meta('description'),
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

async function publicar(noticias) {
  const credencial = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!credencial) {
    console.error('\nFIREBASE_SERVICE_ACCOUNT nao definida. Use --simular para testar sem credencial.');
    process.exit(1);
  }

  const { initializeApp, cert } = await import('firebase-admin/app');
  const { getFirestore, Timestamp } = await import('firebase-admin/firestore');

  initializeApp({ credential: cert(JSON.parse(credencial)) });
  const db = getFirestore();
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
    });
  }
  await lote.commit();

  console.log(`\nPublicado: ${noticias.length} noticias (${removidos} anteriores removidas).`);
}

async function main() {
  console.log(SIMULAR ? '=== SIMULACAO (nada sera escrito) ===\n' : '=== Publicando no Firestore ===\n');

  const { aprovados, descartados } = await coletar();
  const noticias = removerDuplicatas(aprovados)
    .sort((a, b) => b.data - a.data)
    .slice(0, LIMITE_DE_NOTICIAS);

  console.log(`\n${aprovados.length} aprovados, ${descartados.length} descartados, ${noticias.length} publicaveis apos deduplicar.\n`);

  // So agora busca o preview, e apenas das que serao publicadas: enriquecer as
  // 45 aprovadas seria desperdicio de requisicao.
  console.log('Buscando capa e resumo nas paginas...');
  const previews = await Promise.all(noticias.map((n) => buscarPreview(n.link)));
  let comCapa = 0;
  let resumoRecuperado = 0;
  noticias.forEach((n, i) => {
    const p = previews[i];
    if (p.imagem) { n.imagem = p.imagem; comCapa++; }
    if (!n.descricao && p.resumo && !ehSoOTituloRepetido(p.resumo, n.titulo)) {
      n.descricao = encurtar(limparEntulho(p.resumo), 400);
      resumoRecuperado++;
    }
    // Sem resumo em lugar nenhum, o veiculo ao menos diz de onde veio.
    if (!n.descricao) n.descricao = n.autor;
  });
  console.log(`  ${comCapa} com imagem de capa, ${resumoRecuperado} resumos recuperados da pagina.\n`);

  if (SIMULAR) {
    console.log('--- SERIAM PUBLICADAS ---');
    noticias.forEach((n, i) => {
      console.log(`${String(i + 1).padStart(2)}. [${n.autor}] ${n.titulo}`);
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

  if (noticias.length === 0) {
    console.error('Nenhuma noticia aprovada. Abortando para nao esvaziar o app.');
    process.exit(1);
  }
  await publicar(noticias);
}

main().catch((erro) => {
  console.error('Falhou:', erro);
  process.exit(1);
});
