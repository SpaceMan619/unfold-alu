import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unfold/features/auth/session_controller.dart';

class MemoryAuthRepository implements AuthRepository {
  final authController = StreamController<String?>();
  UserProfile? savedProfile;
  bool signedOut = false;
  bool rejectGoogleDomain = false;
  String googleEmail = 'rajveer@alustudent.com';

  @override
  Future<UserProfile?> signInWithGoogle({AccountRole? role}) async {
    if (rejectGoogleDomain) throw const AluEmailRequiredException();
    if (role == null) return savedProfile;
    return saveGoogleProfile(role: role);
  }

  @override
  Future<UserProfile> saveGoogleProfile({required AccountRole role}) async {
    savedProfile = UserProfile(
      uid: 'google-user',
      name: 'Rajveer Jolly',
      email: googleEmail,
      role: role,
    );
    return savedProfile!;
  }

  @override
  Stream<String?> authStateChanges() => authController.stream;

  @override
  Future<UserProfile?> profile(String uid) async => savedProfile;

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required AccountRole role,
  }) async {
    savedProfile = UserProfile(
      uid: 'user-1',
      name: name,
      email: email,
      role: role,
    );
    return savedProfile!;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

void main() {
  test('registration saves the selected role and authenticates', () async {
    final repository = MemoryAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      container.dispose();
      await repository.authController.close();
    });

    final controller = container.read(sessionProvider.notifier);
    controller.begin();
    controller.chooseRole(AccountRole.founder);
    final success = await controller.register(
      name: 'Rajveer Jolly',
      email: 'rajveer@example.com',
      password: 'password123',
    );

    expect(success, isTrue);
    expect(container.read(sessionProvider).stage, SessionStage.authenticated);
    expect(container.read(sessionProvider).role, AccountRole.founder);
    expect(repository.savedProfile?.name, 'Rajveer Jolly');
  });

  test('an existing Firebase session restores its profile', () async {
    final repository = MemoryAuthRepository()
      ..savedProfile = const UserProfile(
        uid: 'user-1',
        name: 'Amara',
        email: 'amara@example.com',
        role: AccountRole.student,
      );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      container.dispose();
      await repository.authController.close();
    });
    container.read(sessionProvider);

    repository.authController.add('user-1');
    await Future<void>.delayed(Duration.zero);

    expect(container.read(sessionProvider).stage, SessionStage.authenticated);
    expect(container.read(sessionProvider).name, 'Amara');
  });

  test(
    'new Google user chooses a role before authentication completes',
    () async {
      final repository = MemoryAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(() async {
        container.dispose();
        await repository.authController.close();
      });

      final controller = container.read(sessionProvider.notifier);
      final signedIn = await controller.signInWithGoogle();

      expect(signedIn, isTrue);
      expect(container.read(sessionProvider).stage, SessionStage.chooseRole);
      expect(container.read(sessionProvider).awaitingGoogleRole, isTrue);

      await controller.completeGoogleProfile(AccountRole.student);

      expect(container.read(sessionProvider).stage, SessionStage.authenticated);
      expect(container.read(sessionProvider).role, AccountRole.student);
      expect(repository.savedProfile?.email, 'rajveer@alustudent.com');
    },
  );

  test('Google sign-in rejects accounts outside ALU domains', () async {
    final repository = MemoryAuthRepository()..rejectGoogleDomain = true;
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      container.dispose();
      await repository.authController.close();
    });

    final success = await container
        .read(sessionProvider.notifier)
        .signInWithGoogle();

    expect(success, isFalse);
    expect(container.read(sessionProvider).stage, SessionStage.signedOut);
    expect(container.read(sessionProvider).error, contains('@alustudent.com'));
  });
}
