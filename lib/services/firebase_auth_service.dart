import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:medicine_reminder_app/models/user_profile.dart';
import 'package:medicine_reminder_app/services/auth_service.dart';

class FirebaseAuthService implements AuthService {
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<UserProfile?> get onAuthStateChanged {
    return _firebaseAuth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      try {
        final doc = await _firestore.collection('users').doc(fbUser.uid).get();
        if (doc.exists && doc.data() != null) {
          return UserProfile.fromJson(doc.data()!, fbUser.uid);
        }
        return UserProfile(
          uid: fbUser.uid,
          name: fbUser.displayName ?? 'User',
          email: fbUser.email ?? '',
          age: 0,
          createdAt: DateTime.now(),
        );
      } catch (e) {
        debugPrint('FirebaseAuthService: error mapping auth state: $e');
        return UserProfile(
          uid: fbUser.uid,
          name: fbUser.displayName ?? 'User',
          email: fbUser.email ?? '',
          age: 0,
          createdAt: DateTime.now(),
        );
      }
    });
  }

  @override
  UserProfile? get currentUser {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return null;
    return UserProfile(
      uid: fbUser.uid,
      name: fbUser.displayName ?? 'User',
      email: fbUser.email ?? '',
      age: 0,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<UserProfile?> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required int age,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final fbUser = credential.user;
    if (fbUser == null) throw Exception('Registration failed - User is null.');

    await fbUser.updateDisplayName(name);

    final profile = UserProfile(
      uid: fbUser.uid,
      name: name,
      email: email.toLowerCase(),
      age: age,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(fbUser.uid).set(profile.toJson());

    return profile;
  }

  @override
  Future<UserProfile?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final fbUser = credential.user;
    if (fbUser == null) throw Exception('Login failed.');

    final doc = await _firestore.collection('users').doc(fbUser.uid).get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromJson(doc.data()!, fbUser.uid);
    }

    return UserProfile(
      uid: fbUser.uid,
      name: fbUser.displayName ?? 'User',
      email: fbUser.email ?? '',
      age: 0,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<UserProfile?> updateProfile({required String name, required int age}) async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) throw Exception('No user is currently signed in.');

    await fbUser.updateDisplayName(name);

    final docRef = _firestore.collection('users').doc(fbUser.uid);
    final doc = await docRef.get();
    
    DateTime createdAt = DateTime.now();
    if (doc.exists && doc.data() != null) {
      final oldProfile = UserProfile.fromJson(doc.data()!, fbUser.uid);
      createdAt = oldProfile.createdAt;
    }

    final updatedProfile = UserProfile(
      uid: fbUser.uid,
      name: name,
      email: fbUser.email ?? '',
      age: age,
      createdAt: createdAt,
    );

    await docRef.set(updatedProfile.toJson(), SetOptions(merge: true));
    return updatedProfile;
  }
}
