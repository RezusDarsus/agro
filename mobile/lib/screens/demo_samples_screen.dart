import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants.dart';
import '../models/diagnosis_result.dart';
import '../services/recommendation_service.dart';
import '../services/result_interpreter.dart';
import '../services/severity_service.dart';
import '../services/tflite_classifier_service.dart';
import 'result_screen.dart';

class DemoSamplesScreen extends StatefulWidget {
  const DemoSamplesScreen({super.key});
  @override
  State<DemoSamplesScreen> createState() => _DemoSamplesScreenState();
}

class _DemoSamplesScreenState extends State<DemoSamplesScreen> {
  String? loading;
  static const samples = {
    'assets/demo_images/quality_nuts.jpg': 'Quality hazelnut (in shell)',
    'assets/demo_images/nuts_kernel.jpg': 'Hazelnut kernel',
    'assets/demo_images/damaged_nuts.jpg': 'Damaged hazelnut',
  };

  Future<void> analyze(String asset) async {
    setState(() => loading = asset);
    final classifier = await TFLiteClassifierService.tryCreate(
      modelAsset: 'assets/nut_quality_model.tflite',
      labelsAsset: 'assets/nut_quality_labels.txt',
    );
    if (classifier == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Native TFLite demo requires the Android or iOS app.')));
      setState(() => loading = null);
      return;
    }
    final bytes = await rootBundle.load(asset);
    final file = File(
        '${(await getTemporaryDirectory()).path}/${asset.split('/').last}');
    await file.writeAsBytes(bytes.buffer.asUint8List());
    final prediction = await classifier.classifyImage(file.path);
    classifier.close();
    final severity =
        SeverityService().assess(prediction.classId, prediction.confidence);
    final recommendation =
        await RecommendationService().get(prediction.classId, severity.level);
    final interpretation = ResultInterpreter.interpret(
      classId: prediction.classId,
      confidence: prediction.confidence,
      probabilities: prediction.probabilities,
    );
    final result = DiagnosisResult(
        crop: 'Hazelnut quality (single image)',
        predictedClass: prediction.classId,
        displayName: AppConstants.displayName(prediction.classId),
        confidence: prediction.confidence,
        severityLevel: severity.level,
        severityScore: severity.score,
        recommendationKa: recommendation,
        createdAt: DateTime.now(),
        imagePath: file.path,
        resultState: interpretation.state.id,
        advisory: interpretation.advisory);
    if (mounted)
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => ResultScreen(result: result)));
    if (mounted) setState(() => loading = null);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Trained model samples')),
        body: ListView(padding: const EdgeInsets.all(18), children: [
          const Text(
              'These are real held-out dataset images for demonstrating the separate nut-quality model. They are not plant-disease examples.',
              style: TextStyle(height: 1.4)),
          const SizedBox(height: 16),
          for (final sample in samples.entries)
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(sample.key,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover)),
                          const SizedBox(height: 10),
                          Text(sample.value,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          FilledButton(
                              onPressed: loading == null
                                  ? () => analyze(sample.key)
                                  : null,
                              child: Text(loading == sample.key
                                  ? 'Analyzing…'
                                  : 'Analyze sample')),
                        ]))),
        ]),
      );
}
