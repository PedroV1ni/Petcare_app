import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/care.dart';
import 'care_detail_screen.dart';

class CareScreen extends StatelessWidget {
  final DataService _service = DataService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Care>>(
      stream: _service.streamCare(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final cares = snap.data ?? [];
        if (cares.isEmpty) {
          return const Center(child: Text('Nenhuma dica de cuidado encontrada.'));
        }
        return ListView.builder(
          itemCount: cares.length,
          itemBuilder: (_, i) {
            final care = cares[i];
            return ListTile(
              leading: const Icon(Icons.favorite, size: 36),
              title: Text(
                care.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Text(
                care.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CareDetailScreen(care: care),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}