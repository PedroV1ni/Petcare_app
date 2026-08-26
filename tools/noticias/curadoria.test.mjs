// Testes do filtro que decide o que vira noticia no app.
//
//   node --test
//
// Este filtro e o unico ponto do pipeline que separa "materia sobre pet" de
// qualquer outra coisa que o feed publicar. Quando ele erra, o erro chega ao
// usuario: a Petz entrou como fonte e passou a aprovar 10 de 10 itens, entre
// eles "Como limpar piscina verde" - porque o trecho "pet" casava com "Petz".

import test from 'node:test';
import assert from 'node:assert/strict';

import { classificar, ehSobrePets, motivoDeDescarte } from './agregar.js';
import { dicaEhAutossuficiente } from './resumir.js';

test('nome da fonte nao faz o item parecer sobre pet', () => {
  assert.equal(ehSobrePets('Como limpar piscina verde: passo a passo | Petz'), false);
  assert.equal(ehSobrePets('Receita de bolo publicada no blog da Petz'), false);
});

test('palavra dentro de outra nao conta', () => {
  assert.equal(ehSobrePets('Competencia e apetite do investidor'), false);
  assert.equal(ehSobrePets('Carpete novo na sala'), false);
});

test('materia sobre pet passa', () => {
  assert.equal(ehSobrePets('Cuidados com seu pet no verao'), true);
  assert.equal(ehSobrePets('Vacinacao de caes e gatos comeca segunda'), true);
  assert.equal(ehSobrePets('Tutor deve observar o comportamento do felino'), true);
});

test('raiz casa com as variacoes da palavra', () => {
  assert.equal(ehSobrePets('CastraMovel atende no bairro'), true);
  assert.equal(ehSobrePets('Castracao gratuita na praca'), true);
  assert.equal(ehSobrePets('Medica veterinaria explica o caso'), true);
  assert.equal(ehSobrePets('Campanha antirrabica comeca hoje'), true);
});

test('acento nao muda o resultado', () => {
  assert.equal(ehSobrePets('Vacinação de cães'), true);
  assert.equal(ehSobrePets('Vacinacao de caes'), true);
});

test('descarta ato administrativo e conteudo policial', () => {
  assert.ok(motivoDeDescarte('EDITAL DO PREGAO ELETRONICO 54/2026'));
  assert.ok(motivoDeDescarte('Homem preso por maus-tratos a cachorro'));
  assert.ok(motivoDeDescarte('Nota de pesar pelo falecimento'));
});

test('descarta anuncio de loja', () => {
  assert.ok(motivoDeDescarte('Zee.Dog chega a Cobasi com acessorios premium'));
  assert.ok(motivoDeDescarte('Racao em promocao nesta semana'));
});

test('materia boa nao e descartada por engano', () => {
  assert.equal(motivoDeDescarte('Caspa em cachorro: como identificar e tratar'), null);
  assert.equal(motivoDeDescarte('Pode dar dipirona para cachorro?'), null);
  assert.equal(motivoDeDescarte('10 sinais de que um gato esta triste'), null);
  // "mortalidade" contem "morta", que esta na lista de exclusao como palavra
  // inteira. Se o teste falhar aqui, o filtro voltou a comparar por trecho.
  assert.equal(motivoDeDescarte('Estudo mede a mortalidade infantil em filhotes'), null);
});

test('guia de cuidado nao entra como noticia', () => {
  assert.equal(classificar('Como acostumar gato a caixa de transporte?', 'guias'), 'cuidado');
  assert.equal(classificar('10 sinais de que um gato esta triste', 'guias'), 'cuidado');
  assert.equal(classificar('Pode dar dipirona para cachorro?', 'guias'), 'cuidado');
  assert.equal(classificar('Melhor areia para gatos: 5 dicas', 'guias'), 'cuidado');
});

test('fato datado e noticia mesmo com cara de guia', () => {
  // Comeca com "Como", que e formato de guia, mas fala de um fato datado.
  assert.equal(classificar('Como a prefeitura vai agendar a castracao', 'guias'), 'noticia');
  assert.equal(classificar('Campanha de vacinacao antirrabica comeca nesta segunda', 'guias'), 'noticia');
});

test('sem sinal no titulo, vale o perfil da fonte', () => {
  assert.equal(classificar('Caspa em cachorro: identificar e tratar', 'guias'), 'cuidado');
  assert.equal(classificar('Medico-veterinario em casa: ate onde vai o atendimento', 'noticias'), 'noticia');
});

test('descarta pauta dirigida ao veterinario, nao ao dono', () => {
  assert.ok(motivoDeDescarte('Reajuste da anuidade para o ano de 2027'));
  assert.ok(motivoDeDescarte('Formulario para receber a cedula em Itapetinga'));
  assert.ok(motivoDeDescarte('Codigo de Etica do Medico Veterinario'));
  assert.ok(motivoDeDescarte('Portaria CRMV/GO no 58/2026'));
  assert.ok(motivoDeDescarte('Ministerio da Saude abre selecao com vagas para medicos-veterinarios'));
});

test('noticia que muda a vida do dono continua passando', () => {
  assert.equal(
    motivoDeDescarte('Projeto preve suspensao da CNH por abandono de animais'),
    null,
  );
  assert.equal(motivoDeDescarte('Atendimento medico-veterinario domiciliar'), null);
});

test('dica que nao diz de quem fala e recusada', () => {
  // Casos reais das versoes 1 e 2 das regras, nesta ordem.
  assert.equal(dicaEhAutossuficiente('Grave o episodio e mostre ao veterinario'), false);
  assert.equal(
    dicaEhAutossuficiente('Grave o episodio de movimento intenso e mostre ao veterinario'),
    false,
  );
  assert.equal(dicaEhAutossuficiente('Fique atento a isso no dia a dia'), false);
  assert.equal(dicaEhAutossuficiente('Observe o comportamento e procure ajuda'), false);
});

// A partir da versao 4 das regras a dica tem de ser uma frase terminada:
// e assim que o codigo pega o corte no meio da frase.
test('dica que nomeia animal e situacao passa', () => {
  assert.ok(dicaEhAutossuficiente('Filme o cao se ele se mexer muito dormindo.'));
  assert.ok(dicaEhAutossuficiente('Observe se a caspa do cachorro vem com coceira.'));
  assert.ok(dicaEhAutossuficiente('Ofereca esconderijos ao gato para enriquecer o ambiente.'));
  assert.ok(dicaEhAutossuficiente('Consulte o veterinario antes de dar dipirona ao seu cao.'));
});

test('acento e caixa nao mudam a conferencia', () => {
  assert.ok(dicaEhAutossuficiente('Escove os dentes do CÃO duas vezes por semana.'));
  assert.equal(dicaEhAutossuficiente('Grave O EPISÓDIO e mostre ao veterinario.'), false);
});

test('dica cortada no meio e recusada', () => {
  // Caso real da versao 3: cabia nos 90 caracteres, mas nao diz quem consultar.
  assert.equal(
    dicaEhAutossuficiente('Observe se o cachorro tem febre ou dor e consulte'),
    false,
  );
  assert.equal(dicaEhAutossuficiente('Leve o gato ao veterinario se ele parar de comer e'), false);
  assert.equal(dicaEhAutossuficiente('Escove os dentes do cao com'), false);
});

test('frase inteira e terminada passa', () => {
  assert.ok(dicaEhAutossuficiente('Observe se o cachorro tem febre e leve ao veterinario.'));
  assert.ok(dicaEhAutossuficiente('Escove os dentes do cao duas vezes por semana.'));
});
