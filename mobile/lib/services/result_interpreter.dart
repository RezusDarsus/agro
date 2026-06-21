import '../core/constants.dart';

enum ResultState { confident, uncertain, manualReview }

extension ResultStateInfo on ResultState {
  String get id => switch (this) {
        ResultState.confident => 'confident',
        ResultState.uncertain => 'uncertain',
        ResultState.manualReview => 'manual_review_required',
      };
}

class ResultInterpretation {
  final ResultState state;
  final String headline;
  final String advisory;
  const ResultInterpretation(this.state, this.headline, this.advisory);
}

/// Turns a raw nut-quality prediction into an app-level decision state.
///
/// Rules (requirement 2):
///  * confidence < 0.70           -> uncertain ("retake photo")
///  * quality_nuts but P(damaged) > 0.20 -> manual review
///  * otherwise                    -> confident
class ResultInterpreter {
  static ResultInterpretation interpret({
    required String classId,
    required double confidence,
    required Map<String, double> probabilities,
  }) {
    if (confidence < AppConstants.nutConfidenceThreshold) {
      return const ResultInterpretation(
        ResultState.uncertain,
        'Uncertain — retake photo',
        'Confidence is below 70%. Retake a sharp, well-lit close-up on a plain '
            'background, or use multi-view inspection for a more reliable result.',
      );
    }
    final damaged = probabilities['damaged_nuts'] ?? 0;
    if (classId == 'quality_nuts' &&
        damaged > AppConstants.damageReviewThreshold) {
      return ResultInterpretation(
        ResultState.manualReview,
        'Possible damage — manual inspection recommended',
        'The nut looks like quality, but damage probability is '
            '${(damaged * 100).round()}%. Inspect it by hand or from more angles '
            'before accepting it into a quality batch.',
      );
    }
    return const ResultInterpretation(
      ResultState.confident,
      'Confident result',
      'Confidence is above the 70% threshold and no damage flag was raised.',
    );
  }
}
