import 'package:flutter/material.dart';
import '../models/care.dart';

class CareDetailScreen extends StatelessWidget {
  final Care care;
  const CareDetailScreen({Key? key, required this.care}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(care.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Categoria:', style: Theme.of(context).textTheme.titleMedium),
          Text(care.category),
          const SizedBox(height: 12),

          Text('Descrição:', style: Theme.of(context).textTheme.titleMedium),
          Text(care.description),
          const SizedBox(height: 12),

          if (care.steps != null && care.steps!.isNotEmpty) ...[
            Text('Passos:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            ...care.steps!.map((s) => Text('• $s')).toList(),
          ],
        ]),
      ),
    );
  }
}