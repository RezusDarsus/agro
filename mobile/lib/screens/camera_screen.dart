import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';
import '../models/diagnosis_result.dart';
import '../services/mock_classifier_service.dart';
import '../services/recommendation_service.dart';
import '../services/result_interpreter.dart';
import '../services/severity_service.dart';
import '../services/subject_validation_service.dart';
import '../services/tflite_classifier_service.dart';
import 'result_screen.dart';

enum AnalysisMode { plantHealth, nutQuality }

class CameraScreen extends StatefulWidget {
  final AnalysisMode mode;
  const CameraScreen({super.key, this.mode = AnalysisMode.plantHealth});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  XFile? image;
  bool loading = false;
  String? error;
  Future<void> pick(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(source: source, imageQuality: 90);
      if (x != null)
        setState(() {
          image = x;
          error = null;
        });
    } catch (_) {
      setState(
        () => error = 'Could not access ${source.name}. Check app permissions.',
      );
    }
  }

  Future<void> analyze() async {
    if (image == null || loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final nutMode = widget.mode == AnalysisMode.nutQuality;
      final tflite = await TFLiteClassifierService.tryCreate(
        modelAsset: nutMode
            ? 'assets/nut_quality_model.tflite'
            : 'assets/agrolens_model.tflite',
        labelsAsset:
            nutMode ? 'assets/nut_quality_labels.txt' : 'assets/labels.txt',
      );
      if (nutMode && tflite == null) {
        setState(() {
          error = kIsWeb
              ? 'Nut-quality TFLite inference runs in the Android/iOS app, not the web preview.'
              : 'The nut-quality model could not be loaded.';
          loading = false;
        });
        return;
      }
      if (tflite == null) {
        final validation = SubjectValidationService().validate(
          await image!.readAsBytes(),
        );
        if (!validation.isLikelyPlant) {
          if (mounted) {
            setState(() {
              error = validation.message;
              loading = false;
            });
          }
          return;
        }
      }
      final prediction =
          await (tflite ?? MockClassifierService()).classifyImage(image!.path);
      tflite?.close();
      final severity = SeverityService().assess(
        prediction.classId,
        prediction.confidence,
      );
      final recommendation = await RecommendationService().get(
        prediction.classId,
        severity.level,
      );
      // Nut-quality mode gets the confident/uncertain/manual-review decision.
      final interpretation = nutMode
          ? ResultInterpreter.interpret(
              classId: prediction.classId,
              confidence: prediction.confidence,
              probabilities: prediction.probabilities,
            )
          : null;
      final result = DiagnosisResult(
        crop: nutMode
            ? 'Hazelnut quality (single image)'
            : 'Hazelnut plant health',
        predictedClass: prediction.classId,
        displayName: AppConstants.displayName(prediction.classId),
        confidence: prediction.confidence,
        severityLevel: severity.level,
        severityScore: severity.score,
        recommendationKa: recommendation,
        createdAt: DateTime.now(),
        imagePath: image!.path,
        resultState: interpretation?.state.id ?? 'confident',
        advisory: interpretation?.advisory ?? '',
      );
      if (mounted)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
        );
    } catch (e) {
      if (mounted)
        setState(() {
          error = 'Analysis failed. Please try another clear image.';
          loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.mode == AnalysisMode.nutQuality
              ? 'Inspect nut quality'
              : 'Choose a plant photo'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: image == null
                    ? Container(
                        color: Colors.green.shade50,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 56),
                            SizedBox(height: 10),
                            Text('No image selected'),
                          ],
                        ),
                      )
                    : kIsWeb
                        ? Image.network(image!.path, fit: BoxFit.cover)
                        : Image.file(File(image!.path), fit: BoxFit.cover),
              ),
            ),
            if (widget.mode == AnalysisMode.nutQuality) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.bolt_outlined, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Single-image mode is faster but less reliable. '
                        'For best reliability, use multi-view inspection.',
                        style: TextStyle(height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: image == null || loading ? null : analyze,
              icon: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(loading ? 'Analyzing…' : 'Analyze Image'),
            ),
          ],
        ),
      );
}
