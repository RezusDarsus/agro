import 'dart:typed_data';
import 'package:image/image.dart' as img;

class SubjectValidationResult {
  final bool isLikelyPlant;
  final String message;
  final double vegetationRatio;
  final double skinRatio;
  const SubjectValidationResult(
      {required this.isLikelyPlant,
      required this.message,
      required this.vegetationRatio,
      required this.skinRatio});
}

/// Fast offline guard for mock mode. The trained model's `unknown` class is
/// still the authoritative out-of-domain check when a real model is present.
class SubjectValidationService {
  SubjectValidationResult validate(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const SubjectValidationResult(
          isLikelyPlant: false,
          message: 'This image could not be read. Choose a JPG or PNG photo.',
          vegetationRatio: 0,
          skinRatio: 0);
    }
    final sample = img.copyResize(decoded, width: 96, height: 96);
    var vegetation = 0;
    var greenVegetation = 0;
    var skin = 0;
    final colorBins = <int, int>{};
    final total = sample.width * sample.height;
    for (final pixel in sample) {
      final r = pixel.r.toDouble(),
          g = pixel.g.toDouble(),
          b = pixel.b.toDouble();
      final bin = ((r ~/ 32) << 6) | ((g ~/ 32) << 3) | (b ~/ 32);
      colorBins[bin] = (colorBins[bin] ?? 0) + 1;
      final maxC = [r, g, b].reduce((a, v) => a > v ? a : v);
      final minC = [r, g, b].reduce((a, v) => a < v ? a : v);
      final saturation = maxC == 0 ? 0 : (maxC - minC) / maxC;
      final greenPlant = g > r * 1.06 && g > b * 1.12 && g > 42;
      final brownPlant =
          r > 55 && g > 35 && r > g * 1.08 && g > b * 1.12 && saturation > .22;
      if (greenPlant) greenVegetation++;
      if (greenPlant || brownPlant) vegetation++;
      final looksLikeSkin = r > 80 &&
          g > 35 &&
          b > 20 &&
          r > g &&
          g > b &&
          (r - g) > 12 &&
          (r - b) > 25 &&
          saturation > .18;
      if (looksLikeSkin) skin++;
    }
    final vegetationRatio = vegetation / total;
    final skinRatio = skin / total;
    final greenRatio = greenVegetation / total;
    final binCounts = colorBins.values.toList()..sort((a, b) => b - a);
    final dominantColorsRatio =
        binCounts.take(5).fold<int>(0, (sum, value) => sum + value) / total;
    var flatNeighbors = 0;
    var strongEdges = 0;
    final comparisons = sample.height * (sample.width - 1);
    for (var y = 0; y < sample.height; y++) {
      for (var x = 0; x < sample.width - 1; x++) {
        final a = sample.getPixel(x, y);
        final b = sample.getPixel(x + 1, y);
        final dr = (a.r - b.r).abs();
        final dg = (a.g - b.g).abs();
        final db = (a.b - b.b).abs();
        if (dr < 4 && dg < 4 && db < 4) flatNeighbors++;
        if (dr + dg + db > 180) strongEdges++;
      }
    }
    final flatRatio = flatNeighbors / comparisons;
    final edgeRatio = strongEdges / comparisons;
    final likelyIllustration = (dominantColorsRatio > .72 && flatRatio > .45) ||
        (dominantColorsRatio > .80 && edgeRatio > .04);
    final likelyPortrait = skinRatio > .25 && greenRatio < .35;
    final accepted =
        vegetationRatio >= .075 && !likelyPortrait && !likelyIllustration;
    return SubjectValidationResult(
      isLikelyPlant: accepted,
      message: accepted
          ? 'Plant subject detected.'
          : likelyIllustration
              ? 'An illustration or cartoon was detected. Use a real camera photo of a hazelnut leaf, fruit, or nut cluster.'
              : likelyPortrait
                  ? 'A person or non-plant subject was detected. Photograph only a hazelnut leaf, fruit, or nut cluster.'
                  : 'No hazelnut plant material was detected. Retake a close, well-lit photo of a leaf, fruit, or nut cluster.',
      vegetationRatio: vegetationRatio,
      skinRatio: skinRatio,
    );
  }
}
