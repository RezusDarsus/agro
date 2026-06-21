import 'classifier_service.dart';

/// Mirrors the native API so shared code compiles on web.
class ModelLoadStatus {
  final bool ok;
  final String message;
  final int? labelCount;
  final int? outputSize;
  final List<int>? inputShape;
  const ModelLoadStatus(
      {required this.ok,
      required this.message,
      this.labelCount,
      this.outputSize,
      this.inputShape});
}

/// Web preview intentionally uses mock inference because tflite_flutter relies
/// on dart:ffi. Android and iOS use the native implementation instead.
class TFLiteClassifierService implements ClassifierService {
  static Future<TFLiteClassifierService?> tryCreate({
    String modelAsset = 'assets/agrolens_model.tflite',
    String labelsAsset = 'assets/labels.txt',
  }) async =>
      null;

  static Future<ModelLoadStatus> diagnose({
    String modelAsset = 'assets/agrolens_model.tflite',
    String labelsAsset = 'assets/labels.txt',
  }) async =>
      const ModelLoadStatus(
          ok: false,
          message: 'TFLite inference runs in the Android/iOS app, not web.');

  void close() {}

  @override
  Future<DiagnosisPrediction> classifyImage(String imagePath) {
    throw UnsupportedError('TFLite is unavailable in the web preview.');
  }
}
