import 'package:flutter/material.dart';

class RecommendationBox extends StatelessWidget {
  final String text;
  const RecommendationBox({super.key, required this.text});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFE7F2E8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.eco_outlined),
                SizedBox(width: 8),
                Text('რეკომენდაცია',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Text(text, style: const TextStyle(fontSize: 16, height: 1.45)),
          ],
        ),
      );
}
