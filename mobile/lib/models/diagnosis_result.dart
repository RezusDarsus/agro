class DiagnosisResult {
  final String crop;
  final String predictedClass;
  final String displayName;
  final double confidence;
  final String severityLevel;
  final double severityScore;
  final String recommendationKa;
  final DateTime createdAt;
  final String? imagePath;

  /// App-level decision state: confident | uncertain | manual_review_required.
  final String resultState;

  /// Plain-language advisory tied to [resultState] (may be empty).
  final String advisory;

  /// Number of images aggregated (1 = single image, 5..10 = multi-view).
  final int viewCount;

  /// "8/10 views agree" style text for multi-view results (null otherwise).
  final String? agreement;

  const DiagnosisResult({
    required this.crop,
    required this.predictedClass,
    required this.displayName,
    required this.confidence,
    required this.severityLevel,
    required this.severityScore,
    required this.recommendationKa,
    required this.createdAt,
    this.imagePath,
    this.resultState = 'confident',
    this.advisory = '',
    this.viewCount = 1,
    this.agreement,
  });

  Map<String, dynamic> toJson() => {
        'crop': crop,
        'predictedClass': predictedClass,
        'displayName': displayName,
        'confidence': confidence,
        'severityLevel': severityLevel,
        'severityScore': severityScore,
        'recommendationKa': recommendationKa,
        'createdAt': createdAt.toIso8601String(),
        'imagePath': imagePath,
        'resultState': resultState,
        'advisory': advisory,
        'viewCount': viewCount,
        'agreement': agreement,
      };

  factory DiagnosisResult.fromJson(Map<String, dynamic> j) => DiagnosisResult(
        crop: j['crop'],
        predictedClass: j['predictedClass'],
        displayName: j['displayName'],
        confidence: (j['confidence'] as num).toDouble(),
        severityLevel: j['severityLevel'],
        severityScore: (j['severityScore'] as num).toDouble(),
        recommendationKa: j['recommendationKa'],
        createdAt: DateTime.parse(j['createdAt']),
        imagePath: j['imagePath'],
        resultState: j['resultState'] ?? 'confident',
        advisory: j['advisory'] ?? '',
        viewCount: (j['viewCount'] as num?)?.toInt() ?? 1,
        agreement: j['agreement'],
      );
}
