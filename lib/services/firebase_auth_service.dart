import 'dart:io' show File;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:medicine_reminder_app/models/user_profile.dart';
import 'package:medicine_reminder_app/services/auth_service.dart';

class FirebaseAuthService implements AuthService {
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ─── Auth state stream ───────────────────────────────────────────────────────

  @override
  Stream<UserProfile?> get onAuthStateChanged {
    return _firebaseAuth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      try {
        final doc =
            await _firestore.collection('users').doc(fbUser.uid).get();
        if (doc.exists && doc.data() != null) {
          return UserProfile.fromJson(doc.data()!, fbUser.uid);
        }
        return UserProfile(
          uid: fbUser.uid,
          name: fbUser.displayName ?? 'User',
          email: fbUser.email ?? '',
          age: 0,
          createdAt: DateTime.now(),
          photoUrl: fbUser.photoURL,
        );
      } catch (e) {
        debugPrint('FirebaseAuthService: error mapping auth state: $e');
        return UserProfile(
          uid: fbUser.uid,
          name: fbUser.displayName ?? 'User',
          email: fbUser.email ?? '',
          age: 0,
          createdAt: DateTime.now(),
          photoUrl: fbUser.photoURL,
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
      photoUrl: fbUser.photoURL,
    );
  }

  // ─── Registration ────────────────────────────────────────────────────────────

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

    // Send email verification after account creation
    await fbUser.sendEmailVerification();

    final profile = UserProfile(
      uid: fbUser.uid,
      name: name,
      email: email.toLowerCase(),
      age: age,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(fbUser.uid)
        .set(profile.toJson());

    return profile;
  }

  // ─── Sign in ─────────────────────────────────────────────────────────────────

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

    // Block login if email is not verified
    if (!fbUser.emailVerified) {
      await _firebaseAuth.signOut(); // sign out immediately so auth state stays null
      throw Exception('email-not-verified');
    }

    final doc =
        await _firestore.collection('users').doc(fbUser.uid).get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromJson(doc.data()!, fbUser.uid);
    }

    return UserProfile(
      uid: fbUser.uid,
      name: fbUser.displayName ?? 'User',
      email: fbUser.email ?? '',
      age: 0,
      createdAt: DateTime.now(),
      photoUrl: fbUser.photoURL,
    );
  }

  // ─── Password reset ──────────────────────────────────────────────────────────

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  // ─── Email verification ──────────────────────────────────────────────────────

  @override
  Future<void> sendEmailVerification() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser != null && !fbUser.emailVerified) {
      await fbUser.sendEmailVerification();
    }
  }

  @override
  Future<void> reloadUser() async {
    await _firebaseAuth.currentUser?.reload();
  }

  // ─── Sign out ────────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // ─── Update profile text ─────────────────────────────────────────────────────

  @override
  Future<UserProfile?> updateProfile({
    required String name,
    required int age,
  }) async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) throw Exception('No user is currently signed in.');

    await fbUser.updateDisplayName(name);

    final docRef = _firestore.collection('users').doc(fbUser.uid);
    final doc = await docRef.get();

    DateTime createdAt = DateTime.now();
    String? existingPhotoUrl;
    if (doc.exists && doc.data() != null) {
      final oldProfile = UserProfile.fromJson(doc.data()!, fbUser.uid);
      createdAt = oldProfile.createdAt;
      existingPhotoUrl = oldProfile.photoUrl;
    }

    final updatedProfile = UserProfile(
      uid: fbUser.uid,
      name: name,
      email: fbUser.email ?? '',
      age: age,
      createdAt: createdAt,
      photoUrl: existingPhotoUrl,
    );

    await docRef.set(updatedProfile.toJson(), SetOptions(merge: true));
    return updatedProfile;
  }

  // ─── Update profile photo ────────────────────────────────────────────────────

  @override
  Future<UserProfile?> updateProfilePhoto({
    File? imageFile,
    Uint8List? imageBytes,
    required String fileName,
  }) async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) throw Exception('No user is currently signed in.');

    final storageRef = _storage
        .ref()
        .child('profile_photos')
        .child(fbUser.uid)
        .child(fileName);

    // Upload: use putFile on mobile, putData on web
    UploadTask uploadTask;
    if (kIsWeb && imageBytes != null) {
      uploadTask = storageRef.putData(imageBytes);
    } else if (imageFile != null) {
      uploadTask = storageRef.putFile(imageFile);
    } else {
      throw Exception('No image data provided.');
    }

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    // Update Firebase Auth photoURL
    await fbUser.updatePhotoURL(downloadUrl);

    // Update Firestore user document
    await _firestore
        .collection('users')
        .doc(fbUser.uid)
        .update({'photoUrl': downloadUrl});

    // Build updated profile to return
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
      photoUrl: downloadUrl,
    );
  }
}
