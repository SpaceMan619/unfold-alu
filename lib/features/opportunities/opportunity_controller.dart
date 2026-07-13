import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend/backend_config.dart';
import '../applications/application.dart';
import '../applications/application_review_controller.dart';
import '../auth/session_controller.dart';
import 'opportunity.dart';
import 'bookmark_repository.dart';
import 'opportunity_repository.dart';
import 'opportunity_seed_data.dart';

final opportunityRepositoryProvider = Provider<OpportunityRepository?>((ref) {
  if (!BackendConfig.usesFirebase || Firebase.apps.isEmpty) return null;
  return FirestoreOpportunityRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

final bookmarkRepositoryProvider = Provider<BookmarkRepository?>((ref) {
  if (!BackendConfig.usesFirebase || Firebase.apps.isEmpty) return null;
  return FirestoreBookmarkRepository(FirebaseFirestore.instance);
});

class OpportunityActivity {
  const OpportunityActivity({
    required this.opportunities,
    this.savedIds = const {},
    this.appliedIds = const {},
    this.applications = const [],
  });

  final List<Opportunity> opportunities;
  final Set<String> savedIds;
  final Set<String> appliedIds;
  final List<OpportunityApplication> applications;

  OpportunityActivity copyWith({
    List<Opportunity>? opportunities,
    Set<String>? savedIds,
    Set<String>? appliedIds,
    List<OpportunityApplication>? applications,
  }) {
    return OpportunityActivity(
      opportunities: opportunities ?? this.opportunities,
      savedIds: savedIds ?? this.savedIds,
      appliedIds: appliedIds ?? this.appliedIds,
      applications: applications ?? this.applications,
    );
  }
}

class OpportunityActivityController extends Notifier<OpportunityActivity> {
  StreamSubscription<List<OpportunityApplication>>? applicationSubscription;

  @override
  OpportunityActivity build() {
    final initial = OpportunityActivity(opportunities: _seedOpportunities);
    final repository = ref.watch(opportunityRepositoryProvider);
    if (repository != null) {
      final subscription = repository.watchActive().listen((opportunities) {
        state = state.copyWith(opportunities: _mergeWithSeeds(opportunities));
      });
      ref.onDispose(subscription.cancel);
    }
    final applicationRepository = ref.watch(applicationRepositoryProvider);
    final bookmarkRepository = ref.watch(bookmarkRepositoryProvider);
    if (bookmarkRepository != null) {
      final bookmarkSession = ref.watch(applicationSessionProvider);
      if (bookmarkSession.uid.isNotEmpty) {
        final bookmarkSubscription = bookmarkRepository
            .watch(bookmarkSession.uid)
            .listen((ids) => state = state.copyWith(savedIds: ids));
        ref.onDispose(bookmarkSubscription.cancel);
      }
    }
    if (applicationRepository == null) return initial;
    final session = ref.watch(applicationSessionProvider);
    if (session.role == AccountRole.student && session.uid.isNotEmpty) {
      applicationSubscription = applicationRepository
          .watchForStudent(session.uid)
          .listen((applications) {
            state = state.copyWith(
              applications: applications,
              appliedIds: applications
                  .map((application) => application.opportunityId)
                  .where((id) => id.isNotEmpty)
                  .toSet(),
            );
          });
      ref.onDispose(() => applicationSubscription?.cancel());
    }
    return initial;
  }

  List<Opportunity> get _seedOpportunities => sourcedVentureOpportunitySeeds
      .map((seed) => seed.opportunity)
      .toList(growable: false);

  List<Opportunity> _mergeWithSeeds(List<Opportunity> live) {
    final liveIds = live.map((item) => item.id).toSet();
    return [
      ...live,
      ..._seedOpportunities.where((item) => !liveIds.contains(item.id)),
    ];
  }

  Future<void> toggleSaved(String id) async {
    final next = {...state.savedIds};
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(savedIds: next);
    final repository = ref.read(bookmarkRepositoryProvider);
    if (repository == null) return;
    final session = ref.read(applicationSessionProvider);
    if (session.uid.isEmpty) return;
    try {
      await repository.setSaved(session.uid, id, next.contains(id));
    } catch (_) {
      final reverted = {...state.savedIds};
      reverted.contains(id) ? reverted.remove(id) : reverted.add(id);
      state = state.copyWith(savedIds: reverted);
      rethrow;
    }
  }

  Future<void> apply(Object value) async {
    final id = value is Opportunity ? value.id : value.toString();
    Opportunity? opportunity;
    if (value is Opportunity) {
      opportunity = value;
    } else {
      for (final item in state.opportunities) {
        if (item.id == id) opportunity = item;
      }
    }
    if (opportunity == null) return;
    await submitApplication(
      opportunity: opportunity,
      motivation:
          'I am excited to contribute to ${opportunity.startup} and grow through this opportunity.',
      availability: 'Flexible',
    );
  }

  Future<void> submitApplication({
    required Opportunity opportunity,
    required String motivation,
    required String availability,
    String portfolioUrl = '',
  }) async {
    final id = opportunity.id;
    final repository = ref.read(applicationRepositoryProvider);
    final session = ref.read(applicationSessionProvider);
    if (repository == null || session.uid.isEmpty) return;
    state = state.copyWith(appliedIds: {...state.appliedIds, id});
    final application = OpportunityApplication(
      id: '${session.uid}_$id',
      opportunityId: id,
      studentId: session.uid,
      founderId: opportunity.ownerId.isEmpty
          ? 'unfold-seed'
          : opportunity.ownerId,
      motivation: motivation.trim(),
      availability: availability.trim(),
      portfolioUrl: portfolioUrl.trim(),
      status: ApplicationStatus.submitted,
      createdAt: DateTime.now(),
      studentName: session.name.isEmpty ? 'ALU student' : session.name,
      studentEmail: session.email,
      roleTitle: opportunity.role,
      skills: opportunity.skills,
      location: 'ALU community',
    );
    try {
      await repository.submit(application);
      state = state.copyWith(
        applications: [
          ...state.applications.where((item) => item.opportunityId != id),
          application,
        ],
      );
    } catch (_) {
      final next = {...state.appliedIds}..remove(id);
      state = state.copyWith(appliedIds: next);
      rethrow;
    }
  }

  Future<void> addOpportunity(Opportunity opportunity) async {
    final repository = ref.read(opportunityRepositoryProvider);
    if (repository != null) {
      await repository.create(opportunity);
      return;
    }
    state = state.copyWith(
      opportunities: [opportunity, ...state.opportunities],
    );
  }

  Future<void> updateOpportunity(Opportunity opportunity) async {
    final repository = ref.read(opportunityRepositoryProvider);
    if (repository != null) {
      await repository.update(opportunity);
      return;
    }
    state = state.copyWith(
      opportunities: [
        for (final item in state.opportunities)
          if (item.id == opportunity.id) opportunity else item,
      ],
    );
  }

  Future<void> deleteOpportunity(String id) async {
    final repository = ref.read(opportunityRepositoryProvider);
    if (repository != null) await repository.delete(id);
    state = state.copyWith(
      opportunities: state.opportunities
          .where((item) => item.id != id)
          .toList(),
    );
  }

  Future<void> closeOpportunity(String id) async {
    final repository = ref.read(opportunityRepositoryProvider);
    if (repository != null) await repository.close(id);
    state = state.copyWith(
      opportunities: state.opportunities
          .where((item) => item.id != id)
          .toList(),
    );
  }
}

final opportunityActivityProvider =
    NotifierProvider<OpportunityActivityController, OpportunityActivity>(
      OpportunityActivityController.new,
    );
