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

import { ehSobrePets, motivoDeDescarte } from './agregar.js';

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
