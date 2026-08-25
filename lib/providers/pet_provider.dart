import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet_model.dart';

class PetProvider with ChangeNotifier {
  List<PetModel> _pets = [];
  bool _isLoading = false;
  String? _error;

  List<PetModel> get pets => List.unmodifiable(_pets);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ----- Carregamento -----

  Future<void> loadPets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pets');
      if (raw != null) {
        final List decoded = json.decode(raw);
        _pets = decoded.map((e) => PetModel.fromJson(e)).toList();
      }
    } catch (e) {
      _error = 'Erro ao carregar pets: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ----- CRUD -----

  Future<void> addPet(PetModel pet) async {
    try {
      _pets.add(pet);
      await _persist();
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao adicionar pet: $e';
      notifyListeners();
    }
  }

  Future<void> updatePet(PetModel updated) async {
    try {
      final idx = _pets.indexWhere((p) => p.id == updated.id);
      if (idx != -1) {
        _pets[idx] = updated;
        await _persist();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erro ao atualizar pet: $e';
      notifyListeners();
    }
  }

  Future<void> removePet(String id) async {
    try {
      _pets.removeWhere((p) => p.id == id);
      await _persist();
      notifyListeners();
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

  /// Retorna 0.0–1.0 com base nos lembretes concluídos hoje.
  /// Recebe a lista de lembretes para não criar dependência circular.
  double activityProgress(List completedTodayReminders, List allTodayReminders) {
    if (allTodayReminders.isEmpty) return 0.0;
    return (completedTodayReminders.length / allTodayReminders.length).clamp(0.0, 1.0);
  }

  // ----- Persistência -----

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_pets.map((p) => p.toJson()).toList());
    await prefs.setString('pets', encoded);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
