// Configuracao das fontes de noticia e das regras de curadoria.
//
// Nenhum feed publico e 100% sobre cuidado com pets: o Google Noticias mistura
// materia policial e judicial, e o CFMV publica edital de licitacao no mesmo
// feed das noticias. Por isso cada item passa por um filtro de inclusao e um
// de exclusao antes de virar noticia no app.

/** Feeds consultados a cada execucao. */
export const FEEDS = [
  {
    nome: 'Cobasi',
    url: 'https://blog.cobasi.com.br/feed/',
    // Blog de varejista: o conteudo editorial e bom, mas as vezes vira
    // anuncio de marca nova na loja. O filtro de exclusao cuida disso.
    tipoDeTitulo: 'direto',
  },
  // Petlove ficou de fora: o conteudo era o melhor que achei, mas o site
  // responde 403 para o IP dos runners do GitHub. Funciona rodando local e
  // falha no CI, entao manter so geraria uma fonte que nunca entrega nada.
  {
    nome: 'CFMV',
    url: 'https://www.cfmv.gov.br/feed/',
    // Conselho Federal de Medicina Veterinaria. Fonte oficial, mas metade do
    // feed e ato administrativo.
    tipoDeTitulo: 'direto',
  },
  {
    nome: 'Google Notícias',
    url: 'https://news.google.com/rss/search?q=cuidados+com+pets+OR+sa%C3%BAde+animal+OR+vacina%C3%A7%C3%A3o+de+c%C3%A3es&hl=pt-BR&gl=BR&ceid=BR:pt-419',
    // O Google anexa " - Veiculo" ao fim do titulo; tratamos isso ao importar.
    tipoDeTitulo: 'com-sufixo-do-veiculo',
    // Teto proposital. O link do Google e um redirect criptografado: nao da
    // para ler og:description nem og:image dessas materias, entao elas
    // aparecem no app sem resumo e sem capa. Limitando o volume, as fontes
    // diretas - que trazem resumo de verdade - ficam sendo a maioria da lista.
    limite: 10,
  },
];

/**
 * O item precisa falar de pet de alguma forma. Sem isso, entra desde noticia
 * de pecuaria ate materia sobre fauna silvestre.
 */
export const TERMOS_INCLUSAO = [
  'pet', 'pets', 'cão', 'cao', 'cães', 'caes', 'cachorro', 'cachorros',
  'gato', 'gatos', 'felino', 'felinos', 'canino', 'caninos',
  'animal de estimação', 'animais de estimação', 'tutor', 'tutores',
  'veterinári', 'vacinação animal',
  'adoção de animais', 'adocao de animais', 'raiva animal',

  // Termos que faltavam e derrubavam materia boa nos testes: "CastraMovel"
  // nao casa com "castracao", e campanhas municipais costumam falar em
  // "bem-estar animal" ou "zoonoses" sem citar cao ou gato no titulo.
  'castra', 'zoonose', 'antirrábic', 'antirrabic',
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
  'morto', 'mortos', 'morta', 'mortas', 'assassin', 'homicídio', 'homicidio',
  'cadáver', 'cadaver', 'preso', 'presa por', 'prisão', 'prisao',
  'estupro', 'tráfico', 'trafico', 'facção', 'faccao', 'crime de',
  'apreendid', 'operação policial', 'operacao policial',

  // Conteudo comercial explicito
  'chega à cobasi', 'chega a cobasi', 'agora na cobasi', 'em promoção',
  'em promocao', 'black friday', 'cupom de desconto',
  'transforme sua compra', 'aniversário cobasi', 'aniversario cobasi',

  // Nota de falecimento e homenagem institucional: relevante para a classe
  // veterinaria, sem utilidade para quem so quer cuidar do proprio pet.
  'lamenta o falecimento', 'nota de pesar', 'in memoriam',
  'morte da médica', 'morte do médico', 'morte da veterinár',
  'morte do veterinár', 'faleceu', 'vítima fatal', 'vitima fatal',

  // Pauta sindical e trabalhista da profissao, mesma logica: interessa ao
  // veterinario, nao a quem tem um cachorro em casa.
  'riscos ocupacionais', 'piso salarial', 'carga horária da categoria',

  // Materia de negocio, escrita para lojista e nao para dono de pet
  'mercado pet brasileiro', 'faturamento', 'balanço financeiro',
  'balanco financeiro', 'franquia', 'investidores',
];

/** Quantas noticias o app mantem publicadas. */
export const LIMITE_DE_NOTICIAS = 30;

/** Descarta itens mais velhos que isso, para o app nao mostrar noticia morta. */
export const IDADE_MAXIMA_EM_DIAS = 60;
