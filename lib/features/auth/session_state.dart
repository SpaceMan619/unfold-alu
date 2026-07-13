import 'auth_models.dart';

enum SessionStage { loading, signedOut, chooseRole, onboarding, authenticated }

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
