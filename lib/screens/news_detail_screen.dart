import 'package:flutter/material.dart';
import '../models/news.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsDetailScreen extends StatelessWidget {
  final News news;
  const NewsDetailScreen({Key? key, required this.news}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(news.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Autor:', style: Theme.of(context).textTheme.titleMedium),
          Text(news.author),
          const SizedBox(height: 12),

          Text('Data:', style: Theme.of(context).textTheme.titleMedium),
          Text('${news.date.day}/${news.date.month}/${news.date.year}'),
          const SizedBox(height: 12),

          Text('Descrição:', style: Theme.of(context).textTheme.titleMedium),
          Text(news.description),
          const SizedBox(height: 12),

          if (news.sourceUrl.isNotEmpty) ...[
            Text('Fonte:', style: Theme.of(context).textTheme.titleMedium),
            InkWell(
              onTap: () => launchUrl(Uri.parse(news.sourceUrl)),
              child: Text(
                news.sourceUrl,
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}