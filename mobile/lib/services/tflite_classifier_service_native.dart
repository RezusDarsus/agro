import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../core/constants.dart';
import 'classifier_service.dart';
import 'image_preprocessor.dart';

/// Result of trying to load a model, for an explicit startup integrity check.
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

class TFLiteClassifierService implements ClassifierService {
  final Interpreter interpreter;
  final List<String> labels;
  TFLiteClassifierService._(this.interpreter, this.labels);

  void close() => interpreter.close();

  /// Loads and validates a model. Returns null if anything is wrong so the app
  /// can fall back to a clearly-labelled demo/mock mode instead of pretending.
  static Future<TFLiteClassifierService?> tryCreate({
    String modelAsset = 'assets/agrolens_model.tflite',
    String labelsAsset = 'assets/labels.txt',
  }) async {
    Interpreter? interpreter;
    try {
      interpreter = await Interpreter.fromAsset(modelAsset);
      final labels = await _loadLabels(labelsAsset);
      final status = _validate(interpreter, labels);
      if (!status.ok) {
        interpreter.close();
        return null;
      }
      return TFLiteClassifierService._(interpreter, labels);
    } catch (_) {
      interpreter?.close();
      return null;
    }
  }

  static Future<List<String>> _loadLabels(String asset) async =>
      (await rootBundle.loadString(asset))
          .split(RegExp(r'\r?\n'))
          .where((e) => e.trim().isNotEmpty)
          .toList();

  static ModelLoadStatus _validate(Interpreter interpreter, List<String> labels) {
    final inputShape = interpreter.getInputTensor(0).shape;
    final outputSize = interpreter.getOutputTensor(0).shape.last;
    if (labels.isEmpty) {
      return const ModelLoadStatus(ok: false, message: 'Label file is empty.');
    }
    final inputOk = inputShape.length == 4 &&
        inputShape[1] == 224 &&
        inputShape[2] == 224 &&
        inputShape[3] == 3;
    if (!inputOk) {
      return ModelLoadStatus(
          ok: false,
          message: 'Unexpected input shape $inputShape (expected [1, 224, 224, 3]).',
          inputShape: inputShape);
    }
    if (labels.length != outputSize) {
      return ModelLoadStatus(
          ok: false,
          message: 'Label count (${labels.length}) does not match model '
              'outputs ($outputSize).',
          labelCount: labels.length,
          outputSize: outputSize);
    }
    return ModelLoadStatus(
        ok: true,
        message: 'Model verified: ${labels.length} classes, input $inputShape.',
        labelCount: labels.length,
        outputSize: outputSize,
        inputShape: inputShape);
  }

  /// Pure integrity check: verifies the file loads, the input shape is the
  /// expected [1,224,224,3], and the label count matches model outputs. Opens
  /// and closes its own interpreter; holds no state.
  static Future<ModelLoadStatus> diagnose({
    String modelAsset = 'assets/agrolens_model.tflite',
    String labelsAsset = 'assets/labels.txt',
  }) async {
    Interpreter? interpreter;
    try {
      interpreter = await Interpreter.fromAsset(modelAsset);
      final labels = await _loadLabels(labelsAsset);
      return _validate(interpreter, labels);
    } catch (e) {
      return ModelLoadStatus(ok: false, message: 'Model failed to load: $e');
    } finally {
      interpreter?.close();
    }
  }

  @override
  Future<DiagnosisPrediction> classifyImage(String imagePath) async {
    final input = await ImagePreprocessor().process(imagePath);
    final output = [List<double>.filled(labels.length, 0)];
    interpreter.run(input, output);
    var values = output.first;
    final sum = values.fold<double>(0, (a, b) => a + b);
    if (values.any((e) => e < 0) || (sum - 1).abs() > .05) {
      final maxV = values.reduce(math.max);
      final exp = values.map((e) => math.exp(e - maxV)).toList();
      final denom = exp.reduce((a, b) => a + b);
      values = exp.map((e) => e / denom).toList();
    }
    final probs = <String, double>{
      for (var i = 0; i < labels.length; i++) labels[i]: values[i],
    };
    final top = probs.entries.reduce((a, b) => a.value >= b.value ? a : b);
    // Only collapse to 'unknown' for models that actually have that class
    // (plant-health). The 3-class nut model returns its true argmax; the
    // app-level ResultInterpreter handles uncertainty instead.
    final hasUnknown = labels.contains('unknown');
    final classId = (hasUnknown && top.value < AppConstants.confidenceThreshold)
        ? 'unknown'
        : top.key;
    return DiagnosisPrediction(
      classId: classId,
      confidence: top.value,
      probabilities: probs,
    );
  }
}
