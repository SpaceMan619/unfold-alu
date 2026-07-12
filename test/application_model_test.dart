import 'package:flutter_test/flutter_test.dart';
import 'package:unfold/features/applications/application.dart';

void main() {
  test('application preserves form answers through firestore mapping', () {
    final createdAt = DateTime(2026, 7, 12);
    final application = OpportunityApplication(
      id: 'application-1',
      opportunityId: 'role-1',
      studentId: 'student-1',
      motivation: 'A detailed motivation.',
      availability: 'Within 2 weeks',
      portfolioUrl: 'https://example.com/work',
      status: ApplicationStatus.submitted,
      createdAt: createdAt,
    );

    final restored = OpportunityApplication.fromMap(
      application.id,
      application.toMap(),
    );

    expect(restored.motivation, application.motivation);
    expect(restored.availability, 'Within 2 weeks');
    expect(restored.portfolioUrl, 'https://example.com/work');
    expect(restored.createdAt, createdAt);
  });
}
