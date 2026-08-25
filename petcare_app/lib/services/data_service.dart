import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news.dart';
import '../models/care.dart';

class DataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<News>> streamNews() => _db
      .collection('news')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => News.fromFirestore(d)).toList());

  Stream<List<Care>> streamCare() => _db
      .collection('care')
      .orderBy('title')
      .snapshots()
      .map((snap) => snap.docs.map((d) => Care.fromFirestore(d)).toList());
}