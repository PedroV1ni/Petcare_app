// Configuracao das fontes de noticia e das regras de curadoria.
//
// Nenhum feed publico e 100% sobre cuidado com pets: o Google Noticias mistura
// materia policial e judicial, e o CFMV publica edital de licitacao no mesmo
// feed das noticias. Por isso cada item passa por um filtro de inclusao e um
// de exclusao antes de virar noticia no app.

/**
 * Feeds consultados a cada execucao.
 *
 * `perfil` diz o que a fonte publica na maior parte do tempo: blog de
 * varejista vive de guia de cuidado, orgao de classe vive de noticia. E so o
 * ponto de partida - o titulo de cada materia pode mudar a classificacao.
 */
export const FEEDS = [
  {
    nome: 'Cobasi',
    perfil: 'guias',
    url: 'https://blog.cobasi.com.br/feed/',
    // Blog de varejista: o conteudo editorial e bom, mas as vezes vira
    // anuncio de marca nova na loja. O filtro de exclusao cuida disso.
  },
  // Petlove ficou de fora: o conteudo era o melhor que achei, mas o site
  // responde 403 para o IP dos runners do GitHub. Funciona rodando local e
  // falha no CI, entao manter so geraria uma fonte que nunca entrega nada.
  {
    nome: 'CFMV',
    perfil: 'noticias',
    url: 'https://www.cfmv.gov.br/feed/',
    // Conselho Federal de Medicina Veterinaria. Fonte oficial, mas metade do
    // feed e ato administrativo.
  },
  {
    nome: 'Petz',
    perfil: 'guias',
    url: 'https://www.petz.com.br/blog/feed/',
    // Mesmo perfil da Cobasi: blog de varejista com conteudo editorial bom e
    // um anuncio no meio de vez em quando, que o filtro de exclusao pega.
  },
  {
    nome: 'CRMV-SP',
    perfil: 'noticias',
    url: 'https://www.crmvsp.gov.br/feed/',
    // Conselhos regionais. Sao a fonte de noticia datada do app depois que o
    // Google Noticias saiu: publicam campanha, resolucao e alerta sanitario.
    // Varios estados porque cada um publica pouco - juntos dao volume.
  },
  {
    nome: 'CRMV-RJ',
    url: 'https://crmvrj.org.br/feed/',
    perfil: 'noticias',
  },
  {
    nome: 'CRMV-BA',
    url: 'https://www.crmvba.org.br/feed/',
    perfil: 'noticias',
  },
  {
    nome: 'CRMV-GO',
    url: 'https://crmvgo.org.br/feed/',
    perfil: 'noticias',
  },
  // Agencia Brasil saiu. A ideia era cobrir o que os conselhos nao cobrem, mas
  // o feed dela e de ultimas noticias em geral: dez itens sobre qualquer
  // assunto, dos quais nenhum passou no filtro de pets. Fonte que nunca
  // entrega so gasta uma requisicao por execucao.
  // Google Noticias saiu. Trazia volume e variedade regional, mas o link dele e
  // um redirect criptografado que so resolve no navegador: nao da para ler a
  // materia. No app essas noticias viravam so um titulo - sem resumo, sem capa
  // e sem nada para ler ao abrir. Fonte que nao da para ler nao serve.
];

/**
 * Termo terminado em "*" e raiz: casa com o que vier depois. Sem o "*", tem de
 * ser a palavra inteira - e por isso que "pet" nao casa mais com "Petz".
 *
 * O item precisa falar de pet de alguma forma. Sem isso, entra desde noticia
 * de pecuaria ate materia sobre fauna silvestre.
 */
export const TERMOS_INCLUSAO = [
  'pet', 'pets', 'cão', 'cao', 'cães', 'caes', 'cachorro', 'cachorros',
  'gato', 'gatos', 'felino', 'felinos', 'canino', 'caninos',
  'animal de estimação', 'animais de estimação', 'tutor', 'tutores',
  'veterinári*', 'vacinação animal',
  'adoção de animais', 'adocao de animais', 'raiva animal',

  // Termos que faltavam e derrubavam materia boa nos testes: "CastraMovel"
  // nao casa com "castracao", e campanhas municipais costumam falar em
  // "bem-estar animal" ou "zoonoses" sem citar cao ou gato no titulo.
  'castra*', 'zoonose*', 'antirrábic*', 'antirrabic*',
  'bem-estar animal', 'bem estar animal', 'proteção animal', 'protecao animal',
  'saúde animal', 'saude animal', 'guarda responsável', 'guarda responsavel',
  'abrigo de animais', 'resgate de animais',
];

/**
 * Motivos para descartar, cada um vindo de algo que apareceu de verdade nos
 * feeds durante os testes.
 */
export const TERMOS_EXCLUSAO = [
  // Atos administrativos do CFMV
  'pregão', 'pregao', 'edital', 'licitação', 'licitacao', 'contratação direta',
  'contratacao direta', 'inexigibilidade', 'dispensa de licitação',
  'aviso de contratação', 'chamamento público', 'termo aditivo',

  // Policial e judicial, que o Google Noticias puxa bastante
  'morto', 'mortos', 'morta', 'mortas', 'assassin*', 'homicídi*', 'homicidi*',
  'cadáver*', 'cadaver*', 'preso*', 'presa por', 'prisão', 'prisao',
  'estupro', 'tráfico', 'trafico', 'facção', 'faccao', 'crime de',
  'apreendid*', 'operação policial', 'operacao policial',

  // Conteudo comercial explicito
  'chega à cobasi', 'chega a cobasi', 'agora na cobasi', 'em promoção',
  'em promocao', 'black friday', 'cupom de desconto',
  'transforme sua compra', 'aniversário cobasi', 'aniversario cobasi',

  // Nota de falecimento e homenagem institucional: relevante para a classe
  // veterinaria, sem utilidade para quem so quer cuidar do proprio pet.
  'lamenta o falecimento', 'nota de pesar', 'in memoriam',
  'morte da médica', 'morte do médico', 'morte da veterinár*',
  'morte do veterinár*', 'faleceu', 'vítima fatal', 'vitima fatal',

  // Pauta sindical e trabalhista da profissao, mesma logica: interessa ao
  // veterinario, nao a quem tem um cachorro em casa.
  'riscos ocupacionais', 'piso salarial', 'carga horária da categoria',
  'aposentadoria especial', 'vagas para médic*', 'vagas para medic*',

  // Servico de conselho para o proprio conselhado. Os feeds dos CRMVs sao
  // metade disso: anuidade, cedula profissional, portaria, manual de conduta.
  // Nada disso muda o que o dono do animal faz em casa.
  'anuidade*', 'cédul*', 'cedul*', 'recadastr*', 'certidõe*', 'certidao', 'certidão',
  'código de ética', 'codigo de etica', 'manual de publicidade',
  'emissão de documentos', 'emissao de documentos', 'portaria*',
  'formulário para', 'formulario para', 'assembleia*', 'plenári*', 'plenari*',
  'inscrição no crmv', 'inscricao no crmv', 'registro profissional',
  'treinamento para implantação', 'treinamento para implantacao',

  // Materia de negocio, escrita para lojista e nao para dono de pet
  'mercado pet brasileiro', 'faturamento', 'balanço financeiro',
  'balanco financeiro', 'franquia', 'investidores',
];

/** Quantas noticias o app mantem publicadas. */
export const LIMITE_DE_NOTICIAS = 24;

/**
 * Janela desejada: o app mostra o que saiu nos ultimos 15 dias.
 *
 * Materia de dois meses atras nao e noticia, e como a lista vai da mais
 * recente para a mais antiga, o que passa disso ficaria sempre no fim.
 */
export const JANELA_EM_DIAS = 15;

/**
 * Piso de quantidade. Sozinha, a janela de 15 dias deixou o app com 7
 * noticias no teste - as fontes brasileiras de pet publicam pouco, e uma
 * semana quieta esvaziaria a aba. Faltando materia nova, a lista completa com
 * as mais recentes que sobraram, sempre nessa ordem.
 */
export const MINIMO_DE_NOTICIAS = 12;

/** Teto absoluto: abaixo desta idade nada entra, nem para completar a lista. */
export const IDADE_MAXIMA_EM_DIAS = 45;

/**
 * Sinais de que a materia e guia de cuidado, nao noticia.
 *
 * Guia nao envelhece e responde uma duvida ("Como acostumar gato a caixa de
 * transporte"); noticia e um fato datado. Sao formatos diferentes e o leitor
 * procura cada um em momento diferente, entao ficam em abas diferentes.
 */
export const SINAIS_DE_GUIA = [
  /^como /,
  /^o que /,
  /^por que /,
  /^quais /,
  /^\d+ (sinais|dicas|formas|motivos|cuidados|passos|racas|coisas)/,
  /\bpode (dar|tomar|comer|usar)\b/,
  /\bsaiba como\b/,
  /\bconfira( as)? dicas\b/,
  /\bpasso a passo\b/,
  /\bvale a pena\b/,
  /\bcomo (identificar|escolher|cuidar|evitar|tratar|fazer)\b/,
  /\bguia (completo|pratico|de)\b/,
  /\bentenda o\b/,
  /\btudo sobre\b/,
  /\bmelhor .{0,20}para\b/,
];

/**
 * Sinais de fato datado. Tem prioridade sobre os de guia: "Prefeitura explica
 * como agendar castracao" e noticia, mesmo comecando com formato de guia.
 */
export const SINAIS_DE_NOTICIA = [
  /\bprefeitura\b/,
  /\bcampanha\b/,
  /\bresolucao\b/,
  /\bconselho federal\b/,
  /\b(anuncia|aprova|lanca|inaugura|amplia|prorroga|suspende|proibe)\b/,
  /\b(comeca|termina|acontece|abre) (nesta|neste|na|no|em)\b/,
  /\bnesta (segunda|terca|quarta|quinta|sexta|sabado|domingo)\b/,
  /\bcaso(s)? de\b/,
  /\bmutirao\b/,
  /\bnova edicao\b|\bnovas edicoes\b/,
  /\bprojeto de lei\b|\bsancionad/,
  /\bevento\b|\bcongresso\b|\bseminario\b/,
];
