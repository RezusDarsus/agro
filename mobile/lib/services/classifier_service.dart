class DiagnosisPrediction {
  final String classId;
  final double confidence;
  final Map<String, double> probabilities;
  const DiagnosisPrediction({
    required this.classId,
    required this.confidence,
    required this.probabilities,
  });
}

abstract class ClassifierService {
  Future<DiagnosisPrediction> classifyImage(String imagePath);
}
