import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diagnosis_result.dart';

class HistoryService {
  static const key = 'diagnosis_history';
  Future<List<DiagnosisResult>> load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      return (jsonDecode(prefs.getString(key) ?? '[]') as List)
          .map((e) => DiagnosisResult.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(DiagnosisResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await load();
    items.insert(0, result);
    await prefs.setString(
      key,
      jsonEncode(items.take(100).map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(key);
}
