import 'package:flutter/foundation.dart';

@immutable
class GuardianRetrievedEvidence {
  const GuardianRetrievedEvidence({
    required this.knowledgeId,
    required this.title,
    required this.category,
    required this.similarityScore,
    required this.pattern,
    required this.description,
    required this.indicators,
    required this.safeAction,
    required this.source,
    required this.language,
  });

  final int knowledgeId;
  final String title;
  final String category;
  final double similarityScore;
  final String pattern;
  final String description;
  final List<String> indicators;
  final String safeAction;
  final String source;
  final String language;

  factory GuardianRetrievedEvidence.fromJson(Map<String, dynamic> json) {
    final knowledgeId = json['knowledge_id'];
    final title = json['title'] as String? ?? '';
    final category = json['category'] as String? ?? '';
    final similarityScore = (json['similarity_score'] as num?)?.toDouble() ?? 0.0;
    final pattern = json['pattern'] as String? ?? '';
    final description = json['description'] as String? ?? '';
    final rawIndicators = json['indicators'];
    final indicators = rawIndicators is List
        ? rawIndicators.whereType<String>().toList(growable: false)
        : const <String>[];
    final safeAction = json['safe_action'] as String? ?? '';
    final source = json['source'] as String? ?? '';
    final language = json['language'] as String? ?? 'en';

    return GuardianRetrievedEvidence(
      knowledgeId: knowledgeId is int ? knowledgeId : int.tryParse('$knowledgeId') ?? 0,
      title: title,
      category: category,
      similarityScore: similarityScore,
      pattern: pattern,
      description: description,
      indicators: indicators,
      safeAction: safeAction,
      source: source,
      language: language,
    );
  }
}

@immutable
class GuardianLiveAnalysisResult {
  const GuardianLiveAnalysisResult({
    required this.riskScore,
    required this.riskLevel,
    required this.classification,
    required this.scamCategory,
    required this.detectedIndicators,
    required this.reasoning,
    required this.supportingEvidence,
    required this.mlProbability,
    required this.llmConfidence,
    required this.safeAction,
    required this.safeActions,
    required this.timestamp,
    required this.sessionId,
    required this.language,
    required this.evidenceStatus,
    required this.processingStatus,
    required this.modelVersion,
    required this.ragVersion,
    required this.timingsMs,
  });

  final int riskScore;
  final String riskLevel;
  final String classification;
  final String scamCategory;
  final List<String> detectedIndicators;
  final String reasoning;
  final List<GuardianRetrievedEvidence> supportingEvidence;
  final double mlProbability;
  final double? llmConfidence;
  final String safeAction;
  final Map<String, dynamic>? safeActions;
  final DateTime timestamp;
  final String sessionId;
  final String language;
  final String evidenceStatus;
  final String processingStatus;
  final String modelVersion;
  final String ragVersion;
  final Map<String, double?> timingsMs;

  factory GuardianLiveAnalysisResult.fromJson(Map<String, dynamic> json) {
    final riskScore = json['risk_score'] as int? ?? 0;
    final riskLevel = json['risk_level'] as String? ?? 'LOW';
    final classification = json['classification'] as String? ?? 'GENUINE';
    final scamCategory = json['scam_category'] as String? ?? 'General';
    final rawIndicators = json['detected_indicators'];
    final detectedIndicators = rawIndicators is List
        ? rawIndicators.whereType<String>().toList(growable: false)
        : const <String>[];
    final reasoning = json['reasoning'] as String? ?? '';
    final rawEvidence = json['supporting_evidence'];
    final supportingEvidence = rawEvidence is List
        ? rawEvidence
            .whereType<Map<String, dynamic>>()
            .map(GuardianRetrievedEvidence.fromJson)
            .toList(growable: false)
        : const <GuardianRetrievedEvidence>[];
    final mlProbability = (json['ml_probability'] as num?)?.toDouble() ?? 0.0;
    final llmConfidence = (json['llm_confidence'] as num?)?.toDouble();
    final safeAction = json['safe_action'] as String? ?? '';
    final safeActions = json['safe_actions'] as Map<String, dynamic>?;
    final timestamp = DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now();
    final sessionId = json['session_id'] as String? ?? '';
    final language = json['language'] as String? ?? 'en';
    final evidenceStatus = json['evidence_status'] as String? ?? 'NO_RELEVANT_MATCH';
    final processingStatus = json['processing_status'] as String? ?? 'COMPLETED';
    final modelVersion = json['model_version'] as String? ?? '';
    final ragVersion = json['rag_version'] as String? ?? '';
    final rawTimings = json['timings_ms'];
    final timingsMs = <String, double?>{};
    if (rawTimings is Map) {
      rawTimings.forEach((key, value) {
        if (key is String) {
          timingsMs[key] = (value as num?)?.toDouble();
        }
      });
    }

    return GuardianLiveAnalysisResult(
      riskScore: riskScore,
      riskLevel: riskLevel,
      classification: classification,
      scamCategory: scamCategory,
      detectedIndicators: detectedIndicators,
      reasoning: reasoning,
      supportingEvidence: supportingEvidence,
      mlProbability: mlProbability,
      llmConfidence: llmConfidence,
      safeAction: safeAction,
      safeActions: safeActions,
      timestamp: timestamp,
      sessionId: sessionId,
      language: language,
      evidenceStatus: evidenceStatus,
      processingStatus: processingStatus,
      modelVersion: modelVersion,
      ragVersion: ragVersion,
      timingsMs: timingsMs,
    );
  }
}

@immutable
class GuardianLiveAnalysisResponse {
  const GuardianLiveAnalysisResponse({
    required this.sessionId,
    required this.status,
    required this.message,
    required this.processedSequence,
    required this.windowId,
    required this.result,
  });

  final String sessionId;
  final String status;
  final String message;
  final int processedSequence;
  final String? windowId;
  final GuardianLiveAnalysisResult? result;

  factory GuardianLiveAnalysisResponse.fromJson(Map<String, dynamic> json) {
    final sessionId = json['session_id'] as String? ?? '';
    final status = json['status'] as String? ?? 'AI_WAITING_FOR_TRANSCRIPT';
    final message = json['message'] as String? ?? '';
    final processedSequence = json['processed_sequence'] as int? ?? 0;
    final windowId = json['window_id'] as String?;
    final rawResult = json['result'];
    final result = rawResult is Map<String, dynamic>
        ? GuardianLiveAnalysisResult.fromJson(rawResult)
        : null;

    return GuardianLiveAnalysisResponse(
      sessionId: sessionId,
      status: status,
      message: message,
      processedSequence: processedSequence,
      windowId: windowId,
      result: result,
    );
  }
}

@immutable
class GuardianLiveAnalysisSnapshot {
  const GuardianLiveAnalysisSnapshot({
    required this.state,
    required this.message,
    required this.result,
    required this.lastAnalyzedSequence,
    required this.isAnalyzing,
    this.activeSessionId,
    this.isCallEnded = false,
    this.lastAnalysisTime,
  });

  final String state;
  final String message;
  final GuardianLiveAnalysisResult? result;
  final int lastAnalyzedSequence;
  final bool isAnalyzing;
  final String? activeSessionId;
  final bool isCallEnded;
  final DateTime? lastAnalysisTime;
}

