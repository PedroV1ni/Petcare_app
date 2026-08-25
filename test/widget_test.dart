import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_app/models/breed.dart';
import 'package:petcare_app/models/pet_model.dart';
import 'package:petcare_app/models/reminder_model.dart';

/// Testes de modelo e de integridade dos assets.
///
/// Nao exercitam telas de proposito: o app chama Firebase.initializeApp no
/// main, e subir a arvore de widgets em teste exigiria mocks de Firebase que
/// dariam mais manutencao do que valor. O que esta coberto aqui e a parte
/// que quebra em silencio - serializacao e assets.
void main() {
  group('PetModel', () {
    final pet = PetModel(
      id: 'abc',
      name: 'Mel',
      description: 'Princesa',
      birthDate: DateTime(2020, 6, 15),
      breed: 'Poodle',
      species: 'dog',
      size: 'Pequeno',
      weight: 8.5,
      imageUrl: 'assets/pets/rex.jpg',
    );

    test('sobrevive a ida e volta por JSON', () {
      final volta = PetModel.fromJson(pet.toJson());
      expect(volta.id, pet.id);
      expect(volta.name, pet.name);
      expect(volta.breed, pet.breed);
      expect(volta.species, pet.species);
      expect(volta.weight, pet.weight);
      expect(volta.birthDate, pet.birthDate);
      expect(volta.imageUrl, pet.imageUrl);
    });

    test('idade desconta aniversario que ainda nao chegou', () {
      final hoje = DateTime.now();
      final fazAmanha = pet.copyWith(
        birthDate: DateTime(hoje.year - 5, hoje.month, hoje.day)
            .add(const Duration(days: 1)),
      );
      expect(fazAmanha.age, 4);

      final jaFez = pet.copyWith(
        birthDate: DateTime(hoje.year - 5, hoje.month, hoje.day)
            .subtract(const Duration(days: 1)),
      );
      expect(jaFez.age, 5);
    });

    test('distingue imagem de asset de arquivo do aparelho', () {
      expect(pet.isAssetImage, isTrue);
      expect(
        pet.copyWith(imageUrl: '/data/user/0/foto.jpg').isAssetImage,
        isFalse,
      );
    });
  });

  group('ReminderModel', () {
    test('sobrevive a ida e volta por JSON', () {
      final r = ReminderModel(
        id: 'r1',
        petId: 'abc',
        title: 'Vacina',
        type: 'vacina',
        dateTime: DateTime(2026, 3, 10, 14, 30),
        notes: 'Levar carteirinha',
        isDone: true,
      );
      final volta = ReminderModel.fromJson(r.toJson());
      expect(volta.id, r.id);
      expect(volta.petId, r.petId);
      expect(volta.type, r.type);
      expect(volta.dateTime, r.dateTime);
      expect(volta.notes, r.notes);
      expect(volta.isDone, isTrue);
    });

    test('assume padroes quando o documento vem incompleto', () {
      final r = ReminderModel.fromJson({
        'dateTime': DateTime(2026, 1, 1).toIso8601String(),
      });
      expect(r.type, 'outro');
      expect(r.isDone, isFalse);
      expect(r.notes, isNull);
    });
  });

  group('Breed', () {
    test('assume padroes quando faltam campos', () {
      final b = Breed.fromJson({'name': 'Teste'});
      expect(b.name, 'Teste');
      expect(b.species, 'dog');
      expect(b.temperament, isEmpty);
      expect(b.tips, isEmpty);
      expect(b.curiosities, isEmpty);
    });
  });

  group('assets/breeds/breeds.json', () {
    late List<Breed> racas;

    setUpAll(() {
      final bruto = File('assets/breeds/breeds.json').readAsStringSync();
      racas = (json.decode(bruto) as List)
          .map((e) => Breed.fromJson(e as Map<String, dynamic>))
          .toList();
    });

    test('e um JSON valido e nao esta vazio', () {
      expect(racas, isNotEmpty);
    });

    test('toda raca tem nome, descricao e especie conhecida', () {
      for (final b in racas) {
        expect(b.name, isNotEmpty, reason: 'raca sem nome');
        expect(b.description, isNotEmpty, reason: '${b.name} sem descricao');
        expect(b.species, anyOf('dog', 'cat'),
            reason: '${b.name} com especie inesperada: ${b.species}');
      }
    });

    // Este e o teste que teria pegado o bug das 15 fotos ausentes: o app nao
    // quebrava, so caia no placeholder, entao a falha passava despercebida.
    test('o arquivo de imagem de toda raca existe no disco', () {
      final faltando = <String>[];
      for (final b in racas) {
        expect(b.image, isNotEmpty, reason: '${b.name} sem caminho de imagem');
        if (!File(b.image).existsSync()) faltando.add('${b.name} -> ${b.image}');
      }
      expect(faltando, isEmpty,
          reason: 'imagens declaradas mas ausentes:\n${faltando.join('\n')}');
    });

    test('nao ha nome de raca repetido dentro da mesma especie', () {
      final vistos = <String>{};
      for (final b in racas) {
        final chave = '${b.species}:${b.name.toLowerCase()}';
        expect(vistos.add(chave), isTrue, reason: 'raca duplicada: ${b.name}');
      }
    });
  });
}
