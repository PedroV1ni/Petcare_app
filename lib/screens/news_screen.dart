import 'package:flutter/material.dart';

import '../models/news.dart';
import '../services/data_service.dart';
import '../utils/app_widgets.dart';
import '../widgets/news_card.dart';

/// Aba Notícias: so fato datado.
///
/// Guia de cuidado vem dos mesmos feeds mas vive na aba Cuidados - guia
/// responde uma duvida e nao envelhece, noticia e um acontecimento. Misturar
/// os dois fazia "Como acostumar gato a caixa de transporte" aparecer como
/// se fosse noticia do dia.
class NewsScreen extends StatelessWidget {
  NewsScreen({super.key});

  final _service = DataService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<News>>(
      stream: _service.streamNews(),
      builder: (ctx, snap) {
        if (snap.hasError) {
          return AppErrorWidget(
              message: 'Erro ao carregar notícias: ${snap.error}');
        }
        if (!snap.hasData) {
          return const AppLoadingWidget(message: 'Carregando notícias...');
        }
        // Ja vem do Firestore da mais recente para a mais antiga.
        final lista = snap.data!;
        if (lista.isEmpty) {
          return const AppEmptyWidget(
            message: 'Nenhuma notícia por enquanto.',
            icon: Icons.article_outlined,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: lista.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.brown.shade50,
          ),
          itemBuilder: (_, i) => NewsCard(news: lista[i]),
        );
      },
    );
  }
}
