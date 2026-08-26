import 'package:flutter/material.dart';

import '../models/news.dart';
import '../services/data_service.dart';
import '../utils/app_widgets.dart';
import '../widgets/news_card.dart';
import 'news_detail_screen.dart';

/// Aba Cuidados: guias vindos das fontes, e as dicas tiradas deles.
///
/// Antes as dicas eram escritas a mao dentro do app. Agora toda dica sai do
/// texto de uma materia real e leva a ela: tocar na dica abre o guia de onde
/// ela veio, para o leitor conferir o contexto em vez de confiar numa frase
/// solta.
class CareScreen extends StatelessWidget {
  CareScreen({super.key});

  final DataService _service = DataService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<News>>(
      stream: _service.streamGuiasDeCuidado(),
      builder: (ctx, snap) {
        if (snap.hasError) {
          return AppErrorWidget(
              message: 'Erro ao carregar cuidados: ${snap.error}');
        }
        if (!snap.hasData) {
          return const AppLoadingWidget(message: 'Carregando cuidados...');
        }
        final guias = snap.data!;
        if (guias.isEmpty) {
          return const AppEmptyWidget(
            message: 'Nenhum guia de cuidado por enquanto.',
            icon: Icons.favorite_outline,
          );
        }

        final comDica = guias.where((g) => g.temDica).toList();

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (comDica.isNotEmpty) _dicas(context, comDica),
            _titulo(
              'Guias das fontes',
              explicacao: 'Publicados por veículos e conselhos de veterinária',
            ),
            for (var i = 0; i < guias.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Colors.brown.shade50,
                ),
              NewsCard(news: guias[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _titulo(String texto, {String? explicacao}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texto,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.brown.shade900,
            ),
          ),
          if (explicacao != null) ...[
            const SizedBox(height: 3),
            Text(
              explicacao,
              style: TextStyle(fontSize: 12.5, color: Colors.brown.shade400),
            ),
          ],
        ],
      ),
    );
  }

  /// Faixa horizontal de dicas. Horizontal de proposito: sao frases curtas, e
  /// empilhadas ocupariam a tela toda antes de o leitor chegar nos guias.
  Widget _dicas(BuildContext context, List<News> comDica) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('Dicas rápidas', explicacao: 'Tiradas das matérias abaixo'),
        SizedBox(
          height: 152,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: comDica.length,
            separatorBuilder: (_, __) => const SizedBox(width: 11),
            itemBuilder: (_, i) => _cartaoDeDica(context, comDica[i]),
          ),
        ),
      ],
    );
  }

  Widget _cartaoDeDica(BuildContext context, News guia) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NewsDetailScreen(news: guia)),
      ),
      child: Container(
        width: 230,
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
        decoration: BoxDecoration(
          color: Colors.brown.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.brown.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline, size: 19, color: Colors.brown.shade400),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                guia.dica,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: Colors.brown.shade900,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // A fonte fica visivel na propria dica: sem isso ela viraria um
            // conselho do app, e o app nao e quem esta dizendo aquilo.
            Text(
              guia.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.brown.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
