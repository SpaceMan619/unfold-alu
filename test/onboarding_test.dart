import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unfold/app/unfold_app.dart';
import 'package:unfold/features/auth/session_controller.dart';
import 'package:unfold/features/home/home_shell.dart';

import 'support/fake_auth_repository.dart';

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

    expect(find.byType(HomeShell), findsOneWidget);
  });
}
