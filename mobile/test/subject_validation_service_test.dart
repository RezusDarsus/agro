import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:agrolens_samegrelo/services/subject_validation_service.dart';

Uint8List jpg(int r, int g, int b) {
  final image = img.Image(width: 100, height: 100);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final variation = ((x * 13 + y * 7) % 31) - 15;
      image.setPixelRgb(
        x,
        y,
        (r + variation).clamp(0, 255),
        (g + variation).clamp(0, 255),
        (b + variation).clamp(0, 255),
      );
    }
  }
  return Uint8List.fromList(img.encodeJpg(image));
}

Uint8List cartoon() {
  final image = img.Image(width: 100, height: 100);
  img.fill(image, color: img.ColorRgb8(72, 165, 58));
  img.fillRect(image,
      x1: 40, y1: 0, x2: 60, y2: 99, color: img.ColorRgb8(160, 105, 67));
  img.drawLine(image,
      x1: 39,
      y1: 0,
      x2: 39,
      y2: 99,
      color: img.ColorRgb8(0, 0, 0),
      thickness: 3);
  img.drawLine(image,
      x1: 61,
      y1: 0,
      x2: 61,
      y2: 99,
      color: img.ColorRgb8(0, 0, 0),
      thickness: 3);
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  final validator = SubjectValidationService();

  test('accepts a strong vegetation signal', () {
    expect(validator.validate(jpg(45, 135, 35)).isLikelyPlant, isTrue);
  });

  test('rejects a skin-dominant portrait-like signal', () {
    final result = validator.validate(jpg(190, 125, 85));
    expect(result.isLikelyPlant, isFalse);
    expect(result.message, contains('person'));
  });

  test('rejects an image without plant signal', () {
    expect(validator.validate(jpg(80, 80, 80)).isLikelyPlant, isFalse);
  });

  test('rejects flat-color cartoons', () {
    final result = validator.validate(cartoon());
    expect(result.isLikelyPlant, isFalse);
    expect(result.message, contains('cartoon'));
  });
}
