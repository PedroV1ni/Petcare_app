import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_model.dart';

class ReminderProvider with ChangeNotifier {
  List<ReminderModel> _reminders = [];
  bool _isLoading = false;
  String? _error;

  List<ReminderModel> get reminders => List.unmodifiable(_reminders);
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  // ----- Carregamento -----

  Future<void> loadReminders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('reminders');
      if (raw != null) {
        final List decoded = json.decode(raw);
        _reminders = decoded.map((e) => ReminderModel.fromJson(e)).toList();
      }
    } catch (e) {
      _error = 'Erro ao carregar lembretes: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ----- CRUD -----

  Future<void> addReminder(ReminderModel reminder) async {
    try {
      _reminders.add(reminder);
      await _persist();
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao adicionar lembrete: $e';
      notifyListeners();
    }
  }

  Future<void> updateReminder(ReminderModel updated) async {
    try {
      final idx = _reminders.indexWhere((r) => r.id == updated.id);
      if (idx != -1) {
        _reminders[idx] = updated;
        await _persist();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erro ao atualizar lembrete: $e';
      notifyListeners();
    }
  }

  Future<void> toggleDone(String id) async {
    try {
      final idx = _reminders.indexWhere((r) => r.id == id);
      if (idx != -1) {
        final r = _reminders[idx];
        _reminders[idx] = r.copyWith(isDone: !r.isDone);
        await _persist();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erro ao marcar lembrete: $e';
      notifyListeners();
    }
  }

  Future<void> removeReminder(String id) async {
    try {
      _reminders.removeWhere((r) => r.id == id);
      await _persist();
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao remover lembrete: $e';
      notifyListeners();
    }
  }

  // ----- Persistência -----

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_reminders.map((r) => r.toJson()).toList());
    await prefs.setString('reminders', encoded);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
