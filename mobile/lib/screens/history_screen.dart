import 'package:flutter/material.dart';
import '../models/diagnosis_result.dart';
import '../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<DiagnosisResult>> items = HistoryService().load();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Diagnosis History'),
          actions: [
            IconButton(
              tooltip: 'Clear history',
              onPressed: () async {
                await HistoryService().clear();
                setState(() => items = HistoryService().load());
              },
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: FutureBuilder<List<DiagnosisResult>>(
          future: items,
          builder: (_, s) {
            if (!s.hasData)
              return const Center(child: CircularProgressIndicator());
            final list = s.data!;
            if (list.isEmpty)
              return const Center(child: Text('No saved diagnoses yet.'));
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) {
                final r = list[i];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.eco)),
                  title: Text(r.displayName),
                  subtitle: Text(
                    '${r.createdAt.toLocal()}\n${(r.confidence * 100).round()}% confidence',
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    r.severityLevel.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            );
          },
        ),
      );
}
