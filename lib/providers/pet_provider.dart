import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/pet_model.dart';

/// Pets do usuario logado, em `users/{uid}/pets`.
///
/// A lista chega por stream do Firestore: entrar na conta assina a colecao,
/// sair cancela e limpa. Como o snapshot dispara sozinho, nao existe mais o
/// problema antigo de a tela abrir vazia porque ninguem chamou o load.
class PetProvider with ChangeNotifier {
  PetProvider() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _petsSub;

  List<PetModel> _pets = [];
  bool _isLoading = false;
  String? _error;
  String? _uid;

  List<PetModel> get pets => List.unmodifiable(_pets);
  bool get isLoading => _isLoading;
  String? get error => _error;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(_uid).collection('pets');

  // ----- Ciclo de vida da sessao -----

  void _onAuthChanged(User? user) {
    if (user?.uid == _uid) return;
    _uid = user?.uid;
    _petsSub?.cancel();
    _petsSub = null;

    if (_uid == null) {
      _pets = [];
      _isLoading = false;
      _error = null;
      notifyListeners();
      return;
    }
    _subscribe();
  }

  void _subscribe() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _petsSub = _col.orderBy('name').snapshots().listen(
      (snap) {
        _pets = snap.docs.map((d) => PetModel.fromJson(d.data())).toList();
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Erro ao carregar pets: $e';
        _isLoading = false;
        debugPrint(_error);
        notifyListeners();
      },
    );
  }

  /// Reassina a colecao. Serve para o botao de tentar de novo das telas.
  Future<void> loadPets() async {
    if (_uid == null) return;
    await _petsSub?.cancel();
    _subscribe();
  }

  // ----- CRUD -----

  Future<void> addPet(PetModel pet) async {
    if (_uid == null) return;
    try {
      await _col.doc(pet.id).set(pet.toJson());
    } catch (e) {
      _error = 'Erro ao adicionar pet: $e';
      notifyListeners();
    }
  }

  Future<void> updatePet(PetModel updated) async {
    if (_uid == null) return;
    try {
      await _col.doc(updated.id).set(updated.toJson());
    } catch (e) {
      _error = 'Erro ao atualizar pet: $e';
      notifyListeners();
    }
  }

  Future<void> removePet(String id) async {
    if (_uid == null) return;
    try {
      await _col.doc(id).delete();
    } catch (e) {
      _error = 'Erro ao remover pet: $e';
      notifyListeners();
    }
  }

  PetModel? getPetById(String id) {
    try {
      return _pets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ----- Atividade real (baseada em lembretes) -----

  /// Retorna 0.0-1.0 com base nos lembretes concluidos hoje.
  /// Recebe a lista de lembretes para nao criar dependencia circular.
  double activityProgress(
      List completedTodayReminders, List allTodayReminders) {
    if (allTodayReminders.isEmpty) return 0.0;
    return (completedTodayReminders.length / allTodayReminders.length)
        .clamp(0.0, 1.0);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _petsSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
