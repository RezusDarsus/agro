import 'package:flutter_test/flutter_test.dart';
import 'package:agrolens_samegrelo/services/result_interpreter.dart';

void main() {
  test('low confidence is uncertain', () {
    final r = ResultInterpreter.interpret(
      classId: 'quality_nuts',
      confidence: 0.62,
      probabilities: {'quality_nuts': 0.62, 'nuts_kernel': 0.2, 'damaged_nuts': 0.18},
    );
    expect(r.state, ResultState.uncertain);
    expect(r.state.id, 'uncertain');
  });

  test('quality nut with high damage probability needs manual review', () {
    final r = ResultInterpreter.interpret(
      classId: 'quality_nuts',
      confidence: 0.74,
      probabilities: {'quality_nuts': 0.74, 'nuts_kernel': 0.0, 'damaged_nuts': 0.26},
    );
    expect(r.state, ResultState.manualReview);
    expect(r.state.id, 'manual_review_required');
  });

  test('clear quality nut is confident', () {
    final r = ResultInterpreter.interpret(
      classId: 'quality_nuts',
      confidence: 0.95,
      probabilities: {'quality_nuts': 0.95, 'nuts_kernel': 0.03, 'damaged_nuts': 0.02},
    );
    expect(r.state, ResultState.confident);
  });

  test('confident damaged nut is not downgraded', () {
    final r = ResultInterpreter.interpret(
      classId: 'damaged_nuts',
      confidence: 0.9,
      probabilities: {'quality_nuts': 0.05, 'nuts_kernel': 0.05, 'damaged_nuts': 0.9},
    );
    expect(r.state, ResultState.confident);
  });
}
