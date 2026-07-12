import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AccountRole { student, founder }

enum SessionStage { loading, signedOut, chooseRole, onboarding, authenticated }

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  final String uid;
  final String name;
  final String email;
  final AccountRole role;
}

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

class SessionState {
  const SessionState({
    this.stage = SessionStage.loading,
    this.role,
    this.uid = '',
    this.name = '',
    this.email = '',
    this.isSubmitting = false,
    this.awaitingGoogleRole = false,
    this.error,
  });

  final SessionStage stage;
  final AccountRole? role;
  final String uid;
  final String name;
  final String email;
  final bool isSubmitting;
  final bool awaitingGoogleRole;
  final String? error;

  SessionState copyWith({
    SessionStage? stage,
    AccountRole? role,
    String? uid,
    String? name,
    String? email,
    bool? isSubmitting,
    bool? awaitingGoogleRole,
    String? error,
    bool clearError = false,
  }) {
    return SessionState(
      stage: stage ?? this.stage,
      role: role ?? this.role,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      awaitingGoogleRole: awaitingGoogleRole ?? this.awaitingGoogleRole,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class SessionController extends Notifier<SessionState> {
  StreamSubscription<String?>? subscription;
  bool isRegistering = false;

  @override
  SessionState build() {
    final repository = ref.watch(authRepositoryProvider);
    subscription = repository.authStateChanges().listen(_restoreSession);
    ref.onDispose(() => subscription?.cancel());
    return const SessionState();
  }

  Future<void> _restoreSession(String? uid) async {
    if (isRegistering) return;
    if (uid == null) {
      state = const SessionState(stage: SessionStage.signedOut);
      return;
    }
    try {
      final profile = await ref.read(authRepositoryProvider).profile(uid);
      state = profile == null
          ? const SessionState(stage: SessionStage.chooseRole)
          : _authenticated(profile);
    } catch (_) {
      state = const SessionState(
        stage: SessionStage.signedOut,
        error: 'We could not restore your account. Please try again.',
      );
    }
  }

  SessionState _authenticated(UserProfile profile) {
    return SessionState(
      stage: SessionStage.authenticated,
      uid: profile.uid,
      role: profile.role,
      name: profile.name,
      email: profile.email,
    );
  }

  void begin() =>
      state = state.copyWith(stage: SessionStage.chooseRole, clearError: true);

  void chooseRole(AccountRole role) {
    state = state.copyWith(
      stage: SessionStage.onboarding,
      role: role,
      clearError: true,
    );
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final role = state.role;
    if (role == null) return false;
    isRegistering = true;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final profile = await ref
          .read(authRepositoryProvider)
          .register(name: name, email: email, password: password, role: role);
      state = _authenticated(profile);
      return true;
    } on FirebaseAuthException catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        error: switch (error.code) {
          'email-already-in-use' => 'An account already uses this email.',
          'invalid-email' => 'Enter a valid email address.',
          'weak-password' => 'Use a password with at least 6 characters.',
          _ => error.message ?? 'Account creation failed. Please try again.',
        },
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Account creation failed. Check your connection and try again.',
      );
      return false;
    } finally {
      isRegistering = false;
    }
  }

  Future<bool> signInWithGoogle() async {
    isRegistering = true;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final profile = await ref
          .read(authRepositoryProvider)
          .signInWithGoogle(role: state.role);
      if (profile != null) {
        state = _authenticated(profile);
      } else {
        state = state.copyWith(
          stage: SessionStage.chooseRole,
          isSubmitting: false,
          awaitingGoogleRole: true,
          clearError: true,
        );
      }
      return true;
    } on AluEmailRequiredException {
      state = const SessionState(
        stage: SessionStage.signedOut,
        error: 'Sign in with an @alustudent.com or @alueducation.com account.',
      );
      return false;
    } on PlatformException catch (error) {
      if (error.code == 'sign_in_canceled') {
        state = state.copyWith(isSubmitting: false, clearError: true);
      } else {
        state = state.copyWith(
          isSubmitting: false,
          error: 'Google sign-in failed. Please try again.',
        );
      }
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Google sign-in failed. Check your connection and try again.',
      );
      return false;
    } finally {
      isRegistering = false;
    }
  }

  Future<bool> completeGoogleProfile(AccountRole role) async {
    isRegistering = true;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final profile = await ref
          .read(authRepositoryProvider)
          .saveGoogleProfile(role: role);
      state = _authenticated(profile);
      return true;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'We could not finish your profile. Please try again.',
      );
      return false;
    } finally {
      isRegistering = false;
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const SessionState(stage: SessionStage.signedOut);
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);
