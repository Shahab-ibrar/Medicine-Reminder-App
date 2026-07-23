import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medicine_reminder_app/models/medicine.dart';
import 'package:medicine_reminder_app/services/database_service.dart';

class MockDatabaseService implements DatabaseService {
  static const String _prefMedicinesKey = 'mock_medicines';
  final StreamController<List<Medicine>> _medicinesController = StreamController<List<Medicine>>.broadcast();
  List<Medicine> _localMedicines = [];
  String? _currentUserId;

  MockDatabaseService() {
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final medicinesJson = prefs.getString(_prefMedicinesKey);
      if (medicinesJson != null) {
        final List<dynamic> list = json.decode(medicinesJson);
        _localMedicines = list.map((item) => Medicine.fromJson(item, item['id'] ?? '')).toList();
      }
      _notify();
    } catch (e) {
      debugPrint('MockDatabaseService load error: $e');
    }
  }

  Future<void> _saveMedicines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _localMedicines.map((m) => m.toJson()..['id'] = m.id).toList();
      await prefs.setString(_prefMedicinesKey, json.encode(list));
      _notify();
    } catch (e) {
      debugPrint('MockDatabaseService save error: $e');
    }
  }

  void _notify() {
    if (_currentUserId != null) {
      final filtered = _localMedicines.where((m) => m.userId == _currentUserId).toList();
      _medicinesController.add(filtered);
    }
  }

  @override
  Stream<List<Medicine>> watchMedicines(String userId) {
    _currentUserId = userId;
    Future.microtask(() => _notify());
    return _medicinesController.stream;
  }

  @override
  Future<List<Medicine>> getMedicines(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUserId = userId;
    return _localMedicines.where((m) => m.userId == userId).toList();
  }

  @override
  Future<Medicine> addMedicine(Medicine medicine) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final id = medicine.id.isEmpty 
        ? 'mock-med-${DateTime.now().millisecondsSinceEpoch}-${medicine.hashCode}' 
        : medicine.id;
    final newMedicine = medicine.copyWith(id: id);
    
    _localMedicines.add(newMedicine);
    await _saveMedicines();
    return newMedicine;
  }

  @override
  Future<void> updateMedicine(Medicine medicine) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _localMedicines.indexWhere((m) => m.id == medicine.id);
    if (idx != -1) {
      _localMedicines[idx] = medicine;
      await _saveMedicines();
    }
  }

  @override
  Future<void> deleteMedicine(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _localMedicines.removeWhere((m) => m.id == id);
    await _saveMedicines();
  }
}
