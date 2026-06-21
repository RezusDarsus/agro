import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:agrolens_samegrelo/services/image_preprocessor.dart';

void main() {
  test('sends raw RGB values because normalization is inside the model',
      () async {
    final image = img.Image(width: 2, height: 2);
    img.fill(image, color: img.ColorRgb8(200, 100, 50));
    final file =
        File('${Directory.systemTemp.path}/agrolens_preprocess_test.jpg');
    await file.writeAsBytes(img.encodeJpg(image, quality: 100));
    final tensor = await ImagePreprocessor().process(file.path);
    expect(tensor[0][0][0][0], greaterThan(190));
    expect(tensor[0][0][0][1], greaterThan(90));
    expect(tensor[0][0][0][2], greaterThan(40));
    await file.delete();
  });
}
