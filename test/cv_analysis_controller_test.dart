import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unfold/features/cv/cv_analysis_controller.dart';

class FakeCvPersistence implements CvAnalysisPersistence {
  final values = StreamController<CvAnalysisState?>.broadcast();
  CvAnalysisState? saved;
  String? savedFor;
  String? clearedFor;

  @override
  Stream<CvAnalysisState?> watch(String uid) => values.stream;

  @override
  Future<void> save(String uid, CvAnalysisState analysis) async {
    savedFor = uid;
    saved = analysis;
  }

  @override
  Future<void> clear(String uid) async => clearedFor = uid;
}

void main() {
  test(
    'restores CV intelligence and persists skill removal per user',
    () async {
      final persistence = FakeCvPersistence();
      final container = ProviderContainer(
        overrides: [
          cvAnalysisPersistenceProvider.overrideWithValue(persistence),
          cvUserIdProvider.overrideWithValue('student-a'),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await persistence.values.close();
      });

      container.read(cvAnalysisProvider);
      persistence.values.add(
        const CvAnalysisState(
          stage: CvAnalysisStage.ready,
          fileName: 'resume.pdf',
          skills: ['Flutter', 'Research'],
          suggestedRoles: ['Product intern'],
          summary: 'An ALU student building digital products.',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(cvAnalysisProvider).fileName, 'resume.pdf');
      await container.read(cvAnalysisProvider.notifier).removeSkill('Research');

      expect(container.read(cvAnalysisProvider).skills, ['Flutter']);
      expect(persistence.savedFor, 'student-a');
      expect(persistence.saved?.skills, ['Flutter']);
    },
  );

  test(
    'removing a CV clears its persisted intelligence for that user',
    () async {
      final persistence = FakeCvPersistence();
      final container = ProviderContainer(
        overrides: [
          cvAnalysisPersistenceProvider.overrideWithValue(persistence),
          cvUserIdProvider.overrideWithValue('student-b'),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await persistence.values.close();
      });

      await container.read(cvAnalysisProvider.notifier).removeCv();

      expect(container.read(cvAnalysisProvider).stage, CvAnalysisStage.empty);
      expect(persistence.clearedFor, 'student-b');
    },
  );
}
