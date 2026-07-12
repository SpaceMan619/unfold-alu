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
  Future<void> withdraw(String id) async {}
}

void main() {
  test('founder has no fabricated applications without a repository', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(applicationReviewProvider), isEmpty);
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
