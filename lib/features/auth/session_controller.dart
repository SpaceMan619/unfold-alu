import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'auth_models.dart';
import 'auth_repository.dart';
import 'session_state.dart';

export 'auth_models.dart';
export 'auth_repository.dart';
export 'session_state.dart';

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
