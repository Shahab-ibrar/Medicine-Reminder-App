import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:medicine_reminder_app/models/user_profile.dart';
import 'package:medicine_reminder_app/services/service_locator.dart';

class AuthProvider with ChangeNotifier {
  UserProfile? _user;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<UserProfile?>? _authSubscription;

  AuthProvider() {
    _subscribeToAuthChanges();
  }

  UserProfile? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isFirebaseEnabled => locator.useFirebase;

  void _subscribeToAuthChanges() {
    _authSubscription?.cancel();
    _authSubscription = locator.authService.onAuthStateChanged.listen(
      (userProfile) {
        _user = userProfile;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> toggleServiceMode(bool useFirebase) async {
    _isLoading = true;
    notifyListeners();

    await signOut();
    await locator.setUseFirebase(useFirebase);
    _subscribeToAuthChanges();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required int age,
  }) async {
    _setLoading(true);
    try {
      _user = await locator.authService.registerWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
        age: age,
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      final error = e.toString().replaceAll('Exception: ', '');

      if (error.contains('email-already-in-use')) {
        _errorMessage = 'This email is already registered.';
      } else if (error.contains('invalid-email')) {
        _errorMessage = 'Please enter a valid email address.';
      } else if (error.contains('weak-password')) {
        _errorMessage =
            'Password is too weak. Use at least 8 characters with uppercase, lowercase, number, and special character.';
      } else if (error.contains('network-request-failed')) {
        _errorMessage = 'No internet connection.';
      } else {
        _errorMessage = error;
      }

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    try {
      _user = await locator.authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      final error = e.toString().replaceAll('Exception: ', '');

      if (error.contains('user-not-found')) {
        _errorMessage = 'No account found with this email.';
      } else if (error.contains('wrong-password') ||
          error.contains('invalid-credential')) {
        _errorMessage = 'Incorrect email or password.';
      } else if (error.contains('invalid-email')) {
        _errorMessage = 'Please enter a valid email address.';
      } else if (error.contains('network-request-failed')) {
        _errorMessage = 'No internet connection.';
      } else {
        _errorMessage = error;
      }

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordReset({required String email}) async {
    _setLoading(true);
    try {
      await locator.authService.sendPasswordResetEmail(email: email);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await locator.authService.signOut();
      _user = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({required String name, required int age}) async {
    if (_user == null) return false;
    _setLoading(true);
    try {
      final updated = await locator.authService.updateProfile(
        name: name,
        age: age,
      );
      if (updated != null) {
        _user = updated;
      }
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
