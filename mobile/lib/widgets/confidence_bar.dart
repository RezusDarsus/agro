import 'package:flutter/material.dart';

class ConfidenceBar extends StatelessWidget {
  final double value;
  const ConfidenceBar({super.key, required this.value});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confidence ${(value * 100).round()}%',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value,
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      );
}
