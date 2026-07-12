import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend/backend_config.dart';
import '../auth/session_controller.dart';
import 'application.dart';
import 'application_repository.dart';

final applicationRepositoryProvider = Provider<ApplicationRepository?>((ref) {
  if (!BackendConfig.usesFirebase || Firebase.apps.isEmpty) return null;
  return FirestoreApplicationRepository(FirebaseFirestore.instance);
});

final applicationSessionProvider = Provider<SessionState>(
  (ref) => ref.watch(sessionProvider),
);

class FounderApplication {
  const FounderApplication({
    required this.application,
    required this.studentName,
    required this.roleTitle,
    required this.skills,
    required this.location,
  });

  final OpportunityApplication application;
  final String studentName;
  final String roleTitle;
  final List<String> skills;
  final String location;

  FounderApplication copyWith({OpportunityApplication? application}) {
    return FounderApplication(
      application: application ?? this.application,
      studentName: studentName,
      roleTitle: roleTitle,
      skills: skills,
      location: location,
    );
  }
}

final demoFounderApplications = [
  FounderApplication(
    application: OpportunityApplication(
      id: 'application-amara',
      opportunityId: 'mobile-dev',
      studentId: 'student-amara',
      motivation:
          'I want to help build accessible learning tools and deepen my Flutter experience.',
      status: ApplicationStatus.submitted,
      createdAt: DateTime(2026, 7, 11),
    ),
    studentName: 'Amara Okafor',
    roleTitle: 'Mobile developer intern',
    skills: ['Flutter', 'Firebase', 'Figma'],
    location: 'Kigali, Rwanda',
  ),
  FounderApplication(
    application: OpportunityApplication(
      id: 'application-kwame',
      opportunityId: 'mobile-dev',
      studentId: 'student-kwame',
      motivation:
          'My recent campus project taught me how to turn user feedback into simple product improvements.',
      status: ApplicationStatus.reviewing,
      createdAt: DateTime(2026, 7, 10),
    ),
    studentName: 'Kwame Mensah',
    roleTitle: 'Mobile developer intern',
    skills: ['Dart', 'Research', 'Product thinking'],
    location: 'Accra, Ghana',
  ),
  FounderApplication(
    application: OpportunityApplication(
      id: 'application-zuri',
      opportunityId: 'mobile-dev',
      studentId: 'student-zuri',
      motivation:
          'Soma Labs aligns with my mission to make education more inclusive across Africa.',
      status: ApplicationStatus.shortlisted,
      createdAt: DateTime(2026, 7, 9),
    ),
    studentName: 'Zuri Njeri',
    roleTitle: 'Mobile developer intern',
    skills: ['Flutter', 'Accessibility', 'UI design'],
    location: 'Nairobi, Kenya',
  ),
];

class ApplicationReviewController extends Notifier<List<FounderApplication>> {
  StreamSubscription<List<OpportunityApplication>>? subscription;

  @override
  List<FounderApplication> build() {
    final repository = ref.watch(applicationRepositoryProvider);
    if (repository == null) return demoFounderApplications;
    final session = ref.watch(applicationSessionProvider);
    if (session.role == AccountRole.founder && session.uid.isNotEmpty) {
      subscription = repository.watchForFounder(session.uid).listen((items) {
        state = items.isEmpty
            ? demoFounderApplications
            : items.map(_toFounderApplication).toList();
      });
      ref.onDispose(() => subscription?.cancel());
    }
    return demoFounderApplications;
  }

  Future<void> updateStatus(
    String applicationId,
    ApplicationStatus status,
  ) async {
    final previous = state;
    state = [
      for (final item in state)
        if (item.application.id == applicationId)
          item.copyWith(application: item.application.copyWith(status: status))
        else
          item,
    ];
    final repository = ref.read(applicationRepositoryProvider);
    if (repository == null) return;
    try {
      await repository.updateStatus(applicationId, status);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  FounderApplication _toFounderApplication(OpportunityApplication value) {
    return FounderApplication(
      application: value,
      studentName: value.studentName,
      roleTitle: value.roleTitle,
      skills: value.skills,
      location: value.location,
    );
  }
}

final applicationReviewProvider =
    NotifierProvider<ApplicationReviewController, List<FounderApplication>>(
      ApplicationReviewController.new,
    );
