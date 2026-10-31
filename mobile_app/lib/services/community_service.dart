import '../models/community_report_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class CommunityService {
  CommunityService({
    required this.api,
    required this.authService,
  });

  final ApiService api;
  final AuthService authService;

  Future<List<CommunityReportModel>> getCommunityReports() async {
    final token = await authService.getStoredToken();
    if (token == null) {
      throw const ApiException('Authentication required to view community reports.');
    }

    final response = await api.get('/community/reports', token: token);
    if (response is! List<dynamic>) {
      throw const ApiException('Invalid response when fetching community reports.');
    }

    return response
        .whereType<Map<String, dynamic>>()
        .map(CommunityReportModel.fromJson)
        .toList();
  }

  Future<CommunityReportModel> submitReport({
    required String content,
    required String category,
    String? description,
    String? evidence,
    int? analysisId,
  }) async {
    final token = await authService.getStoredToken();
    if (token == null) {
      throw const ApiException('Authentication required to submit report.');
    }

    final body = <String, dynamic>{
      'content': content.trim(),
      'category': category.trim(),
    };
    if (description != null && description.trim().isNotEmpty) {
      body['description'] = description.trim();
    }
    if (evidence != null && evidence.trim().isNotEmpty) {
      body['evidence'] = evidence.trim();
    }
    if (analysisId != null) {
      body['analysis_id'] = analysisId;
    }

    final response = await api.postJson('/community/reports', body, token: token);
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid response when submitting report.');
    }

    return CommunityReportModel.fromJson(response);
  }
}
