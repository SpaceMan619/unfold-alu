import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend/backend_config.dart';
import '../applications/application_review_controller.dart';
import 'startup_repository.dart';

final startupRepositoryProvider = Provider<StartupRepository?>((ref) {
  if (!BackendConfig.usesFirebase || Firebase.apps.isEmpty) return null;
  return FirestoreStartupRepository(FirebaseFirestore.instance);
});

class StartupState {
  const StartupState({this.profile, this.loading = false, this.error});
  final StartupProfile? profile;
  final bool loading;
  final String? error;
}

class StartupController extends Notifier<StartupState> {
  @override
  StartupState build() {
    final repository = ref.watch(startupRepositoryProvider);
    final session = ref.watch(applicationSessionProvider);
    if (repository == null) {
      return const StartupState(
        profile: StartupProfile(
          id: 'demo-startup',
          ownerId: 'demo-founder',
          name: 'Soma Labs',
          summary: 'Learning technology for low-bandwidth classrooms.',
          verificationStatus: VerificationStatus.verified,
        ),
      );
    }
    if (session.uid.isEmpty) return const StartupState();
    final subscription = repository
        .watchForOwner(session.uid)
        .listen(
          (profile) => state = StartupState(profile: profile),
          onError: (Object error) =>
              state = StartupState(error: error.toString()),
        );
    ref.onDispose(subscription.cancel);
    return const StartupState(loading: true);
  }

  Future<void> submit(String name, String summary) async {
    final repository = ref.read(startupRepositoryProvider);
    final session = ref.read(applicationSessionProvider);
    if (repository == null || session.uid.isEmpty) return;
    await repository.submit(ownerId: session.uid, name: name, summary: summary);
  }
}

final startupProvider = NotifierProvider<StartupController, StartupState>(
  StartupController.new,
);
