import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unfold/app/unfold_app.dart';
import 'package:unfold/features/auth/session_controller.dart';

import 'support/fake_auth_repository.dart';

void main() {
  testWidgets('student can open every primary tab', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const UnfoldApp(demoAuthenticated: true),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('nav-1')));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-2')));
    await tester.pumpAndSettle();
    expect(find.text('Applications'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-3')));
    await tester.pumpAndSettle();
    expect(find.text('Profile details'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-0')));
    await tester.pumpAndSettle();
    expect(find.text('Your next chapter\nis ready to unfold.'), findsOneWidget);
  });

  testWidgets('student can save and view an opportunity', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: UnfoldApp(demoAuthenticated: true)),
    );

    expect(find.text('Your next chapter\nis ready to unfold.'), findsOneWidget);

    final saveButton = find.byKey(const ValueKey('save-demo-kayko-flutter'));
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-1')));
    await tester.pumpAndSettle();

    expect(find.text('Flutter product intern'), findsOneWidget);

    final removeButton = find.byKey(const ValueKey('save-demo-kayko-flutter'));
    await tester.ensureVisible(removeButton);
    await tester.tap(removeButton);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Flutter product intern'), findsNothing);
    expect(
      find.text('Save an opportunity and it will wait for you here.'),
      findsOneWidget,
    );
  });
}
