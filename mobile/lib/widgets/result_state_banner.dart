import 'package:flutter/material.dart';
import '../models/diagnosis_result.dart';

/// Shows the app-level decision state (confident / uncertain /
/// manual_review_required) with its advisory text and any view-agreement note.
class ResultStateBanner extends StatelessWidget {
  final DiagnosisResult result;
  const ResultStateBanner({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final (color, icon, title) = switch (result.resultState) {
      'uncertain' => (
          const Color(0xFFFFC83D),
          Icons.help_outline,
          'Uncertain — retake photo'
        ),
      'manual_review_required' => (
          const Color(0xFFFF8A4C),
          Icons.front_hand_outlined,
          'Manual inspection recommended'
        ),
      _ => (const Color(0xFF7CC47F), Icons.verified_outlined, 'Confident result'),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .18),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ]),
          if (result.advisory.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(result.advisory, style: const TextStyle(height: 1.4)),
          ],
          if (result.agreement != null) ...[
            const SizedBox(height: 8),
            Text('Multi-view agreement: ${result.agreement} '
                '(${result.viewCount} photos averaged)'),
          ],
        ],
      ),
    );
  }
}
