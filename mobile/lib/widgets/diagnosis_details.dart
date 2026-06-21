import 'package:flutter/material.dart';
import '../models/diagnosis_result.dart';

class DiagnosisDetails extends StatelessWidget {
  final DiagnosisResult result;
  const DiagnosisDetails({super.key, required this.result});

  static const details = {
    'healthy': (
      meaning:
          'No strong visual signs of the supported diseases were detected in this photo.',
      signs:
          'Even leaf color, intact tissue, normal fruit shape, and no expanding spots or soft rot.',
      actions:
          'Continue weekly monitoring. Photograph the same area again if color, texture, or fruit shape changes.',
    ),
    'stink_bug_damage': (
      meaning:
          'The image may resemble feeding injury caused by brown marmorated stink bugs.',
      signs:
          'Look for puncture marks, corky or sunken areas, malformed kernels, insects, eggs, or damage on nearby clusters.',
      actions:
          'Inspect several trees, especially orchard edges. Record how many clusters are affected and consult a local agronomist before treatment.',
    ),
    'fungal_spot': (
      meaning:
          'The image may contain spot patterns visually similar to fungal leaf disease.',
      signs:
          'Check whether spots are expanding, have dark borders, merge together, appear on both leaf surfaces, or occur on nearby leaves.',
      actions:
          'Avoid wetting foliage unnecessarily, photograph affected leaves over several days, remove severely damaged fallen material, and seek agronomist confirmation.',
    ),
    'fruit_rot': (
      meaning:
          'The image may resemble tissue breakdown or rot affecting hazelnut fruit.',
      signs:
          'Look for soft tissue, darkening, mold growth, unpleasant odor, leaking moisture, or multiple damaged nuts in one cluster.',
      actions:
          'Separate damaged fruit, check humidity and drying conditions, disinfect handling equipment, and request specialist guidance if cases increase.',
    ),
    'unknown': (
      meaning:
          'A reliable hazelnut diagnosis could not be produced from this upload.',
      signs:
          'The image may be unrelated, too wide, unclear, poorly lit, or the trained disease model may be unavailable.',
      actions:
          'Use a real close-up photo in daylight. Fill most of the frame with one hazelnut leaf, fruit, or nut cluster and avoid people, cartoons, and distant trees.',
    ),
    'quality_nuts': (
      meaning:
          'The trained nut-quality model found visual features most consistent with an intact nut in shell.',
      signs:
          'Confirm an intact shell, even surface, no holes, no visible mold, and no major discoloration from more than one angle.',
      actions:
          'Keep the nut in the quality batch only after normal manual checks. Store it dry and monitor batch moisture.',
    ),
    'nuts_kernel': (
      meaning:
          'The model identified a shelled hazelnut kernel rather than a nut in shell.',
      signs:
          'Check kernel color, shriveling, mold, odor, insect traces, and storage moisture.',
      actions:
          'Use kernel-specific quality checks. This visual model cannot assess taste, rancidity, aflatoxins, or internal chemistry.',
    ),
    'damaged_nuts': (
      meaning:
          'The model found visual features associated with damaged nuts in the training dataset.',
      signs:
          'Inspect for holes, cracks, surface breakdown, mold-like discoloration, missing shell areas, or deformation.',
      actions:
          'Separate the sample from the quality batch and inspect multiple views. Escalate repeated damage to manual quality control.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final detail = details[result.predictedClass] ?? details['unknown']!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detailed assessment',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _section(Icons.info_outline, 'What this means', detail.meaning),
            _section(Icons.search, 'What to inspect', detail.signs),
            _section(Icons.task_alt, 'Recommended next steps', detail.actions),
            if (result.confidence > 0)
              _section(Icons.analytics_outlined, 'Confidence interpretation',
                  '${(result.confidence * 100).round()}% means the model preferred this class among its supported labels. It is not the probability that an agronomist would confirm the diagnosis.'),
          ],
        ),
      ),
    );
  }

  Widget _section(IconData icon, String title, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(height: 1.4)),
              ])),
        ]),
      );
}
