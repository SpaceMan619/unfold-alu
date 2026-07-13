import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unfold/app/unfold_theme.dart';
import 'package:unfold/features/applications/application_form_sheet.dart';
import 'package:unfold/features/opportunities/opportunity.dart';

const opportunity = Opportunity(
  id: 'role-1',
  role: 'Product design intern',
  startup: 'Test venture',
  summary: 'Design a useful product.',
  location: 'Kigali',
  commitment: 'Part-time',
  skills: ['Figma'],
  color: Color(0xff68ddc9),
);

Widget app(ApplicationSubmit onSubmit) {
  return MaterialApp(
    theme: UnfoldTheme.dark,
    home: Scaffold(
      body: ApplicationFormSheet(opportunity: opportunity, onSubmit: onSubmit),
    ),
  );
}

void main() {
  testWidgets('application form validates required answers', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      app(
        ({
          required motivation,
          required availability,
          required portfolioUrl,
        }) async {},
      ),
    );

    await tester.tap(find.byKey(const ValueKey('submit-application')));
    await tester.pump();

    expect(
      find.text('Tell the founder why you are interested.'),
      findsOneWidget,
    );
    expect(find.text('Choose when you can start.'), findsOneWidget);
  });

  testWidgets('application form submits complete answers', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    String? capturedMotivation;
    String? capturedAvailability;
    String? portfolio;
    await tester.pumpWidget(
      app(({
        required String motivation,
        required String availability,
        required String portfolioUrl,
      }) async {
        capturedMotivation = motivation;
        capturedAvailability = availability;
        portfolio = portfolioUrl;
      }),
    );

    const answer =
        'I led a student design project and would bring careful research, rapid prototyping, and strong collaboration to this role.';
    await tester.enterText(
      find.byKey(const ValueKey('motivation-field')),
      answer,
    );
    await tester.tap(find.byKey(const ValueKey('availability-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Immediately').last);
    await tester.enterText(
      find.byKey(const ValueKey('portfolio-field')),
      'https://example.com/work',
    );
    await tester.tap(find.byKey(const ValueKey('submit-application')));
    await tester.pumpAndSettle();

    expect(capturedMotivation, answer);
    expect(capturedAvailability, 'Immediately');
    expect(portfolio, 'https://example.com/work');
  });
}
