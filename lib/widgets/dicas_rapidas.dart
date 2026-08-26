import 'package:flutter/material.dart';

import '../models/news.dart';
import '../screens/news_detail_screen.dart';
import '../services/data_service.dart';

/// Faixa de dicas da tela Início.
///
/// Mostra as dicas tiradas dos guias reais e, quando nao ha nenhuma, cai numa
/// lista fixa. A reserva existe porque esta faixa e o primeiro conteudo que
/// aparece ao abrir o app: se dependesse so do feed, ficaria vazia enquanto a
/// consulta carrega, sem internet, ou numa semana quieta nas fontes.
///
/// A diferenca entre as duas fica visivel - dica real leva a materia e mostra
/// o veiculo; a de reserva nao, porque nao ha materia por tras dela.
class DicasRapidas extends StatelessWidget {
  /// `guias` existe para o teste poder injetar um stream e conferir a queda
  /// para a reserva. No app fica de fora e vale o Firestore.
  DicasRapidas({super.key, Stream<List<News>>? guias})
      : _guias = guias ?? DataService().streamGuiasDeCuidado();

  final Stream<List<News>> _guias;

  /// Reserva. Cuidados basicos que valem em qualquer epoca, justamente por
  /// isso nao envelhecem enquanto ficam guardados aqui.
  static const _reserva = [
    'Escove o pelo regularmente',
    'Ofereça água fresca sempre',
    'Passeie pelo menos 30 min hoje',
    'Verifique as vacinas em dia',
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<News>>(
      stream: _guias,
      builder: (ctx, snap) {
        // Sem `hasData` ainda, `?? []` cai direto na reserva: mostrar a faixa
        // preenchida e melhor que um vazio de meio segundo toda vez que a
        // tela abre.
        final comDica = (snap.data ?? []).where((g) => g.temDica).toList();

        return SizedBox(
          height: 92,
          child: comDica.isEmpty
              ? ListView(
                  scrollDirection: Axis.horizontal,
                  children: _reserva.map(_cartaoSimples).toList(),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: comDica.length,
                  itemBuilder: (_, i) => _cartaoDeGuia(context, comDica[i]),
                ),
        );
      },
    );
  }

  Widget _molde({required Widget filho, VoidCallback? aoTocar}) {
    return Container(
      width: 186,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        color: Colors.amber.shade50,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: filho,
          ),
        ),
      ),
    );
  }

  Widget _cartaoSimples(String texto) => _molde(
        filho: Align(
          alignment: Alignment.topLeft,
          child: Text(texto, style: const TextStyle(fontSize: 13)),
        ),
      );

  Widget _cartaoDeGuia(BuildContext context, News guia) {
    return _molde(
      aoTocar: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NewsDetailScreen(news: guia)),
      ),
      filho: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              guia.dica,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, height: 1.3),
            ),
          ),
          const SizedBox(height: 4),
          // O veiculo aparece porque a dica nao e do app: e de quem publicou a
          // materia. Sem isso o app estaria assinando um conselho alheio.
          Text(
            guia.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, color: Colors.brown.shade400),
          ),
        ],
      ),
    );
  }
}
