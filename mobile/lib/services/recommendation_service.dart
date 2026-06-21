import 'dart:convert';
import 'package:flutter/services.dart';

class RecommendationService {
  Future<String> get(String disease, String severity) async {
    try {
      final data = jsonDecode(
        await rootBundle.loadString('assets/recommendations_ka.json'),
      ) as Map<String, dynamic>;
      return data[disease]?[severity]?['ka'] ??
          data['unknown']?['medium']?['ka'] ??
          _fallback;
    } catch (_) {
      return _fallback;
    }
  }

  static const _fallback =
      'შედეგის გადამოწმებისთვის გადაიღეთ მკაფიო ფოტო ან მიმართეთ აგრონომს.';
}
