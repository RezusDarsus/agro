import '../core/constants.dart';
import 'classifier_service.dart';

class MockClassifierService implements ClassifierService {
  @override
  Future<DiagnosisPrediction> classifyImage(String imagePath) async {
    final normalized = imagePath.toLowerCase();
    final explicitDemoClass = AppConstants.labels
        .where(
          (label) => label != 'unknown' && normalized.contains(label),
        )
        .firstOrNull;
    if (explicitDemoClass == null) {
      return const DiagnosisPrediction(
        classId: 'unknown',
        confidence: 0,
        probabilities: {
          'healthy': 0,
          'stink_bug_damage': 0,
          'fungal_spot': 0,
          'fruit_rot': 0,
          'unknown': 1,
        },
      );
    }
    final seed = imagePath.codeUnits.fold<int>(
      0,
      (a, b) => (a * 31 + b) & 0x7fffffff,
    );
    final chosen = explicitDemoClass;
    final confidence = 0.72 + (seed % 22) / 100;
    final rest = (1 - confidence) / 4;
    final probabilities = {
      for (final label in AppConstants.labels)
        label: label == chosen ? confidence : rest,
    };
    return DiagnosisPrediction(
      classId: chosen,
      confidence: confidence,
      probabilities: probabilities,
    );
  }
}
