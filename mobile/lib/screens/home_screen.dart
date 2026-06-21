import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/tflite_classifier_service.dart';
import 'about_screen.dart';
import 'camera_screen.dart';
import 'history_screen.dart';
import 'demo_samples_screen.dart';
import 'multi_view_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool? modelAvailable;
  bool? nutModelAvailable;
  String? nutModelMessage;
  @override
  void initState() {
    super.initState();
    // Startup integrity check: file present, input shape correct, label count
    // matches model outputs. A failure leaves the app in clearly-labelled demo
    // mode rather than pretending inference works.
    TFLiteClassifierService.diagnose().then((s) {
      if (mounted) setState(() => modelAvailable = s.ok);
    });
    TFLiteClassifierService.diagnose(
      modelAsset: 'assets/nut_quality_model.tflite',
      labelsAsset: 'assets/nut_quality_labels.txt',
    ).then((s) {
      if (mounted) {
        setState(() {
          nutModelAvailable = s.ok;
          nutModelMessage = s.message;
        });
      }
    });
  }

  void open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.eco, size: 62, color: AppTheme.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AgroLens\nSamegrelo',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                height: .95,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.green,
                              ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Offline AI for hazelnut plant health and nut quality',
                          style: TextStyle(fontSize: 17, color: AppTheme.green),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => open(const CameraScreen()),
                icon: const Icon(Icons.camera_alt_outlined, size: 34),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Text('Take / Choose Photo'),
                ),
              ),
              const SizedBox(height: 14),
              _nav(
                Icons.inventory_2_outlined,
                'Inspect Nut Quality (single image)',
                () => open(const CameraScreen(mode: AnalysisMode.nutQuality)),
              ),
              if (nutModelAvailable == true)
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'Trained model verified • 94.79% single-view test accuracy',
                    style: TextStyle(
                        color: AppTheme.green, fontWeight: FontWeight.w600),
                  ),
                ),
              if (nutModelAvailable == false)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'Demo mode (nut model unavailable): ${nutModelMessage ?? ''}',
                    style: const TextStyle(
                        color: Color(0xFF8A5A00), fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 14),
              _nav(
                Icons.collections_outlined,
                'Multi-view Nut Inspection',
                () => open(const MultiViewScreen()),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  'Average 5–10 photos of one nut • most reliable mode '
                  '(98.74% physical-nut accuracy)',
                  style: TextStyle(
                      color: AppTheme.green, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 14),
              _nav(
                Icons.history,
                'Diagnosis History',
                () => open(const HistoryScreen()),
              ),
              const SizedBox(height: 12),
              _nav(
                Icons.science_outlined,
                'Trained Model Samples',
                () => open(const DemoSamplesScreen()),
              ),
              const SizedBox(height: 12),
              _nav(
                Icons.info_outline,
                'About Project',
                () => open(const AboutScreen()),
              ),
              const SizedBox(height: 24),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.energy_savings_leaf_outlined,
                      color: AppTheme.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Take a clear photo of a hazelnut leaf, fruit, or nut cluster. The app will estimate possible disease or pest damage.',
                      style: TextStyle(height: 1.45, fontSize: 16),
                    ),
                  ),
                ],
              ),
              if (modelAvailable == false) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC83D),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Demo mode: no trained TFLite model found.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
  Widget _nav(IconData icon, String label, VoidCallback onTap) => Material(
        color: AppTheme.green,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.cream, size: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.cream,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.cream),
              ],
            ),
          ),
        ),
      );
}
