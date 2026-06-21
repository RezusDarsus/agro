import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/diagnosis_result.dart';
import '../services/history_service.dart';
import '../widgets/diagnosis_card.dart';
import '../widgets/diagnosis_details.dart';
import '../widgets/recommendation_box.dart';
import '../widgets/result_state_banner.dart';

class ResultScreen extends StatefulWidget {
  final DiagnosisResult result;
  const ResultScreen({super.key, required this.result});
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool saved = false;
  Future<void> save() async {
    await HistoryService().save(widget.result);
    if (mounted) setState(() => saved = true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Diagnosis result')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.result.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: kIsWeb
                    ? Image.network(
                        widget.result.imagePath!,
                        height: 220,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(widget.result.imagePath!),
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
              ),
            const SizedBox(height: 14),
            DiagnosisCard(result: widget.result),
            if (widget.result.confidence > 0) ...[
              const SizedBox(height: 14),
              ResultStateBanner(result: widget.result),
            ],
            const SizedBox(height: 14),
            DiagnosisDetails(result: widget.result),
            const SizedBox(height: 14),
            RecommendationBox(text: widget.result.recommendationKa),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              color: Colors.orange.shade50,
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.health_and_safety_outlined),
                  SizedBox(width: 10),
                  Expanded(child: Text(AppConstants.safetyWarning)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: saved ? null : save,
              icon: Icon(saved ? Icons.check : Icons.bookmark_add_outlined),
              label:
                  Text(saved ? 'Saved to history' : 'Save result to history'),
            ),
          ],
        ),
      );
}
