import 'package:medicine_reminder_app/models/user_profile.dart';

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
  Future<void> signOut();
  Future<UserProfile?> updateProfile({required String name, required int age});
}
