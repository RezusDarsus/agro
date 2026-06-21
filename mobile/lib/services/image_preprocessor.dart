import 'dart:io';
import 'package:image/image.dart' as img;

class ImagePreprocessor {
  Future<List<List<List<List<double>>>>> process(String path) async {
    final decoded = img.decodeImage(await File(path).readAsBytes());
    if (decoded == null)
      throw const FormatException('Unsupported or damaged image.');
    final resized = img.copyResize(decoded, width: 224, height: 224);
    return [
      List.generate(
        224,
        (y) => List.generate(224, (x) {
          final p = resized.getPixel(x, y);
          // Both exported Keras models normalize inside the model graph.
          // TFLite therefore receives raw 0..255 RGB values.
          return [p.r.toDouble(), p.g.toDouble(), p.b.toDouble()];
        }),
      ),
    ];
  }
}
