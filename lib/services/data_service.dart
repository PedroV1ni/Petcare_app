import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news.dart';

class DataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Tudo que o agregador publicou, da mais recente para a mais antiga.
  ///
  /// A separacao entre noticia e guia e feita aqui na memoria, e nao com um
  /// `where` no Firestore, porque combinar filtro e ordenacao em campos
  /// diferentes exigiria criar um indice composto no console. A colecao tem
  /// duas dezenas de documentos - nao compensa a burocracia.
  Stream<List<News>> _streamPorTipo(bool Function(News) aceita) => _db
      .collection('news')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => News.fromFirestore(d)).where(aceita).toList());

  /// Fato datado: o que aparece na aba Notícias.
  Stream<List<News>> streamNews() => _streamPorTipo((n) => !n.ehGuiaDeCuidado);

  /// Guia que nao envelhece: alimenta a aba Cuidados.
  Stream<List<News>> streamGuiasDeCuidado() =>
      _streamPorTipo((n) => n.ehGuiaDeCuidado);
}