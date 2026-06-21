import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('About Project')),
        body: ListView(
          padding: EdgeInsets.all(22),
          children: const [
            Icon(Icons.eco, size: 72, color: Color(0xFF064E34)),
            SizedBox(height: 18),
            Text(
              'AgroLens Samegrelo',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'AgroLens Samegrelo is an offline hackathon MVP for hazelnut growers. '
              'It ships a trained, three-class nut-quality grader '
              '(quality_nuts, nuts_kernel, damaged_nuts) for close-up inspection.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              'Scope',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'This model is for close-up hazelnut quality grading. It does not '
              'diagnose leaf disease, fungal spot, stink-bug injury, or fruit rot. '
              'The separate five-class plant-health flow stays in demo mode until '
              'expert-reviewed field data is available.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              'Limitations',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'In single-image mode a damaged nut can occasionally read as a '
              'quality nut. Use multi-view inspection for important grading '
              'decisions. The app is an assistant, not a certified inspector.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              'Future expansion',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'External Samegrelo field test set, calibrated thresholds, an '
              'unknown/non-nut rejection stage, and agronomist feedback.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      );
}
