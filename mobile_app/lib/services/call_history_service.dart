import '../models/call_history_models.dart';
import 'api_service.dart';

class CallHistoryService {
  CallHistoryService({
    required this.api,
    required this.tokenProvider,
  });

  final ApiService api;
  final Future<String?> Function() tokenProvider;

  final Set<String> _finalizedSessions = <String>{};

  bool isSessionFinalized(String sessionId) => _finalizedSessions.contains(sessionId);

  Future<CallHistoryDetail> finalizeCallSession(CallFinalizePayload payload) async {
    final token = await _requireToken();
    final response = await api.postJson(
      '/calls/finalize',
      payload.toJson(),
      token: token,
    );
    _finalizedSessions.add(payload.sessionId);
    return CallHistoryDetail.fromJson(_asObject(response, 'Call finalize'));
  }

  Future<CallHistoryListResponse> loadCallHistory({
    String? riskLevel,
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _requireToken();
    var path = '/calls/history?page=$page&limit=$limit';
    if (riskLevel != null &&
        riskLevel.trim().isNotEmpty &&
        riskLevel.toUpperCase() != 'ALL') {
      path += '&risk_level=${Uri.encodeComponent(riskLevel.trim().toUpperCase())}';
    }
    final response = await api.get(path, token: token);
    return CallHistoryListResponse.fromJson(_asObject(response, 'Call history'));
  }

  Future<CallHistoryDetail> getCallSummary(String sessionId) async {
    final token = await _requireToken();
    final response = await api.get('/calls/$sessionId', token: token);
    return CallHistoryDetail.fromJson(_asObject(response, 'Call summary'));
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
    if (value is Map) return Map<String, dynamic>.from(value);
    throw ApiException('$responseName returned an invalid response.');
  }
}
