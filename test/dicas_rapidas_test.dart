import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_app/models/news.dart';
import 'package:petcare_app/widgets/dicas_rapidas.dart';

/// A faixa de dicas e o primeiro conteudo da tela Inicio. Ela precisa aparecer
/// preenchida em qualquer situacao - inclusive sem internet, enquanto carrega,
/// ou numa semana em que as fontes nao renderam nenhuma dica.

News guia({required String dica, String autor = 'Cobasi'}) => News(
      id: 'x',
      title: 'Guia qualquer',
      description: 'Resumo qualquer',
      date: DateTime(2026, 8, 20),
      author: autor,
      sourceUrl: 'https://exemplo.com/materia',
      tipo: 'cuidado',
      dica: dica,
    );

Future<void> montar(WidgetTester tester, Stream<List<News>> guias) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: DicasRapidas(guias: guias))),
  );
  await tester.pump();
}

void main() {
  testWidgets('mostra a reserva enquanto o stream nao respondeu', (tester) async {
    // Stream que nunca emite: e o instante em que a tela abre.
    await montar(tester, StreamController<List<News>>().stream);

    expect(find.text('Escove o pelo regularmente'), findsOneWidget);
  });

  testWidgets('mostra a reserva quando nenhum guia rendeu dica', (tester) async {
    await montar(tester, Stream.value([guia(dica: '')]));

    expect(find.text('Ofereça água fresca sempre'), findsOneWidget);
  });

  testWidgets('mostra a reserva quando a consulta falha', (tester) async {
    await montar(tester, Stream<List<News>>.error(Exception('sem rede')));

    expect(find.text('Verifique as vacinas em dia'), findsOneWidget);
  });

  testWidgets('dica real substitui a reserva e mostra o veiculo', (tester) async {
    await montar(
      tester,
      Stream.value([guia(dica: 'Observe a pelagem toda semana', autor: 'Petz')]),
    );

    expect(find.text('Observe a pelagem toda semana'), findsOneWidget);
    expect(find.text('Petz'), findsOneWidget);
    // Reserva sai de cena assim que ha dica de verdade.
    expect(find.text('Escove o pelo regularmente'), findsNothing);
  });

  testWidgets('guia sem dica nao entra na faixa', (tester) async {
    await montar(
      tester,
      Stream.value([
        guia(dica: ''),
        guia(dica: 'Deixe agua fresca em mais de um comodo'),
      ]),
    );

    expect(find.text('Deixe agua fresca em mais de um comodo'), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
  });
}
