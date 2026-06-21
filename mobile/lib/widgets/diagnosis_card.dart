import 'package:flutter/material.dart';
import '../models/diagnosis_result.dart';
import 'confidence_bar.dart';
import 'severity_badge.dart';

class DiagnosisCard extends StatelessWidget {
  final DiagnosisResult result;
  const DiagnosisCard({super.key, required this.result});
  @override
  Widget build(BuildContext context) {
    final unavailable =
        result.predictedClass == 'unknown' && result.confidence == 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(unavailable ? 'Analysis status' : 'Analysis: ${result.crop}'),
            const SizedBox(height: 8),
            Text(
              result.displayName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (unavailable)
              const Text(
                'A trained TFLite model is not installed. Demo mode will not invent a disease diagnosis or confidence score for an arbitrary upload.',
                style: TextStyle(fontSize: 16, height: 1.45),
              )
            else ...[
              ConfidenceBar(value: result.confidence),
              const SizedBox(height: 12),
              SeverityBadge(level: result.severityLevel),
            ],
          ],
        ),
      ),
    );
  }
}
