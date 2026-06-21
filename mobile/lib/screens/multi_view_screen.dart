import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';
import '../models/diagnosis_result.dart';
import '../services/history_service.dart';
import '../services/recommendation_service.dart';
import '../services/result_interpreter.dart';
import '../services/severity_service.dart';
import '../services/tflite_classifier_service.dart';

/// Multi-view nut inspection: average the model over 5–10 photos of the SAME
/// physical nut for a more reliable grade, mirroring how the dataset reaches
/// ~98.7% physical-nut accuracy by aggregating ten views.
class MultiViewScreen extends StatefulWidget {
  const MultiViewScreen({super.key});
  @override
  State<MultiViewScreen> createState() => _MultiViewScreenState();
}

class _MultiViewScreenState extends State<MultiViewScreen> {
  final List<XFile> images = [];
  bool loading = false;
  String? error;
  _MultiViewResult? result;

  Future<void> addFromGallery() async {
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 90);
      if (picked.isNotEmpty) {
        setState(() {
          error = null;
          for (final x in picked) {
            if (images.length < AppConstants.multiViewMaxImages) images.add(x);
          }
        });
      }
    } catch (_) {
      setState(() => error = 'Could not open the gallery. Check permissions.');
    }
  }

  Future<void> addFromCamera() async {
    if (images.length >= AppConstants.multiViewMaxImages) return;
    try {
      final x =
          await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 90);
      if (x != null) setState(() => images.add(x));
    } catch (_) {
      setState(() => error = 'Could not open the camera. Check permissions.');
    }
  }

  Future<void> analyze() async {
    if (images.length < AppConstants.multiViewMinImages || loading) return;
    setState(() {
      loading = true;
      error = null;
      result = null;
    });
    final tflite = await TFLiteClassifierService.tryCreate(
      modelAsset: 'assets/nut_quality_model.tflite',
      labelsAsset: 'assets/nut_quality_labels.txt',
    );
    if (tflite == null) {
      setState(() {
        error = kIsWeb
            ? 'Multi-view TFLite inference runs in the Android/iOS app, not the web preview.'
            : 'The nut-quality model could not be loaded.';
        loading = false;
      });
      return;
    }
    try {
      const labels = AppConstants.nutQualityLabels;
      final sums = {for (final l in labels) l: 0.0};
      final perViewClass = <String>[];
      for (final x in images) {
        final p = await tflite.classifyImage(x.path);
        for (final l in labels) {
          sums[l] = sums[l]! + (p.probabilities[l] ?? 0);
        }
        perViewClass.add(p.classId);
      }
      tflite.close();
      final n = images.length;
      final avg = {for (final l in labels) l: sums[l]! / n};
      final top =
          avg.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final agree = perViewClass.where((c) => c == top.key).length;
      final agreementRatio = agree / n;

      var interpretation = ResultInterpreter.interpret(
        classId: top.key,
        confidence: top.value,
        probabilities: avg,
      );
      // Low cross-view agreement overrides to manual review regardless of mean.
      if (agreementRatio < AppConstants.multiViewAgreementThreshold) {
        interpretation = ResultInterpretation(
          ResultState.manualReview,
          'Views disagree — manual inspection recommended',
          'Only $agree of $n views agree with the averaged result. Re-photograph '
              'the nut from clearer angles or inspect it by hand.',
        );
      }
      setState(() {
        result = _MultiViewResult(
          classId: top.key,
          confidence: top.value,
          probabilities: avg,
          agree: agree,
          total: n,
          interpretation: interpretation,
        );
        loading = false;
      });
    } catch (_) {
      tflite.close();
      setState(() {
        error = 'Analysis failed. Use clear, well-lit photos of one nut.';
        loading = false;
      });
    }
  }

  Future<void> save() async {
    final r = result!;
    final severity = SeverityService().assess(r.classId, r.confidence);
    final recommendation =
        await RecommendationService().get(r.classId, severity.level);
    await HistoryService().save(DiagnosisResult(
      crop: 'Hazelnut quality (multi-view)',
      predictedClass: r.classId,
      displayName: AppConstants.displayName(r.classId),
      confidence: r.confidence,
      severityLevel: severity.level,
      severityScore: severity.score,
      recommendationKa: recommendation,
      createdAt: DateTime.now(),
      imagePath: images.first.path,
      resultState: r.interpretation.state.id,
      advisory: r.interpretation.advisory,
      viewCount: r.total,
      agreement: '${r.agree}/${r.total} views agree',
    ));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved to history.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final enough = images.length >= AppConstants.multiViewMinImages;
    return Scaffold(
      appBar: AppBar(title: const Text('Multi-view nut inspection')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text(
          'Capture or select 5–10 photos of the SAME physical nut from different '
          'angles. Averaging views is more reliable than a single image.',
          style: TextStyle(height: 1.4),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: images.length >= AppConstants.multiViewMaxImages
                  ? null
                  : addFromCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: images.length >= AppConstants.multiViewMaxImages
                  ? null
                  : addFromGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Gallery'),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Text('${images.length} / ${AppConstants.multiViewMaxImages} photos '
            '(minimum ${AppConstants.multiViewMinImages})'),
        const SizedBox(height: 10),
        if (images.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, crossAxisSpacing: 6, mainAxisSpacing: 6),
            itemCount: images.length,
            itemBuilder: (_, i) => Stack(fit: StackFit.expand, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: kIsWeb
                    ? Image.network(images[i].path, fit: BoxFit.cover)
                    : Image.file(File(images[i].path), fit: BoxFit.cover),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => setState(() => images.removeAt(i)),
                  child: const CircleAvatar(
                    radius: 11,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ]),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(error!, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: enough && !loading ? analyze : null,
          icon: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.auto_awesome),
          label: Text(loading
              ? 'Averaging ${images.length} views…'
              : 'Analyze ${images.length} views'),
        ),
        if (result != null) ...[
          const SizedBox(height: 20),
          _ResultPanel(result: result!, onSave: save),
        ],
      ]),
    );
  }
}

class _MultiViewResult {
  final String classId;
  final double confidence;
  final Map<String, double> probabilities;
  final int agree;
  final int total;
  final ResultInterpretation interpretation;
  const _MultiViewResult({
    required this.classId,
    required this.confidence,
    required this.probabilities,
    required this.agree,
    required this.total,
    required this.interpretation,
  });
}

class _ResultPanel extends StatelessWidget {
  final _MultiViewResult result;
  final VoidCallback onSave;
  const _ResultPanel({required this.result, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final state = result.interpretation.state;
    final color = switch (state) {
      ResultState.uncertain => const Color(0xFFFFC83D),
      ResultState.manualReview => const Color(0xFFFF8A4C),
      ResultState.confident => const Color(0xFF7CC47F),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Averaged result',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(AppConstants.displayName(result.classId),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${(result.confidence * 100).round()}% averaged confidence'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: color.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(8)),
            child: Text('${result.agree}/${result.total} views agree',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 16),
          for (final l in AppConstants.nutQualityLabels)
            _Bar(label: AppConstants.displayName(l), value: result.probabilities[l] ?? 0),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: .15),
                border: Border.all(color: color),
                borderRadius: BorderRadius.circular(12)),
            child: Text(result.interpretation.advisory,
                style: const TextStyle(height: 1.4)),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Save result to history'),
          ),
        ]),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double value;
  const _Bar({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: Text(label)),
            Text('${(value * 100).round()}%'),
          ]),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            minHeight: 9,
            borderRadius: BorderRadius.circular(6),
          ),
        ]),
      );
}
