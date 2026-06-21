import 'package:flutter/material.dart';

class SeverityBadge extends StatelessWidget {
  final String level;
  const SeverityBadge({super.key, required this.level});
  @override
  Widget build(BuildContext context) {
    final c = level == 'low'
        ? Colors.green
        : level == 'medium'
            ? Colors.orange
            : Colors.red;
    return Chip(
      avatar: Icon(Icons.circle, color: c, size: 12),
      label: Text('${level[0].toUpperCase()}${level.substring(1)} severity'),
      side: BorderSide(color: c),
      backgroundColor: c.withValues(alpha: .10),
    );
  }
}
