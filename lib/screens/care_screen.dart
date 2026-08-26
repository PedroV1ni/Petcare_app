import 'package:flutter/material.dart';

import '../models/care.dart';
import '../models/news.dart';
import '../services/data_service.dart';
import '../widgets/news_card.dart';
import 'care_detail_screen.dart';

/// Aba Cuidados: as dicas do proprio app mais os guias vindos dos feeds.
///
/// Guia de cuidado ("Pode dar dipirona para cachorro?") chegava junto com as
/// noticias e envelhecia junto com elas, apesar de continuar valendo. Aqui ele
/// fica onde o leitor procura quando tem uma duvida, e nao quando quer saber
/// o que aconteceu.
class CareScreen extends StatelessWidget {
  CareScreen({super.key});

  final DataService _service = DataService();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _dicasDoApp(context),
        _guiasDasFontes(),
      ],
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

  Widget _dicasDoApp(BuildContext context) {
    return StreamBuilder<List<Care>>(
      stream: _service.streamCare(),
      builder: (ctx, snap) {
        final cares = snap.data ?? [];
        if (cares.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _titulo('Dicas do PetCare'),
            ...cares.map(
              (care) => ListTile(
                leading: Icon(Icons.favorite, size: 30, color: Colors.brown.shade300),
                title: Text(
                  care.title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.brown.shade900,
                  ),
                ),
                subtitle: Text(
                  care.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, color: Colors.brown.shade400),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CareDetailScreen(care: care)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _guiasDasFontes() {
    return StreamBuilder<List<News>>(
      stream: _service.streamGuiasDeCuidado(),
      builder: (ctx, snap) {
        final guias = snap.data ?? [];
        if (guias.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
}
