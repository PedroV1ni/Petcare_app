import 'package:cloud_firestore/cloud_firestore.dart';

class News {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String author;
  final String sourceUrl;  // novo

  News({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.author,
    required this.sourceUrl,
  });

  factory News.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return News(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      author: data['author'] ?? '',
      sourceUrl: data['sourceUrl'] ?? '',
    );
  }
}