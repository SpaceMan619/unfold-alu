import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unfold/features/opportunities/opportunity.dart';
import 'package:unfold/features/opportunities/opportunity_controller.dart';
import 'package:unfold/features/opportunities/opportunity_repository.dart';

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

void main() {
  test('saved and applied IDs update independently', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(opportunityActivityProvider.notifier);

    controller.toggleSaved('mobile-dev');
    controller.apply('growth');

    final state = container.read(opportunityActivityProvider);
    expect(state.savedIds, {'mobile-dev'});
    expect(state.appliedIds, {'growth'});
  });

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
