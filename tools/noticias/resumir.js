// Resume materias a partir do texto real da pagina, usando a Groq.
//
// Regra que orienta este arquivo: so resume o que existe. Materia sem texto
// acessivel nao vai para a IA - pedir um "resumo" a partir de um titulo seria
// inventar conteudo, e num app de saude animal isso pode virar orientacao
// errada sobre medicamento ou doenca.
//
// A Groq foi escolhida por ter camada gratuita. Em troca ha limite de
// requisicoes: quando ele estoura, a chamada falha e o agregador mantem o
// resumo que o proprio veiculo publicou. Nada quebra.

import Groq from 'groq-sdk';

/** Sem chave configurada o agregador segue sem IA, em vez de falhar. */
export function iaDisponivel() {
  return Boolean(process.env.GROQ_API_KEY);
}

/**
 * Ordem de preferencia para resumir. O primeiro que a conta tiver e usado.
 *
 * Nomes de modelo na Groq mudam e sao aposentados, e a primeira execucao real
 * falhou com 404 model_not_found justamente por isso. Em vez de fixar um nome
 * e torcer, o script pergunta a API o que existe.
 */
const PREFERENCIA = [
  'openai/gpt-oss-120b',
  'openai/gpt-oss-20b',
  'llama-3.3-70b-versatile',
  'llama-3.1-70b-versatile',
  'llama3-70b-8192',
  'llama-3.1-8b-instant',
  'llama3-8b-8192',
  'mixtral-8x7b-32768',
  'gemma2-9b-it',
];

/** Modelos que existem mas nao servem para resumir texto. */
const NAO_SERVE = /whisper|tts|guard|vision|embed|distil|orpheus|allam/i;

/**
 * Modelo de raciocinio fica por ultimo. Ele gasta tokens pensando antes de
 * responder, o que so encarece e alonga uma tarefa simples como resumir - e
 * ainda obriga a limpar o bloco <think> da resposta.
 */
const RACIOCINIO = /qwen3|reasoning|-r1|thinking|deepseek/i;

let modeloEscolhido = null;

/**
 * O primeiro resumo vazio de cada execucao imprime o diagnostico completo.
 * So o primeiro: repetir dez vezes a mesma causa so polui o log.
 */
let jaDiagnosticou = false;

/**
 * Descobre um modelo utilizavel na conta. GROQ_MODEL, quando definida, vence
 * sem consulta - serve para forcar um modelo especifico.
 */
export async function escolherModelo(cliente) {
  if (process.env.GROQ_MODEL) return process.env.GROQ_MODEL;
  if (modeloEscolhido) return modeloEscolhido;

  const lista = await cliente.models.list();
  const disponiveis = (lista.data || [])
    .map((m) => m.id)
    .filter((id) => !NAO_SERVE.test(id));

  const simples = disponiveis.filter((id) => !RACIOCINIO.test(id));
  modeloEscolhido =
    PREFERENCIA.find((p) => disponiveis.includes(p)) ||
    simples.find((id) => /llama|mixtral|gemma|qwen|gpt|kimi/i.test(id)) ||
    simples[0] ||
    disponiveis[0];

  if (!modeloEscolhido) {
    throw new Error(`nenhum modelo utilizavel na conta. Disponiveis: ${disponiveis.join(', ') || '(nenhum)'}`);
  }
  console.log(`  modelo: ${modeloEscolhido}`);
  console.log(`  disponiveis na conta: ${disponiveis.join(', ')}`);
  return modeloEscolhido;
}

const INSTRUCAO = `Voce resume noticias sobre cuidados com animais de estimacao
para um aplicativo brasileiro chamado PetCare, lido por donos de pets.

Regras:
- Escreva 2 a 3 frases, em portugues do Brasil, no maximo 400 caracteres.
- Use somente o que esta no texto fornecido. Nao complete com conhecimento
  proprio, nao suponha e nao generalize.
- Priorize o que o dono do animal precisa saber: sintoma, cuidado, prazo,
  local, quem pode participar.
- Nao repita o titulo. Nao comece com "A materia" ou "O artigo".
- Nao de conselho medico proprio: relate o que a materia diz.
- Ignore menu, propaganda e cupom que aparecerem no texto.
- Responda apenas com o resumo, sem introducao e sem aspas.
- Se o texto nao permitir um resumo fiel, responda exatamente: SEM_RESUMO`;

/**
 * Instrucao extra para guia de cuidado, que rende uma dica alem do resumo.
 *
 * A dica aparece sozinha na aba Cuidados, fora do contexto da materia, e por
 * isso o que ela pode dizer e mais estreito que o resumo: serve para observar
 * e prevenir, nunca para tratar. Dose de medicamento fora de contexto e o
 * caso que mais preocupa - "1 gota por quilo" lido solto, sem a parte de que
 * so vale com prescricao, vira instrucao de automedicacao.
 */
const INSTRUCAO_COM_DICA = `${INSTRUCAO}

Depois do resumo, escreva uma linha comecando com "DICA:" contendo uma acao
pratica que o dono possa adotar, tirada do texto.

Regras da dica:
- No maximo 90 caracteres, no imperativo, em portugues do Brasil.
- Ela sera lida sozinha, fora da materia: precisa fazer sentido isolada.
- Pode falar de observacao, prevencao, higiene, rotina e de quando procurar
  um veterinario.
- Nao pode indicar medicamento, dose, frequencia de administracao nem
  tratamento. Se a materia for principalmente sobre isso, escreva
  exatamente: DICA: SEM_DICA
- Nao invente nada que nao esteja no texto.

Formato da resposta, exatamente em duas partes:
<resumo>
DICA: <dica>`;

/** Separa o resumo da dica na resposta de duas partes. */
function separarResumoEDica(saida) {
  const marca = saida.search(/^\s*DICA:/im);
  if (marca === -1) return { resumo: saida.trim(), dica: null };

  const resumo = saida.slice(0, marca).trim();
  const bruta = saida
    .slice(marca)
    .replace(/^\s*DICA:\s*/i, '')
    .trim();

  const dica = !bruta || /SEM_DICA/i.test(bruta) ? null : bruta.replace(/^["']|["']$/g, '').trim();
  return { resumo, dica };
}

/**
 * Extrai o corpo da materia do HTML.
 *
 * Nao e um parser de verdade - so remove o que atrapalha (script, style, menu,
 * rodape) e devolve o texto. Serve porque o destino e um resumo, nao uma
 * reproducao fiel.
 */
export function extrairTexto(html) {
  const semRuido = html
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<noscript[\s\S]*?<\/noscript>/gi, ' ')
    .replace(/<nav[\s\S]*?<\/nav>/gi, ' ')
    .replace(/<header[\s\S]*?<\/header>/gi, ' ')
    .replace(/<footer[\s\S]*?<\/footer>/gi, ' ')
    .replace(/<aside[\s\S]*?<\/aside>/gi, ' ')
    .replace(/<form[\s\S]*?<\/form>/gi, ' ');

  const limpar = (trecho) =>
    trecho
      .replace(/<[^>]+>/g, ' ')
      .replace(/&nbsp;/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();

  // Prefere o corpo semantico, mas escolhendo o MAIOR bloco: paginas de blog
  // costumam ter varios <article> pequenos de "leia tambem" antes da materia,
  // e pegar o primeiro devolvia um card de duas palavras.
  let melhor = '';
  for (const tag of ['article', 'main']) {
    const blocos = semRuido.match(new RegExp(`<${tag}[\\s\\S]*?</${tag}>`, 'gi')) || [];
    for (const bloco of blocos) {
      const texto = limpar(bloco);
      if (texto.length > melhor.length) melhor = texto;
    }
  }

  // Bloco semantico curto demais quer dizer que o site nao marca a materia
  // com essas tags; ai vale mais usar a pagina inteira.
  const artigo = melhor.length >= 400 ? melhor : limpar(semRuido);

  return artigo
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/\s+/g, ' ')
    .trim();
}

/** Abaixo disso o que sobrou e menu e rodape, nao materia. */
const MINIMO_DE_CARACTERES = 400;

/**
 * Resume uma materia. Devolve null quando nao da para resumir com fidelidade -
 * o chamador entao mantem o resumo que ja tinha.
 */
const esperar = (ms) => new Promise((r) => setTimeout(r, ms));

/**
 * Chama a IA respeitando o limite por minuto da camada gratuita.
 *
 * Estourar o limite e esperado aqui, nao excecao: o job resume varias materias
 * seguidas e o teto e de 8000 tokens por minuto. A propria Groq responde
 * quanto falta esperar ("try again in 3.65s"), entao vale obedecer e repetir
 * em vez de descartar a materia - foi assim que uma se perdeu na execucao #6.
 */
async function chamarComRetentativa(cliente, corpo, tentativas = 3) {
  for (let tentativa = 1; ; tentativa++) {
    try {
      return await cliente.chat.completions.create(corpo);
    } catch (erro) {
      const excedeuLimite = erro?.status === 429;
      if (!excedeuLimite || tentativa >= tentativas) throw erro;

      const sugerido = /try again in ([\d.]+)s/i.exec(erro.message || '');
      // Um segundo a mais que o sugerido: o limite e por janela de minuto e
      // acordar no limite exato costuma esbarrar de novo.
      const espera = sugerido ? Number(sugerido[1]) * 1000 + 1000 : 5000 * tentativa;
      console.log(`  limite por minuto atingido, aguardando ${Math.round(espera / 1000)}s...`);
      await esperar(espera);
    }
  }
}

/**
 * Resume a materia e, para guia de cuidado, tira dela uma dica pratica.
 *
 * As duas coisas saem da mesma chamada de proposito. A camada gratuita limita
 * tokens por minuto, entao pedir a dica separada dobraria as chamadas e faria
 * o job esbarrar no limite - o resumo ja custou uma materia por 429 antes.
 *
 * Devolve `{ resumo, dica }`, com `dica` nula quando nao foi pedida ou quando
 * o modelo recusou por a materia ser sobre tratamento.
 */
export async function resumir(cliente, titulo, texto, { querDica = false } = {}) {
  if (!texto || texto.length < MINIMO_DE_CARACTERES) return null;

  const resposta = await chamarComRetentativa(cliente, {
    model: await escolherModelo(cliente),
    // O resumo tem 400 caracteres, mas o teto precisa de folga porque alguns
    // modelos gastam tokens raciocinando antes de responder - com teto justo a
    // resposta volta vazia. Folga sem exagero: na camada gratuita o teto
    // pedido conta no limite por minuto, e pedir demais derruba a proxima.
    max_tokens: 700,
    // Temperatura baixa porque a tarefa e fidelidade ao texto, nao criacao.
    temperature: 0.3,
    messages: [
      { role: 'system', content: querDica ? INSTRUCAO_COM_DICA : INSTRUCAO },
      {
        role: 'user',
        content: `Titulo: ${titulo}\n\nTexto da materia:\n${texto.slice(0, 7000)}`,
      },
    ],
  });

  const bruto = resposta.choices?.[0]?.message?.content || '';

  // Modelo de raciocinio devolve <think>...</think> antes do texto final.
  const saida = bruto
    .replace(/<think>[\s\S]*?<\/think>/gi, '')
    .replace(/<think>[\s\S]*$/i, '')
    .trim();

  if (!saida || saida.includes('SEM_RESUMO')) {
    // Sem isto, "0 resumidas" nao diz se o modelo recusou, se a resposta veio
    // truncada ou se veio vazia - e a chave e secret, entao nao da para
    // reproduzir a chamada fora do runner.
    if (!jaDiagnosticou) {
      jaDiagnosticou = true;
      const escolha = resposta.choices?.[0] || {};
      console.log(
        `  [diagnostico] sem resumo: finish_reason=${escolha.finish_reason}` +
          ` bruto=${bruto.length}ch limpo=${saida.length}ch` +
          ` tokens_saida=${resposta.usage?.completion_tokens}`,
      );
      if (bruto) console.log(`  [diagnostico] inicio da resposta: ${bruto.slice(0, 220).replace(/\s+/g, ' ')}`);
    }
    return null;
  }

  const { resumo, dica } = separarResumoEDica(saida);
  if (!resumo || resumo.includes('SEM_RESUMO')) return null;

  return {
    // Modelo aberto as vezes devolve o resumo entre aspas mesmo instruido a
    // nao fazer isso; tirar aqui e mais barato que insistir no prompt.
    resumo: resumo.replace(/^["']|["']$/g, '').trim(),
    // Dica longa demais foi o modelo ignorando o limite: cortar no meio da
    // frase deixaria um conselho pela metade, entao ela e descartada.
    dica: dica && dica.length <= 110 ? dica : null,
  };
}

export function criarCliente() {
  return new Groq({ apiKey: process.env.GROQ_API_KEY });
}
