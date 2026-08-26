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

  testWidgets('a ordem nao muda entre dois builds do mesmo dia', (tester) async {
    // A ordem e embaralhada com a data como semente. Se alguem trocar por um
    // sorteio a cada build, os cartoes passam a pular de lugar sozinhos - a
    // cada lembrete marcado na tela Inicio - e este teste falha.
    List<String> ordemDosCartoes() =>
        tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').toList();

    // Tres builds, e nao dois: com quatro cartoes, um sorteio solto ainda
    // repetiria a ordem em 1 de 24 tentativas, e o teste passaria as vezes
    // mesmo quebrado. Em tres, isso cai para 1 em 576.
    final ordens = <List<String>>[];
    for (var i = 0; i < 3; i++) {
      await montar(tester, StreamController<List<News>>().stream);
      ordens.add(ordemDosCartoes());
    }

    expect(ordens[1], equals(ordens[0]));
    expect(ordens[2], equals(ordens[0]));
    expect(ordens[0].length, 4);
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
