import '../models/analysis_record.dart';
import 'api_service.dart';

class DashboardStats {
  const DashboardStats({
    required this.totalAnalyses,
    required this.scamsDetected,
    required this.safeMessages,
    required this.highRisk,
  });

  final int totalAnalyses;
  final int scamsDetected;
  final int safeMessages;
  final int highRisk;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalAnalyses: _requiredInt(json, 'total_analyses'),
      scamsDetected: _requiredInt(json, 'scams_detected'),
      safeMessages: _requiredInt(json, 'safe_messages'),
      highRisk: _requiredInt(json, 'high_risk'),
    );
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int && value >= 0) return value;
    throw FormatException('Dashboard response is missing $key.');
  }
}

class DashboardData {
  const DashboardData({required this.stats, required this.recentAnalyses});

  final DashboardStats stats;
  final List<AnalysisRecord> recentAnalyses;
}

class AnalysisService {
  const AnalysisService({required this.api, required this.tokenProvider});

  final ApiService api;
  final Future<String?> Function() tokenProvider;

  Future<DashboardData> loadDashboard() async {
    final token = await _requireToken();
    final responses = await Future.wait([
      api.get('/analysis/dashboard', token: token),
      api.get('/analysis/history', token: token),
    ]);
    final statsJson = _asObject(responses[0], 'Dashboard');
    final historyJson = responses[1];
    if (historyJson is! List) {
      throw const ApiException(
        'Analysis history returned an invalid response.',
      );
    }
    final history = historyJson
        .map(
          (item) =>
              AnalysisRecord.fromJson(_asObject(item, 'Analysis history')),
        )
        .toList(growable: false);
    return DashboardData(
      stats: DashboardStats.fromJson(statsJson),
      recentAnalyses: history.take(5).toList(growable: false),
    );
  }

  Future<List<AnalysisRecord>> loadHistory() async {
    final token = await _requireToken();
    final response = await api.get('/analysis/history', token: token);
    if (response is! List) {
      throw const ApiException(
        'Analysis history returned an invalid response.',
      );
    }
    return response
        .map(
          (item) =>
              AnalysisRecord.fromJson(_asObject(item, 'Analysis history')),
        )
        .toList(growable: false);
  }

  Future<AnalysisRecord> analyzeText(String content) async {
    final token = await _requireToken();
    final response = await api.postJson('/analysis/text', {
      'content': content,
    }, token: token);
    return AnalysisRecord.fromJson(_asObject(response, 'Text analysis'));
  }

  Future<AnalysisRecord> analyzeFile({
    required String type,
    required String filename,
    required List<int> bytes,
  }) async {
    final token = await _requireToken();
    final response = await api.postMultipart(
      path: '/analysis/$type',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      token: token,
    );
    return AnalysisRecord.fromJson(_asObject(response, 'File analysis'));
  }

  Future<String> _requireToken() async {
    final token = await tokenProvider();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Your session has expired. Please sign in again.',
        statusCode: 401,
      );
    }
    return token;
  }

  Map<String, dynamic> _asObject(dynamic value, String responseName) {
    if (value is Map<String, dynamic>) return value;
    throw ApiException('$responseName returned an invalid response.');
  }
}
