import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medicine_reminder_app/models/user_profile.dart';
import 'package:medicine_reminder_app/services/auth_service.dart';

class MockAuthService implements AuthService {
  final StreamController<UserProfile?> _authController = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentUser;
  
  static const String _prefUserKey = 'mock_current_user';
  static const String _prefUsersListKey = 'mock_registered_users';

  MockAuthService() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_prefUserKey);
      if (userJson != null) {
        final Map<String, dynamic> data = json.decode(userJson);
        final uid = data['uid'] ?? 'mock-uid';
        _currentUser = UserProfile.fromJson(data, uid);
        _authController.add(_currentUser);
        debugPrint('MockAuthService: Loaded session for user ${_currentUser?.email}');
      } else {
        _authController.add(null);
      }
    } catch (e) {
      debugPrint('MockAuthService load session error: $e');
      _authController.add(null);
    }
  }

  @override
  Stream<UserProfile?> get onAuthStateChanged => _authController.stream;

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  Future<UserProfile?> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required int age,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_prefUsersListKey) ?? '{}';
    final Map<String, dynamic> users = json.decode(usersJson);

    if (users.containsKey(email.toLowerCase())) {
      throw Exception('Email already registered.');
    }

    final uid = 'mock-uid-${DateTime.now().millisecondsSinceEpoch}';
    final profile = UserProfile(
      uid: uid,
      name: name,
      email: email.toLowerCase(),
      age: age,
      createdAt: DateTime.now(),
    );

    users[email.toLowerCase()] = {
      'uid': uid,
      'password': password,
      'name': name,
      'email': email.toLowerCase(),
      'age': age,
      'createdAt': profile.createdAt.toIso8601String(),
    };
    await prefs.setString(_prefUsersListKey, json.encode(users));

    _currentUser = profile;
    await prefs.setString(_prefUserKey, json.encode(profile.toJson()..['uid'] = uid));
    _authController.add(_currentUser);

    return _currentUser;
  }

  @override
  Future<UserProfile?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_prefUsersListKey) ?? '{}';
    final Map<String, dynamic> users = json.decode(usersJson);

    final normalizedEmail = email.toLowerCase();
    if (!users.containsKey(normalizedEmail) || users[normalizedEmail]['password'] != password) {
      throw Exception('Invalid email or password.');
    }

    final userData = users[normalizedEmail];
    final uid = userData['uid'];
    _currentUser = UserProfile.fromJson(userData, uid);
    
    await prefs.setString(_prefUserKey, json.encode(_currentUser!.toJson()..['uid'] = uid));
    _authController.add(_currentUser);

    return _currentUser;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_prefUsersListKey) ?? '{}';
    final Map<String, dynamic> users = json.decode(usersJson);

    if (!users.containsKey(email.toLowerCase())) {
      throw Exception('User with this email does not exist.');
    }
    debugPrint('MockAuthService: Password reset email sent to $email');
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefUserKey);
    _currentUser = null;
    _authController.add(null);
    debugPrint('MockAuthService: User signed out');
  }

  @override
  Future<UserProfile?> updateProfile({required String name, required int age}) async {
    if (_currentUser == null) throw Exception('No user signed in.');

    await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();

    final updated = UserProfile(
      uid: _currentUser!.uid,
      name: name,
      email: _currentUser!.email,
      age: age,
      createdAt: _currentUser!.createdAt,
    );

    _currentUser = updated;
    await prefs.setString(_prefUserKey, json.encode(updated.toJson()..['uid'] = updated.uid));

    final usersJson = prefs.getString(_prefUsersListKey) ?? '{}';
    final Map<String, dynamic> users = json.decode(usersJson);
    if (users.containsKey(updated.email)) {
      final userData = users[updated.email];
      userData['name'] = name;
      userData['age'] = age;
      users[updated.email] = userData;
      await prefs.setString(_prefUsersListKey, json.encode(users));
    }

    _authController.add(_currentUser);
    return _currentUser;
  }
}
