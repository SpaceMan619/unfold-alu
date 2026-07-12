import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CvAnalysisStage { empty, selected, analyzing, ready, failed }

class CvAnalysisState {
  const CvAnalysisState({
    this.stage = CvAnalysisStage.empty,
    this.fileName,
    this.filePath,
    this.skills = const [],
    this.error,
  });

  final CvAnalysisStage stage;
  final String? fileName;
  final String? filePath;
  final List<String> skills;
  final String? error;

  bool get hasEvidence => stage == CvAnalysisStage.ready && skills.isNotEmpty;
}

abstract interface class CvAnalysisService {
  Future<List<String>> analyze(String filePath);
}

class CvAnalysisController extends Notifier<CvAnalysisState> {
  @override
  CvAnalysisState build() => const CvAnalysisState();

  Future<void> selectCv() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      allowMultiple: false,
    );
    final file = result?.files.single;
    if (file == null) return;
    state = CvAnalysisState(
      stage: CvAnalysisStage.selected,
      fileName: file.name,
      filePath: file.path,
    );
  }

  void removeCv() => state = const CvAnalysisState();
}

final cvAnalysisProvider =
    NotifierProvider<CvAnalysisController, CvAnalysisState>(
      CvAnalysisController.new,
    );
