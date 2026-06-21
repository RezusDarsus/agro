import 'package:flutter_test/flutter_test.dart';
import 'package:agrolens_samegrelo/services/mock_classifier_service.dart';

void main() {
  test('arbitrary uploads never receive a fabricated disease result', () async {
    final result =
        await MockClassifierService().classifyImage('uploads/random-tree.jpg');
    expect(result.classId, 'unknown');
    expect(result.confidence, 0);
  });

  test('explicitly named demo files can exercise result UI', () async {
    final result =
        await MockClassifierService().classifyImage('demo/fungal_spot.jpg');
    expect(result.classId, 'fungal_spot');
    expect(result.confidence, greaterThan(.65));
  });
}
