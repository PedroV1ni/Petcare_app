import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/reminder_model.dart';

/// Lembretes do usuario logado, em `users/{uid}/reminders`.
///
/// Mesmo desenho do PetProvider: a colecao e assinada no login e liberada no
/// logout, e a lista se atualiza sozinha a cada mudanca no Firestore.
class ReminderProvider with ChangeNotifier {
  ReminderProvider() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _remSub;

  List<ReminderModel> _reminders = [];
  bool _isLoading = false;
  String? _error;
  String? _uid;

  List<ReminderModel> get reminders => List.unmodifiable(_reminders);
  bool get isLoading => _isLoading;
  String? get error => _error;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(_uid).collection('reminders');

  // ----- Helpers de hoje -----

  List<ReminderModel> todayReminders(String petId) {
    final now = DateTime.now();
    return _reminders.where((r) {
      return r.petId == petId &&
          r.dateTime.year == now.year &&
          r.dateTime.month == now.month &&
          r.dateTime.day == now.day;
    }).toList();
  }

  List<ReminderModel> completedTodayReminders(String petId) =>
      todayReminders(petId).where((r) => r.isDone).toList();

  List<ReminderModel> upcomingReminders(String petId) {
    final now = DateTime.now();
    return _reminders
        .where((r) => r.petId == petId && r.dateTime.isAfter(now) && !r.isDone)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // ----- Ciclo de vida da sessao -----

  void _onAuthChanged(User? user) {
    if (user?.uid == _uid) return;
    _uid = user?.uid;
    _remSub?.cancel();
    _remSub = null;

    if (_uid == null) {
      _reminders = [];
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

    _remSub = _col.orderBy('dateTime').snapshots().listen(
      (snap) {
        _reminders =
            snap.docs.map((d) => ReminderModel.fromJson(d.data())).toList();
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Erro ao carregar lembretes: $e';
        _isLoading = false;
        debugPrint(_error);
        notifyListeners();
      },
    );
  }

  /// Reassina a colecao. Serve para o botao de tentar de novo das telas.
  Future<void> loadReminders() async {
    if (_uid == null) return;
    await _remSub?.cancel();
    _subscribe();
  }

  // ----- CRUD -----

  Future<void> addReminder(ReminderModel reminder) async {
    if (_uid == null) return;
    try {
      await _col.doc(reminder.id).set(reminder.toJson());
    } catch (e) {
      _error = 'Erro ao adicionar lembrete: $e';
      notifyListeners();
    }
  }

  Future<void> updateReminder(ReminderModel updated) async {
    if (_uid == null) return;
    try {
      await _col.doc(updated.id).set(updated.toJson());
    } catch (e) {
      _error = 'Erro ao atualizar lembrete: $e';
      notifyListeners();
    }
  }

  Future<void> toggleDone(String id) async {
    if (_uid == null) return;
    try {
      final idx = _reminders.indexWhere((r) => r.id == id);
      if (idx == -1) return;
      await _col.doc(id).update({'isDone': !_reminders[idx].isDone});
    } catch (e) {
      _error = 'Erro ao marcar lembrete: $e';
      notifyListeners();
    }
  }

  Future<void> removeReminder(String id) async {
    if (_uid == null) return;
    try {
      await _col.doc(id).delete();
    } catch (e) {
      _error = 'Erro ao remover lembrete: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _remSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
