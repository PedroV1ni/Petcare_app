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

// Configuravel por variavel de ambiente: a Groq aposenta modelo com alguma
// frequencia, e trocar o nome nao deveria exigir mexer no codigo.
const MODELO = process.env.GROQ_MODEL || 'llama-3.3-70b-versatile';

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
export async function resumir(cliente, titulo, texto) {
  if (!texto || texto.length < MINIMO_DE_CARACTERES) return null;

  const resposta = await cliente.chat.completions.create({
    model: MODELO,
    // Resumo curto: teto baixo evita resposta divagando e economiza cota.
    max_tokens: 400,
    // Temperatura baixa porque a tarefa e fidelidade ao texto, nao criacao.
    temperature: 0.3,
    messages: [
      { role: 'system', content: INSTRUCAO },
      {
        role: 'user',
        content: `Titulo: ${titulo}\n\nTexto da materia:\n${texto.slice(0, 12000)}`,
      },
    ],
  });

  const saida = (resposta.choices?.[0]?.message?.content || '').trim();
  if (!saida || saida.includes('SEM_RESUMO')) return null;

  // Modelo aberto as vezes devolve o resumo entre aspas mesmo instruido a nao
  // fazer isso; tirar aqui e mais barato que insistir no prompt.
  return saida.replace(/^["']|["']$/g, '').trim();
}

export function criarCliente() {
  return new Groq({ apiKey: process.env.GROQ_API_KEY });
}
