import 'dart:io' show File;
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:medicine_reminder_app/models/user_profile.dart';

/// Abstract interface for authentication services.
/// Implemented by [FirebaseAuthService] and [MockAuthService].
abstract class AuthService {
  Stream<UserProfile?> get onAuthStateChanged;
  UserProfile? get currentUser;

  Future<UserProfile?> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required int age,
  });

  Future<UserProfile?> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail({required String email});

  /// Sends a verification email to the currently signed-in user.
  Future<void> sendEmailVerification();

  /// Reloads the current Firebase user to refresh [emailVerified] status.
  Future<void> reloadUser();

  Future<void> signOut();
  Future<UserProfile?> updateProfile({required String name, required int age});

  /// Uploads [imageFile] (or [imageBytes] on web) to Firebase Storage and
  /// saves the resulting URL to Firestore + Firebase Auth photoURL.
  /// Returns the updated [UserProfile].
  Future<UserProfile?> updateProfilePhoto({
    File? imageFile,
    Uint8List? imageBytes,
    required String fileName,
  });
}
