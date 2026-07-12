import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unfold/app/unfold_app.dart';
import 'package:unfold/features/auth/session_controller.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<UserProfile?> signInWithGoogle({AccountRole? role}) async => null;

  @override
  Future<UserProfile> saveGoogleProfile({required AccountRole role}) async {
    return UserProfile(
      uid: 'google-user',
      name: 'Rajveer Jolly',
      email: 'rajveer@alustudent.com',
      role: role,
    );
  }

  @override
  Stream<String?> authStateChanges() => Stream.value(null);

  @override
  Future<UserProfile?> profile(String uid) async => null;

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required AccountRole role,
  }) async {
    return UserProfile(uid: 'test-user', name: name, email: email, role: role);
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('student can complete demo onboarding', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const UnfoldApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('get-started')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I am a student'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'ALU email'),
      'rajveer@alustudent.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.tap(find.byKey(const ValueKey('complete-profile')));
    await tester.pumpAndSettle();

    expect(find.text('Good morning, Rajveer'), findsOneWidget);
  });
}
