import 'package:cloud_firestore/cloud_firestore.dart';

class News {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String author;
  final String sourceUrl;
  /// Capa da materia, tirada da og:image do veiculo. Vem vazia quando o site
  /// nao publica a metatag ou quando o link e um redirect do Google Noticias,
  /// que nao da para resolver fora do navegador.
  final String imageUrl;
  /// Marca resumo gerado por IA a partir do texto da materia. O app precisa
  /// avisar isso ao leitor - resumo automatico pode errar enfase.
  final bool aiSummary;
  /// `noticia` (fato datado) ou `cuidado` (guia que nao envelhece). Sao
  /// formatos diferentes, procurados em momentos diferentes, entao cada um vai
  /// para a sua aba. Documento antigo, sem o campo, conta como noticia.
  final String tipo;

  News({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.author,
    required this.sourceUrl,
    this.imageUrl = '',
    this.aiSummary = false,
    this.tipo = 'noticia',
  });

  bool get temCapa => imageUrl.isNotEmpty;
  bool get ehGuiaDeCuidado => tipo == 'cuidado';

  factory News.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return News(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      author: data['author'] ?? '',
      sourceUrl: data['sourceUrl'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      aiSummary: data['aiSummary'] ?? false,
      tipo: data['tipo'] ?? 'noticia',
    );
  }
}