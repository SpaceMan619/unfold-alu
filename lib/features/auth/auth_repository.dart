import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_models.dart';

abstract class AuthRepository {
  Stream<String?> authStateChanges();

  Future<UserProfile?> profile(String uid);

  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required AccountRole role,
  });

  Future<UserProfile?> signInWithGoogle({AccountRole? role}) {
    throw UnimplementedError();
  }

  Future<UserProfile> saveGoogleProfile({required AccountRole role}) {
    throw UnimplementedError();
  }

  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this.auth, this.firestore);

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  bool _isAluEmail(String email) {
    final normalized = email.trim().toLowerCase();
    return normalized.endsWith('@alustudent.com') ||
        normalized.endsWith('@alueducation.com');
  }

  @override
  Stream<String?> authStateChanges() {
    return auth.authStateChanges().map((user) => user?.uid);
  }

  @override
  Future<UserProfile?> profile(String uid) async {
    final snapshot = await firestore.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (data == null) return null;
    return UserProfile(
      uid: uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: (data['role'] as String?) == 'founder'
          ? AccountRole.founder
          : AccountRole.student,
    );
  }

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required AccountRole role,
  }) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(name);
    final profile = UserProfile(
      uid: user.uid,
      name: name,
      email: email,
      role: role,
    );
    await firestore.collection('users').doc(user.uid).set({
      'name': name,
      'email': email,
      'role': role.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return profile;
  }

  @override
  Future<UserProfile?> signInWithGoogle({AccountRole? role}) async {
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw PlatformException(code: 'sign_in_canceled');
    }
    if (!_isAluEmail(googleUser.email)) {
      await googleSignIn.signOut();
      throw const AluEmailRequiredException();
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-token',
        message: 'Google did not return a valid sign-in token.',
      );
    }
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: idToken,
    );
    final result = await auth.signInWithCredential(credential);
    final user = result.user!;
    final existing = await profile(user.uid);
    if (existing != null) return existing;
    if (role == null) return null;
    return _saveGoogleUser(user, role);
  }

  @override
  Future<UserProfile> saveGoogleProfile({required AccountRole role}) async {
    final user = auth.currentUser;
    if (user == null || user.email == null || !_isAluEmail(user.email!)) {
      await signOut();
      throw const AluEmailRequiredException();
    }
    return _saveGoogleUser(user, role);
  }

  Future<UserProfile> _saveGoogleUser(User user, AccountRole role) async {
    final value = UserProfile(
      uid: user.uid,
      name: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : user.email!.split('@').first,
      email: user.email!,
      role: role,
    );
    await firestore.collection('users').doc(user.uid).set({
      'name': value.name,
      'email': value.email,
      'role': role.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return value;
  }

  @override
  Future<void> signOut() async {
    await auth.signOut();
    await googleSignIn.signOut();
  }
}

class AluEmailRequiredException implements Exception {
  const AluEmailRequiredException();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});
