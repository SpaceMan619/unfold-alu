import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unfold/features/opportunities/opportunity.dart';
import 'package:unfold/features/opportunities/opportunity_controller.dart';
import 'package:unfold/features/opportunities/opportunity_repository.dart';
import 'package:unfold/features/applications/application.dart';
import 'package:unfold/features/applications/application_repository.dart';
import 'package:unfold/features/applications/application_review_controller.dart';
import 'package:unfold/features/auth/session_controller.dart';

class FakeOpportunityRepository implements OpportunityRepository {
  final stream = StreamController<List<Opportunity>>();
  Opportunity? created;

  @override
  Future<void> create(Opportunity opportunity) async => created = opportunity;

  @override
  Future<void> close(String id) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> update(Opportunity opportunity) async {}

  @override
  Stream<List<Opportunity>> watchActive() => stream.stream;
}

class FakeApplicationRepository implements ApplicationRepository {
  final studentApplications =
      StreamController<List<OpportunityApplication>>.broadcast();
  final watchedStudentIds = <String>[];
  OpportunityApplication? submitted;

  @override
  Stream<List<OpportunityApplication>> watchForStudent(String studentId) {
    watchedStudentIds.add(studentId);
    return studentApplications.stream;
  }

  @override
  Stream<List<OpportunityApplication>> watchForFounder(String founderId) =>
      const Stream.empty();

  @override
  Future<void> submit(OpportunityApplication application) async {
    submitted = application;
  }

  @override
  Future<void> updateStatus(String id, ApplicationStatus status) async {}

  @override
  Future<void> withdraw(String id) async {}
}

void main() {
  test('saved IDs do not fabricate an application without persistence', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(opportunityActivityProvider.notifier);

    controller.toggleSaved('mobile-dev');
    controller.apply('growth');

    final state = container.read(opportunityActivityProvider);
    expect(state.savedIds, {'mobile-dev'});
    expect(state.appliedIds, isEmpty);
  });

  test(
    'submitted state is scoped to the signed-in student and opportunity',
    () async {
      final repository = FakeApplicationRepository();
      final container = ProviderContainer(
        overrides: [
          applicationRepositoryProvider.overrideWithValue(repository),
          applicationSessionProvider.overrideWithValue(
            const SessionState(
              stage: SessionStage.authenticated,
              uid: 'student-a',
              name: 'Student A',
              email: 'a@alustudent.com',
              role: AccountRole.student,
            ),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await repository.studentApplications.close();
      });

      container.read(opportunityActivityProvider);
      expect(repository.watchedStudentIds, ['student-a']);
      repository.studentApplications.add([
        OpportunityApplication(
          id: 'student-a_role-1',
          opportunityId: 'role-1',
          studentId: 'student-a',
          motivation: 'Relevant experience',
          status: ApplicationStatus.submitted,
          createdAt: DateTime(2026, 7, 13),
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(opportunityActivityProvider).appliedIds, {
        'role-1',
      });
      expect(
        container
            .read(opportunityActivityProvider)
            .appliedIds
            .contains('role-2'),
        isFalse,
      );
    },
  );

  test(
    'live opportunities replace seeds and publishing uses repository',
    () async {
      final repository = FakeOpportunityRepository();
      final container = ProviderContainer(
        overrides: [
          opportunityRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await repository.stream.close();
      });

      final controller = container.read(opportunityActivityProvider.notifier);
      const live = Opportunity(
        id: 'live-role',
        role: 'Product fellow',
        startup: 'Test venture',
        summary: 'Shape an early product.',
        location: 'Remote',
        commitment: 'Flexible',
        skills: ['Research'],
        match: 0,
        color: Color(0xff68ddc9),
      );
      repository.stream.add(const [live]);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(opportunityActivityProvider).opportunities, [live]);
      await controller.addOpportunity(live);
      expect(repository.created, live);
    },
  );
}
