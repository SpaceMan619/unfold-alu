import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unfold/features/applications/application.dart';
import 'package:unfold/features/applications/application_review_controller.dart';
import 'package:unfold/features/applications/application_repository.dart';
import 'package:unfold/features/auth/session_controller.dart';

class FakeApplicationRepository implements ApplicationRepository {
  final founderApplications = StreamController<List<OpportunityApplication>>();
  String? updatedId;
  ApplicationStatus? updatedStatus;
  List<OpportunityApplication> seeded = const [];

  @override
  Stream<List<OpportunityApplication>> watchForFounder(String founderId) =>
      founderApplications.stream;

  @override
  Stream<List<OpportunityApplication>> watchForStudent(String studentId) =>
      const Stream.empty();

  @override
  Future<void> updateStatus(String id, ApplicationStatus status) async {
    updatedId = id;
    updatedStatus = status;
  }

  @override
  Future<void> submit(OpportunityApplication application) async {}

  @override
  Future<void> seedFounderDemos(
    List<OpportunityApplication> applications,
  ) async => seeded = applications;

  @override
  Future<void> withdraw(String id) async {}
}

void main() {
  test('signed-out account has no preview applications', () {
    final container = ProviderContainer(
      overrides: [
        applicationRepositoryProvider.overrideWithValue(null),
        applicationSessionProvider.overrideWithValue(const SessionState()),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(applicationReviewProvider), isEmpty);
  });

  test(
    'authenticated account can manage the preview pipeline locally',
    () async {
      final container = ProviderContainer(
        overrides: [
          applicationRepositoryProvider.overrideWithValue(null),
          applicationSessionProvider.overrideWithValue(
            const SessionState(
              stage: SessionStage.authenticated,
              uid: 'preview-founder',
              role: AccountRole.student,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final previews = container.read(applicationReviewProvider);
      expect(previews, hasLength(3));
      expect(previews.every((item) => item.isPreview), isTrue);

      await container
          .read(applicationReviewProvider.notifier)
          .updateStatus(
            'demo-applicant-preview-founder-imani',
            ApplicationStatus.waitlisted,
          );

      expect(
        container
            .read(applicationReviewProvider)
            .firstWhere(
              (item) =>
                  item.application.id == 'demo-applicant-preview-founder-imani',
            )
            .application
            .status,
        ApplicationStatus.waitlisted,
      );
    },
  );

  test('empty founder pipeline seeds persistent demo records once', () async {
    final repository = FakeApplicationRepository();
    final container = ProviderContainer(
      overrides: [
        applicationRepositoryProvider.overrideWithValue(repository),
        applicationSessionProvider.overrideWithValue(
          const SessionState(
            stage: SessionStage.authenticated,
            uid: 'founder-seed',
            role: AccountRole.student,
          ),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await repository.founderApplications.close();
    });

    container.read(applicationReviewProvider);
    repository.founderApplications.add(const []);
    await Future<void>.delayed(Duration.zero);

    expect(repository.seeded, hasLength(3));
    expect(repository.seeded.every((item) => item.isDemo), isTrue);
    expect(
      repository.seeded.every((item) => item.founderId == 'founder-seed'),
      isTrue,
    );
  });

  test('founder watches and updates repository applications', () async {
    final repository = FakeApplicationRepository();
    final container = ProviderContainer(
      overrides: [
        applicationRepositoryProvider.overrideWithValue(repository),
        applicationSessionProvider.overrideWithValue(
          const SessionState(
            stage: SessionStage.authenticated,
            uid: 'founder-1',
            role: AccountRole.founder,
          ),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await repository.founderApplications.close();
    });

    container.read(applicationReviewProvider);
    repository.founderApplications.add([
      OpportunityApplication(
        id: 'live-1',
        opportunityId: 'role-1',
        studentId: 'student-1',
        founderId: 'founder-1',
        motivation: 'I want to help.',
        status: ApplicationStatus.submitted,
        createdAt: DateTime(2026, 7, 12),
        studentName: 'Amara',
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(applicationReviewProvider).single.studentName,
      'Amara',
    );
    await container
        .read(applicationReviewProvider.notifier)
        .updateStatus('live-1', ApplicationStatus.shortlisted);
    expect(repository.updatedId, 'live-1');
    expect(repository.updatedStatus, ApplicationStatus.shortlisted);
  });
}
