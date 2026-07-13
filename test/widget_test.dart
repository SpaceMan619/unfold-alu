import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unfold/app/unfold_app.dart';
import 'package:unfold/features/applications/application_review_controller.dart';
import 'package:unfold/features/auth/session_controller.dart';

import 'support/fake_auth_repository.dart';

void main() {
  testWidgets('founder preview pipeline is reachable without live applicants', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          applicationRepositoryProvider.overrideWithValue(null),
          applicationSessionProvider.overrideWithValue(
            const SessionState(
              stage: SessionStage.authenticated,
              uid: 'preview-founder',
              role: AccountRole.student,
              name: 'Rajveer Jolly',
            ),
          ),
        ],
        child: const UnfoldApp(demoAuthenticated: true),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('nav-3')));
    await tester.pumpAndSettle();
    final switchButton = find.text('Switch to founder studio');
    await tester.ensureVisible(switchButton);
    await tester.tap(switchButton);
    await tester.pumpAndSettle();

    final previewButton = find.byKey(
      const ValueKey('review-preview-applicants'),
    );
    expect(find.text('Preview pipeline'), findsOneWidget);
    await tester.ensureVisible(previewButton);
    await tester.tap(previewButton);
    await tester.pumpAndSettle();
    expect(find.text('Imani Okafor'), findsOneWidget);
    expect(find.text('Tendai Moyo'), findsOneWidget);
    expect(find.text('Nadia Uwase'), findsOneWidget);
  });

  testWidgets('student can drag the nav thumb to another tab', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const UnfoldApp(demoAuthenticated: true),
      ),
    );

    final thumb = find.byKey(const ValueKey('nav-thumb'));
    final destination = find.byKey(const ValueKey('nav-2'));
    final start = tester.getCenter(thumb);
    final end = tester.getCenter(destination);
    await tester.dragFrom(start, Offset(end.dx - start.dx, 0));
    await tester.pumpAndSettle();

    expect(find.text('Applications'), findsOneWidget);
  });

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

  testWidgets('opportunity sheet shows the match breakdown and pinned apply', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(child: UnfoldApp(demoAuthenticated: true)),
    );

    final card = find.text('Flutter product intern');
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();

    // Demo profile has Flutter + Firebase of the role's three skills → 67%.
    expect(find.text('WHY YOU MATCH — 67%'), findsOneWidget);
    expect(find.text('PAY'), findsOneWidget);
    expect(find.text("WHAT YOU'LL BUILD"), findsOneWidget);
    expect(find.text('MORE LIKE THIS'), findsOneWidget);
    // Apply stays pinned at the bottom of the sheet.
    expect(find.text('Start application'), findsOneWidget);
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
