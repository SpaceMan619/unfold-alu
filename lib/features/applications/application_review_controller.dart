import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_controller.dart';
import 'application.dart';
import 'application_repository.dart';

final applicationRepositoryProvider = Provider<ApplicationRepository?>((ref) {
  if (Firebase.apps.isEmpty) return null;
  return FirestoreApplicationRepository(FirebaseFirestore.instance);
});

final applicationSessionProvider = Provider<SessionState>(
  (ref) => ref.watch(sessionProvider),
);

final founderPreviewApplicantsProvider = Provider<bool>((ref) => true);

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

  bool get isPreview => application.isDemo;

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

class ApplicationReviewController extends Notifier<List<FounderApplication>> {
  StreamSubscription<List<OpportunityApplication>>? subscription;
  bool seedingRequested = false;

  @override
  List<FounderApplication> build() {
    final session = ref.watch(applicationSessionProvider);
    if (session.uid.isEmpty) return const [];
    final previewsEnabled = ref.watch(founderPreviewApplicantsProvider);
    final previews = previewsEnabled
        ? _demoApplications(session.uid)
        : const <FounderApplication>[];
    final repository = ref.watch(applicationRepositoryProvider);
    if (repository == null) return previews;
    subscription = repository.watchForFounder(session.uid).listen((items) {
      if (items.isEmpty && previewsEnabled && !seedingRequested) {
        seedingRequested = true;
        unawaited(_seedDemos(repository, session.uid));
      }
      final hasRealApplicants = items.any((item) => !item.isDemo);
      final visibleItems = hasRealApplicants
          ? items.where((item) => !item.isDemo)
          : items;
      state = items.isEmpty && previewsEnabled
          ? previews
          : visibleItems.map(_toFounderApplication).toList();
    });
    ref.onDispose(() => subscription?.cancel());
    return previews;
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
      if (applicationId.startsWith('demo-applicant-')) {
        final founderId = ref.read(applicationSessionProvider).uid;
        await repository.seedFounderDemos(_demoRecords(founderId));
      }
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

  Future<void> _seedDemos(
    ApplicationRepository repository,
    String founderId,
  ) async {
    try {
      await repository.seedFounderDemos(_demoRecords(founderId));
    } catch (_) {
      seedingRequested = false;
    }
  }
}

List<OpportunityApplication> _demoRecords(String founderId) {
  return [
    OpportunityApplication(
      id: 'demo-applicant-$founderId-imani',
      opportunityId: 'demo-founder-role',
      studentId: 'demo-student-imani',
      founderId: founderId,
      motivation:
          'I have led two campus research projects and would love to turn those insights into a product students genuinely use.',
      availability: '12 hours each week',
      portfolioUrl: 'https://example.com/imani',
      status: ApplicationStatus.submitted,
      createdAt: DateTime(2026, 7, 12),
      studentName: 'Imani Okafor',
      studentEmail: 'imani.okafor@example.com',
      roleTitle: 'Product & community intern',
      skills: const ['Research', 'Figma', 'Community'],
      location: 'Kigali · Class of 2027',
      isDemo: true,
    ),
    OpportunityApplication(
      id: 'demo-applicant-$founderId-tendai',
      opportunityId: 'demo-founder-role',
      studentId: 'demo-student-tendai',
      founderId: founderId,
      motivation:
          'My Flutter coursework and student-club operations experience would help me contribute across both product and delivery.',
      availability: '10 hours each week',
      portfolioUrl: 'https://example.com/tendai',
      status: ApplicationStatus.reviewing,
      createdAt: DateTime(2026, 7, 11),
      studentName: 'Tendai Moyo',
      studentEmail: 'tendai.moyo@example.com',
      roleTitle: 'Product & community intern',
      skills: const ['Flutter', 'Operations', 'Firebase'],
      location: 'Kigali · Class of 2026',
      isDemo: true,
    ),
    OpportunityApplication(
      id: 'demo-applicant-$founderId-nadia',
      opportunityId: 'demo-founder-role',
      studentId: 'demo-student-nadia',
      founderId: founderId,
      motivation:
          'I enjoy translating complex ideas into clear stories and have experience coordinating community events across campus.',
      availability: '8 hours each week',
      portfolioUrl: 'https://example.com/nadia',
      status: ApplicationStatus.shortlisted,
      createdAt: DateTime(2026, 7, 10),
      studentName: 'Nadia Uwase',
      studentEmail: 'nadia.uwase@example.com',
      roleTitle: 'Product & community intern',
      skills: const ['Content', 'Events', 'Strategy'],
      location: 'Kigali · Class of 2028',
      isDemo: true,
    ),
  ];
}

List<FounderApplication> _demoApplications(String founderId) {
  final applications = _demoRecords(founderId);
  return [
    for (final application in applications)
      FounderApplication(
        application: application,
        studentName: application.studentName,
        roleTitle: application.roleTitle,
        skills: application.skills,
        location: application.location,
      ),
  ];
}

final applicationReviewProvider =
    NotifierProvider<ApplicationReviewController, List<FounderApplication>>(
      ApplicationReviewController.new,
    );
