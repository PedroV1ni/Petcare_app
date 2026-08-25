import 'package:cloud_firestore/cloud_firestore.dart';

class Care {
  final String id;
  final String title;
  final String description;
  final String category;
  final List<String>? steps;  // opcional

  Care({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.steps,
  });

  factory Care.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Care(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      steps: data['steps'] != null ? List<String>.from(data['steps']) : null,
    );
  }
}