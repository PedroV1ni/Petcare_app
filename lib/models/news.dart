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

  News({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.author,
    required this.sourceUrl,
    this.imageUrl = '',
  });

  bool get temCapa => imageUrl.isNotEmpty;

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
    );
  }
}