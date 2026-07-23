import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medicine_reminder_app/services/auth_service.dart';
import 'package:medicine_reminder_app/services/database_service.dart';
import 'package:medicine_reminder_app/services/firebase_auth_service.dart';
import 'package:medicine_reminder_app/services/firestore_service.dart';
import 'package:medicine_reminder_app/services/mock_auth_service.dart';
import 'package:medicine_reminder_app/services/mock_database_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  static const String _prefUseFirebaseKey = 'use_firebase_services';

  bool _useFirebase = true;
  bool get useFirebase => _useFirebase;

  late AuthService _authService;
  late DatabaseService _databaseService;

  AuthService get authService => _authService;
  DatabaseService get databaseService => _databaseService;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _useFirebase = prefs.getBool(_prefUseFirebaseKey) ?? false;
    } catch (e) {
      _useFirebase = false;
    }
    _setupServices();
  }

  void _setupServices() {
    if (_useFirebase) {
      try {
        _authService = FirebaseAuthService();
        _databaseService = FirestoreDatabaseService();
        debugPrint('ServiceLocator: Firebase services initialized');
      } catch (e) {
        debugPrint(
          'ServiceLocator: Failed to initialize Firebase services. Falling back to Mock: $e',
        );
        _useFirebase = false;
        _authService = MockAuthService();
        _databaseService = MockDatabaseService();
      }
    } else {
      _useFirebase = false;
      _authService = MockAuthService();
      _databaseService = MockDatabaseService();
      debugPrint('ServiceLocator: Mock services initialized');
    }
  }

  Future<void> setUseFirebase(bool value) async {
    _useFirebase = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefUseFirebaseKey, value);
    } catch (e) {
      debugPrint('ServiceLocator failed to save useFirebase: $e');
    }
    _setupServices();
  }
}

final locator = ServiceLocator();
