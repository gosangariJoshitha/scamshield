class AnalysisRecord {
  const AnalysisRecord({
    required this.id,
    required this.content,
    required this.riskScore,
    required this.riskLevel,
    required this.classification,
    required this.category,
    required this.inputType,
    required this.createdAt,
    this.originalFilename,
    this.explanation,
    this.recommendedAction,
    this.mlProbability,
    this.llmConfidence,
    this.indicators = const [],
    this.retrievedEvidence = const [],
    this.processingStatus,
    this.safeActions = const [],
    this.actionTranslations = const {},
    this.defaultLanguage,
  });

  final int id;
  final String content;
  final int riskScore;
  final String riskLevel;
  final String classification;
  final String category;
  final String inputType;
  final DateTime createdAt;
  final String? originalFilename;
  final String? explanation;
  final String? recommendedAction;
  final double? mlProbability;
  final double? llmConfidence;
  final List<String> indicators;
  final List<AnalysisEvidence> retrievedEvidence;
  final String? processingStatus;
  final List<String> safeActions;
  final Map<String, List<String>> actionTranslations;
  final String? defaultLanguage;

  factory AnalysisRecord.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['created_at'];
    if (createdAtValue is! String) {
      throw const FormatException('Analysis response is missing created_at.');
    }
    final createdAt = DateTime.tryParse(createdAtValue);
    if (createdAt == null) {
      throw const FormatException('Analysis response has an invalid date.');
    }

    return AnalysisRecord(
      id: _requiredInt(json, 'id'),
      content: _requiredString(json, 'content'),
      riskScore: _requiredInt(json, 'risk_score'),
      riskLevel: _requiredString(json, 'risk_level'),
      classification: _requiredString(json, 'classification'),
      category: _requiredString(json, 'category'),
      inputType: json['input_type'] is String
          ? json['input_type'] as String
          : 'text',
      createdAt: createdAt,
      originalFilename: json['original_filename'] as String?,
      explanation: json['explanation'] as String?,
      recommendedAction: json['recommended_action'] is String
          ? json['recommended_action'] as String
          : null,
      mlProbability: _optionalDouble(json['ml_probability']),
      llmConfidence: _optionalDouble(json['llm_confidence']),
      indicators: _stringList(json['indicators']),
      retrievedEvidence: _evidenceList(json['retrieved_evidence_data']),
      processingStatus: json['processing_status'] as String?,
      safeActions: _safeActions(json['safe_actions']),
      actionTranslations: _actionTranslations(json['safe_actions']),
      defaultLanguage: _defaultLanguage(json['safe_actions']),
    );
  }

  static double? _optionalDouble(Object? value) =>
      value is num ? value.toDouble() : null;

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }

  static List<String> _safeActions(Object? value) {
    if (value is! Map) return const [];
    return _stringList(value['canonical']);
  }

  static Map<String, List<String>> _actionTranslations(Object? value) {
    if (value is! Map) return const {};
    final raw = value['translations'];
    if (raw is! Map) return const {};
    final result = <String, List<String>>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      final val = entry.value;
      if (key is String && val is List) {
        result[key] = val
            .whereType<String>()
            .where((item) => item.trim().isNotEmpty)
            .toList(growable: false);
      }
    }
    return result;
  }

  static String? _defaultLanguage(Object? value) {
    if (value is! Map) return null;
    final lang = value['default_language'];
    return lang is String ? lang : null;
  }

  static List<AnalysisEvidence> _evidenceList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => AnalysisEvidence.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    throw FormatException('Analysis response is missing $key.');
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('Analysis response is missing $key.');
  }
}

class AnalysisEvidence {
  const AnalysisEvidence({
    required this.title,
    required this.category,
    required this.pattern,
    required this.source,
    this.similarityScore,
    this.safeAction,
  });

  final String title;
  final String category;
  final String pattern;
  final String source;
  final double? similarityScore;
  final String? safeAction;

  factory AnalysisEvidence.fromJson(Map<String, dynamic> json) {
    String readString(String key, {String fallback = ''}) {
      final value = json[key];
      return value is String ? value : fallback;
    }

    final similarity = json['similarity_score'];
    return AnalysisEvidence(
      title: readString('title', fallback: 'Related safety pattern'),
      category: readString('category'),
      pattern: readString('pattern'),
      source: readString('source'),
      similarityScore: similarity is num ? similarity.toDouble() : null,
      safeAction: readString('safe_action'),
    );
  }
}
