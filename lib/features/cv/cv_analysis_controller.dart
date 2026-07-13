import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_controller.dart';

enum CvAnalysisStage { empty, selected, analyzing, ready, failed }

class CvAnalysisState {
  const CvAnalysisState({
    this.stage = CvAnalysisStage.empty,
    this.fileName,
    this.bytes,
    this.skills = const [],
    this.suggestedRoles = const [],
    this.summary = '',
    this.error,
  });

  final CvAnalysisStage stage;
  final String? fileName;
  final Uint8List? bytes;
  final List<String> skills;
  final List<String> suggestedRoles;
  final String summary;
  final String? error;

  bool get hasEvidence => stage == CvAnalysisStage.ready && skills.isNotEmpty;
}

abstract interface class CvAnalysisPersistence {
  Stream<CvAnalysisState?> watch(String uid);
  Future<void> save(String uid, CvAnalysisState analysis);
  Future<void> clear(String uid);
}

class FirestoreCvAnalysisPersistence implements CvAnalysisPersistence {
  FirestoreCvAnalysisPersistence(this.firestore);

  final FirebaseFirestore firestore;

  @override
  Stream<CvAnalysisState?> watch(String uid) =>
      firestore.collection('users').doc(uid).snapshots().map((snapshot) {
        final data = snapshot.data();
        final summary = data?['cvSummary'] as String? ?? '';
        final skills = List<String>.from(data?['skills'] as List? ?? const []);
        final roles = List<String>.from(
          data?['cvSuggestedRoles'] as List? ?? const [],
        );
        final fileName = data?['cvFileName'] as String?;
        if (summary.isEmpty && roles.isEmpty && fileName == null) return null;
        return CvAnalysisState(
          stage: CvAnalysisStage.ready,
          fileName: fileName,
          skills: skills,
          suggestedRoles: roles,
          summary: summary,
        );
      });

  @override
  Future<void> save(String uid, CvAnalysisState analysis) =>
      firestore.collection('users').doc(uid).set({
        'skills': analysis.skills,
        'cvSuggestedRoles': analysis.suggestedRoles,
        'cvSummary': analysis.summary,
        'cvFileName': analysis.fileName,
        'cvAnalyzedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  @override
  Future<void> clear(String uid) => firestore.collection('users').doc(uid).set({
    'cvSuggestedRoles': FieldValue.delete(),
    'cvSummary': FieldValue.delete(),
    'cvFileName': FieldValue.delete(),
    'cvAnalyzedAt': FieldValue.delete(),
  }, SetOptions(merge: true));
}

final cvAnalysisPersistenceProvider = Provider<CvAnalysisPersistence?>((ref) {
  if (Firebase.apps.isEmpty) return null;
  return FirestoreCvAnalysisPersistence(FirebaseFirestore.instance);
});

final cvUserIdProvider = Provider<String>(
  (ref) => ref.watch(sessionProvider.select((session) => session.uid)),
);

// turns a selected cv into editable profile evidence
class CvAnalysisController extends Notifier<CvAnalysisState> {
  @override
  CvAnalysisState build() {
    final persistence = ref.watch(cvAnalysisPersistenceProvider);
    final uid = ref.watch(cvUserIdProvider);
    if (persistence != null && uid.isNotEmpty) {
      final subscription = persistence.watch(uid).listen((saved) {
        if (saved != null && state.stage == CvAnalysisStage.empty) {
          state = saved;
        }
      });
      ref.onDispose(subscription.cancel);
    }
    return const CvAnalysisState();
  }

  Future<void> selectCv() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      allowMultiple: false,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return;
    if (file.size > 8 * 1024 * 1024 || file.bytes == null) {
      state = const CvAnalysisState(
        stage: CvAnalysisStage.failed,
        error: 'Choose a readable PDF smaller than 8 MB.',
      );
      return;
    }
    state = CvAnalysisState(
      stage: CvAnalysisStage.selected,
      fileName: file.name,
      bytes: file.bytes,
    );
  }

  // sends the pdf to firebase ai logic and saves structured results
  Future<void> analyze() async {
    final bytes = state.bytes;
    if (bytes == null) return;
    final selected = state;
    state = CvAnalysisState(
      stage: CvAnalysisStage.analyzing,
      fileName: selected.fileName,
      bytes: bytes,
    );
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.5-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: Schema.object(
            properties: {
              'skills': Schema.array(items: Schema.string()),
              'suggestedRoles': Schema.array(items: Schema.string()),
              'summary': Schema.string(),
            },
          ),
        ),
        systemInstruction: Content.text(
          'Analyze CVs for an ALU internship platform. Extract only evidence '
          'present in the document. Never infer sensitive traits.',
        ),
      );
      final response = await model.generateContent([
        Content.multi([
          TextPart(
            'Return up to eight concise skills, up to three suitable internship '
            'roles, and a one-sentence professional summary.',
          ),
          InlineDataPart('application/pdf', bytes),
        ]),
      ]);
      final data = jsonDecode(response.text ?? '{}') as Map<String, dynamic>;
      final skills = List<String>.from(
        data['skills'] as List? ?? const [],
      ).take(8).toList();
      final roles = List<String>.from(
        data['suggestedRoles'] as List? ?? const [],
      ).take(3).toList();
      final summary = data['summary'] as String? ?? '';
      state = CvAnalysisState(
        stage: CvAnalysisStage.ready,
        fileName: selected.fileName,
        skills: skills,
        suggestedRoles: roles,
        summary: summary,
      );
      await _save();
    } catch (error) {
      state = CvAnalysisState(
        stage: CvAnalysisStage.failed,
        fileName: selected.fileName,
        bytes: bytes,
        error: _analysisErrorMessage(error),
      );
    }
  }

  Future<void> removeSkill(String skill) async {
    final current = state;
    if (current.stage != CvAnalysisStage.ready) return;
    state = CvAnalysisState(
      stage: current.stage,
      fileName: current.fileName,
      skills: current.skills.where((item) => item != skill).toList(),
      suggestedRoles: current.suggestedRoles,
      summary: current.summary,
    );
    await _save();
  }

  Future<void> removeCv() async {
    state = const CvAnalysisState();
    final persistence = ref.read(cvAnalysisPersistenceProvider);
    final uid = ref.read(cvUserIdProvider);
    if (persistence != null && uid.isNotEmpty) await persistence.clear(uid);
  }

  Future<void> _save() async {
    final persistence = ref.read(cvAnalysisPersistenceProvider);
    final uid = ref.read(cvUserIdProvider);
    if (persistence != null && uid.isNotEmpty) {
      await persistence.save(uid, state);
    }
  }
}

final cvAnalysisProvider =
    NotifierProvider<CvAnalysisController, CvAnalysisState>(
      CvAnalysisController.new,
    );

String _analysisErrorMessage(Object error) {
  if (error is ServiceApiNotEnabled) {
    return 'Firebase AI Logic is still starting. Please try again shortly.';
  }
  if (error is QuotaExceeded) {
    return 'The AI usage limit has been reached. Please try again later.';
  }
  if (error is UnsupportedUserLocation) {
    return 'AI analysis is not available in this location.';
  }
  if (error is FormatException) {
    return 'The CV was read, but the response was incomplete. Try again.';
  }

  final message = error.toString().toLowerCase();
  if (message.contains('app check') ||
      message.contains('appcheck') ||
      message.contains('integrity') ||
      message.contains('attestation') ||
      message.contains('permission_denied') ||
      message.contains('403')) {
    return 'Device verification failed. Reopen Unfold and try again.';
  }
  if (message.contains('network') ||
      message.contains('socket') ||
      message.contains('timeout')) {
    return 'Check your connection, then try the analysis again.';
  }
  return 'CV analysis could not be completed. Please try again.';
}
