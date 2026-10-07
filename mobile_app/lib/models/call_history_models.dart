import 'package:flutter/material.dart';

class CallHistoryItem {
  const CallHistoryItem({
    required this.id,
    required this.sessionId,
    required this.endedAt,
    required this.durationSeconds,
    required this.finalRiskScore,
    required this.finalRiskLevel,
    required this.classification,
    required this.scamCategory,
    required this.analysisStatus,
    required this.transcriptionStatus,
    required this.audioStatus,
    this.startedAt,
  });

  final int id;
  final String sessionId;
  final DateTime? startedAt;
  final DateTime endedAt;
  final int durationSeconds;
  final int finalRiskScore;
  final String finalRiskLevel;
  final String classification;
  final String scamCategory;
  final String analysisStatus;
  final String transcriptionStatus;
  final String audioStatus;

  bool get isScam =>
      classification.toUpperCase() == 'SCAM' ||
      finalRiskLevel.toUpperCase() == 'HIGH' ||
      finalRiskLevel.toUpperCase() == 'CRITICAL';

  String get formattedDuration {
    final m = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String formattedEndedAt({DateTime? relativeTo}) {
    final local = endedAt.toLocal();
    final now = relativeTo ?? DateTime.now();
    final isToday = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final datePrefix = isToday ? 'Today' : '${local.day} ${_monthName(local.month)}';
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '$datePrefix, $hour:$minute $suffix';
  }

  Color riskColor(ColorScheme colors) {
    return switch (finalRiskLevel.toUpperCase()) {
      'CRITICAL' => const Color(0xFFB71C1C),
      'HIGH' => colors.error,
      'MEDIUM' => const Color(0xFFC27500),
      _ => const Color(0xFF14804A),
    };
  }

  factory CallHistoryItem.fromJson(Map<String, dynamic> json) {
    return CallHistoryItem(
      id: json['id'] as int? ?? 0,
      sessionId: json['session_id'] as String? ?? '',
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'].toString())
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'].toString())
          : DateTime.now(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      finalRiskScore: (json['final_risk_score'] as num?)?.toInt() ?? 0,
      finalRiskLevel: (json['final_risk_level'] as String?)?.toUpperCase() ?? 'LOW',
      classification: (json['classification'] as String?) ?? 'GENUINE',
      scamCategory: (json['scam_category'] as String?) ?? 'General',
      analysisStatus: (json['analysis_status'] as String?) ?? 'COMPLETED',
      transcriptionStatus: (json['transcription_status'] as String?) ?? 'COMPLETED',
      audioStatus: (json['audio_status'] as String?) ?? 'AVAILABLE',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_id': sessionId,
        'started_at': startedAt?.toIso8601String(),
        'ended_at': endedAt.toIso8601String(),
        'duration_seconds': durationSeconds,
        'final_risk_score': finalRiskScore,
        'final_risk_level': finalRiskLevel,
        'classification': classification,
        'scam_category': scamCategory,
        'analysis_status': analysisStatus,
        'transcription_status': transcriptionStatus,
        'audio_status': audioStatus,
      };

  static String _monthName(int month) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][(month - 1).clamp(0, 11)];
}

class CallHistoryDetail extends CallHistoryItem {
  const CallHistoryDetail({
    required super.id,
    required super.sessionId,
    required super.endedAt,
    required super.durationSeconds,
    required super.finalRiskScore,
    required super.finalRiskLevel,
    required super.classification,
    required super.scamCategory,
    required super.analysisStatus,
    required super.transcriptionStatus,
    required super.audioStatus,
    required this.guardianEnabled,
    required this.guardianStatus,
    super.startedAt,
    this.riskReasoning,
    this.safeAction,
    this.detectedIndicators = const [],
    this.supportingEvidence = const [],
    this.protectionActions = const [],
    this.createdAt,
  });

  final bool guardianEnabled;
  final String guardianStatus;
  final String? riskReasoning;
  final String? safeAction;
  final List<String> detectedIndicators;
  final List<Map<String, dynamic>> supportingEvidence;
  final List<Map<String, dynamic>> protectionActions;
  final DateTime? createdAt;

  factory CallHistoryDetail.fromJson(Map<String, dynamic> json) {
    final indicatorsRaw = json['detected_indicators'];
    final List<String> indicators = [];
    if (indicatorsRaw is List) {
      for (final item in indicatorsRaw) {
        if (item != null) indicators.add(item.toString());
      }
    }

    final evidenceRaw = json['supporting_evidence'];
    final List<Map<String, dynamic>> evidence = [];
    if (evidenceRaw is List) {
      for (final item in evidenceRaw) {
        if (item is Map<String, dynamic>) {
          evidence.add(item);
        } else if (item is Map) {
          evidence.add(Map<String, dynamic>.from(item));
        }
      }
    }

    final actionsRaw = json['protection_actions'];
    final List<Map<String, dynamic>> actions = [];
    if (actionsRaw is List) {
      for (final item in actionsRaw) {
        if (item is Map<String, dynamic>) {
          actions.add(item);
        } else if (item is Map) {
          actions.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return CallHistoryDetail(
      id: json['id'] as int? ?? 0,
      sessionId: json['session_id'] as String? ?? '',
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'].toString())
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'].toString())
          : DateTime.now(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      guardianEnabled: json['guardian_enabled'] as bool? ?? true,
      guardianStatus: (json['guardian_status'] as String?) ?? 'ENABLED',
      finalRiskScore: (json['final_risk_score'] as num?)?.toInt() ?? 0,
      finalRiskLevel: (json['final_risk_level'] as String?)?.toUpperCase() ?? 'LOW',
      classification: (json['classification'] as String?) ?? 'GENUINE',
      scamCategory: (json['scam_category'] as String?) ?? 'General',
      riskReasoning: json['risk_reasoning'] as String?,
      safeAction: json['safe_action'] as String?,
      detectedIndicators: indicators,
      supportingEvidence: evidence,
      protectionActions: actions,
      analysisStatus: (json['analysis_status'] as String?) ?? 'COMPLETED',
      transcriptionStatus: (json['transcription_status'] as String?) ?? 'COMPLETED',
      audioStatus: (json['audio_status'] as String?) ?? 'AVAILABLE',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final base = super.toJson();
    base.addAll({
      'guardian_enabled': guardianEnabled,
      'guardian_status': guardianStatus,
      'risk_reasoning': riskReasoning,
      'safe_action': safeAction,
      'detected_indicators': detectedIndicators,
      'supporting_evidence': supportingEvidence,
      'protection_actions': protectionActions,
      'created_at': createdAt?.toIso8601String(),
    });
    return base;
  }
}

class CallHistoryListResponse {
  const CallHistoryListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasNext,
  });

  final List<CallHistoryItem> items;
  final int total;
  final int page;
  final int limit;
  final bool hasNext;

  factory CallHistoryListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return CallHistoryListResponse(
      items: rawItems
          .whereType<Map>()
          .map((item) => CallHistoryItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      hasNext: json['has_next'] as bool? ?? false,
    );
  }
}

class CallFinalizePayload {
  const CallFinalizePayload({
    required this.sessionId,
    required this.durationSeconds,
    required this.finalRiskScore,
    required this.finalRiskLevel,
    required this.classification,
    required this.scamCategory,
    this.startedAt,
    this.endedAt,
    this.guardianEnabled = true,
    this.guardianStatus = 'ENABLED',
    this.riskReasoning,
    this.safeAction,
    this.detectedIndicators,
    this.supportingEvidence,
    this.protectionActions,
    this.analysisStatus = 'COMPLETED',
    this.transcriptionStatus = 'COMPLETED',
    this.audioStatus = 'AVAILABLE',
  });

  final String sessionId;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final bool guardianEnabled;
  final String guardianStatus;
  final int finalRiskScore;
  final String finalRiskLevel;
  final String classification;
  final String scamCategory;
  final String? riskReasoning;
  final String? safeAction;
  final List<String>? detectedIndicators;
  final List<Map<String, dynamic>>? supportingEvidence;
  final List<Map<String, dynamic>>? protectionActions;
  final String analysisStatus;
  final String transcriptionStatus;
  final String audioStatus;

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'started_at': startedAt?.toUtc().toIso8601String(),
        'ended_at': endedAt?.toUtc().toIso8601String(),
        'duration_seconds': durationSeconds,
        'guardian_enabled': guardianEnabled,
        'guardian_status': guardianStatus,
        'final_risk_score': finalRiskScore,
        'final_risk_level': finalRiskLevel,
        'classification': classification,
        'scam_category': scamCategory,
        'risk_reasoning': riskReasoning,
        'safe_action': safeAction,
        'detected_indicators': detectedIndicators,
        'supporting_evidence': supportingEvidence,
        'protection_actions': protectionActions,
        'analysis_status': analysisStatus,
        'transcription_status': transcriptionStatus,
        'audio_status': audioStatus,
      };
}
