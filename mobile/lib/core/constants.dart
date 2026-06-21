class AppConstants {
  /// Plant-health demo model labels (includes a trained `unknown` class).
  static const labels = [
    'healthy',
    'stink_bug_damage',
    'fungal_spot',
    'fruit_rot',
    'unknown',
  ];

  /// Canonical nut-quality classes. These are the exact strings used by the ML
  /// pipeline, labels.txt, recommendations, and docs. There are no synonyms.
  static const nutQualityLabels = [
    'quality_nuts',
    'nuts_kernel',
    'damaged_nuts',
  ];

  /// Display-only names. The model and storage always use canonical ids above;
  /// these are presentation strings (mirrors assets/nut_quality_display_labels.json).
  static const displayNames = {
    'healthy': 'Healthy',
    'stink_bug_damage': 'Brown marmorated stink bug damage',
    'fungal_spot': 'Fungal spot',
    'fruit_rot': 'Fruit rot',
    'unknown': 'Unknown / uncertain',
    'quality_nuts': 'Quality hazelnut (in shell)',
    'nuts_kernel': 'Hazelnut kernel',
    'damaged_nuts': 'Damaged hazelnut',
  };

  static String displayName(String classId) =>
      displayNames[classId] ?? classId;

  /// Plant-health "unknown" cut-off (that model has a real unknown output).
  static const confidenceThreshold = 0.65;

  /// Below this top probability a nut-quality result is "uncertain".
  static const nutConfidenceThreshold = 0.70;

  /// If a nut reads as quality_nuts but damaged_nuts probability exceeds this,
  /// recommend manual inspection.
  static const damageReviewThreshold = 0.20;

  /// Minimum share of views that must agree in multi-view mode.
  static const multiViewAgreementThreshold = 0.70;
  static const multiViewMinImages = 5;
  static const multiViewMaxImages = 10;

  static const safetyWarning =
      'This is an AI-assisted prediction, not a final agronomist diagnosis. For high severity or low confidence, contact a specialist.';

  static const scopeNote =
      'This model is for close-up hazelnut quality grading. It does not diagnose leaf disease, fungal spot, stink-bug injury, or fruit rot.';
}
