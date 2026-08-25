import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/news.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatelessWidget {
  final _service = DataService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<News>>(
      stream: _service.streamNews(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final list = snap.data!;
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final news = list[i];
            return ListTile(
              leading: const Icon(Icons.article, size: 36),
              title: Text(news.title, style: Theme.of(context).textTheme.titleLarge),
              subtitle: Text(news.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => NewsDetailScreen(news: news),
                ));
              },
            );
          },
        );
      },
    );
  }
}