import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/news.dart';

/// Detalhe da noticia: capa, resumo e o caminho para a materia completa.
///
/// O app nao reproduz o texto integral de proposito - ele pertence ao veiculo.
/// O que fica aqui e o resumo que o proprio veiculo publica na og:description,
/// e dai o leitor decide se abre a fonte.
class NewsDetailScreen extends StatelessWidget {
  final News news;
  const NewsDetailScreen({super.key, required this.news});

  static const _meses = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  String get _dataFormatada =>
      '${news.date.day} de ${_meses[news.date.month - 1]}. de ${news.date.year}';

  /// "há 2 dias" comunica melhor que uma data seca se a noticia e recente.
  String get _quandoSaiu {
    final dias = DateTime.now().difference(news.date).inDays;
    if (dias <= 0) return 'hoje';
    if (dias == 1) return 'ontem';
    if (dias < 7) return 'há $dias dias';
    return _dataFormatada;
  }

  Future<void> _abrirMateria(BuildContext context) async {
    final uri = Uri.tryParse(news.sourceUrl);
    if (uri == null) return;
    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel abrir a noticia.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final temLink = news.sourceUrl.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Notícia')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (news.temCapa) _capa(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _origem(),
                const SizedBox(height: 14),
                Text(
                  news.title,
                  style: TextStyle(
                    fontSize: 23,
                    height: 1.3,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade900,
                  ),
                ),
                const SizedBox(height: 18),
                if (news.description.isNotEmpty &&
                    news.description != news.author) ...[
                  Text(
                    news.description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.brown.shade800,
                    ),
                  ),
                  if (news.aiSummary) _avisoDeIA(),
                  const SizedBox(height: 24),
                ] else ...[
                  // Materia sem resumo disponivel: dizer isso e melhor do que
                  // deixar um espaco vazio sem explicacao.
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 20, color: Colors.brown.shade400),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Este veículo não publicou um resumo. Abra a '
                            'notícia completa para ler.',
                            style: TextStyle(
                              color: Colors.brown.shade600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (temLink) _botaoLerCompleta(context),
                const SizedBox(height: 12),
                Text(
                  'O conteúdo completo é do veículo original.',
                  style: TextStyle(fontSize: 12, color: Colors.brown.shade300),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _capa() {
    return SizedBox(
      height: 210,
      width: double.infinity,
      child: Image.network(
        news.imageUrl,
        fit: BoxFit.cover,
        // Sem placeholder de altura fixa a lista "pula" quando a imagem chega.
        loadingBuilder: (_, filho, progresso) {
          if (progresso == null) return filho;
          return Container(
            color: Colors.brown.shade50,
            child: const Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          color: Colors.brown.shade50,
          child: Icon(Icons.image_not_supported_outlined,
              size: 40, color: Colors.brown.shade200),
        ),
      ),
    );
  }

  /// Aviso discreto de que o resumo foi gerado, nao escrito pelo veiculo.
  Widget _avisoDeIA() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 13, color: Colors.brown.shade300),
          const SizedBox(width: 5),
          Text(
            'Resumido por IA',
            style: TextStyle(fontSize: 11.5, color: Colors.brown.shade300),
          ),
        ],
      ),
    );
  }

  Widget _origem() {
    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.brown.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.brown.shade100),
            ),
            child: Text(
              news.author,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.brown.shade700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _quandoSaiu,
          style: TextStyle(fontSize: 12.5, color: Colors.brown.shade400),
        ),
      ],
    );
  }

  Widget _botaoLerCompleta(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => _abrirMateria(context),
        icon: const Icon(Icons.open_in_new, size: 20),
        label: const Text(
          'Ler notícia completa',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
