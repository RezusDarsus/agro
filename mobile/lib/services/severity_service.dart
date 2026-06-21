class SeverityAssessment {
  final double score;
  final String level;
  const SeverityAssessment(this.score, this.level);
}

class SeverityService {
  static const risks = {
    'healthy': .05,
    'stink_bug_damage': .70,
    'fungal_spot': .65,
    'fruit_rot': .80,
    'unknown': .50,
    'quality_nuts': .05,
    'nuts_kernel': .05,
    'damaged_nuts': .85,
  };
  SeverityAssessment assess(String classId, double confidence) {
    if ({'healthy', 'quality_nuts', 'nuts_kernel'}.contains(classId) &&
        confidence >= .65)
      return SeverityAssessment(.7 * confidence + .3 * .05, 'low');
    final score = (.7 * confidence + .3 * (risks[classId] ?? .5)).clamp(
      0.0,
      1.0,
    );
    return SeverityAssessment(
      score,
      score < .35
          ? 'low'
          : score < .70
              ? 'medium'
              : 'high',
    );
  }
}
