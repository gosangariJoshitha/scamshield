import 'api_service.dart';

class AdminPage {
  const AdminPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
    this.summary = const <String, dynamic>{},
  });

  final List<Map<String, dynamic>> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final Map<String, dynamic> summary;

  factory AdminPage.fromResponse(dynamic response) {
    if (response is! Map<String, dynamic>) {
      throw const FormatException('The admin API returned an invalid page.');
    }
    final rows = response['items'];
    if (rows is! List) {
      throw const FormatException('The admin API page is missing its items.');
    }
    return AdminPage(
      items: rows.whereType<Map<String, dynamic>>().toList(growable: false),
      page: _intValue(response['page'], 1),
      pageSize: _intValue(response['page_size'], rows.length),
      total: _intValue(response['total'], rows.length),
      totalPages: _intValue(response['total_pages'], 1).clamp(1, 1000000),
      summary: response['summary'] is Map<String, dynamic>
          ? response['summary'] as Map<String, dynamic>
          : const <String, dynamic>{},
    );
  }
}

class AdminPortalService {
  AdminPortalService({required this.api, required this.tokenProvider});

  final ApiService api;
  final Future<String?> Function() tokenProvider;

  Future<Map<String, dynamic>> loadOverview() async =>
      _asMap(await _get('/admin/overview'));

  Future<AdminPage> loadReviewPage({
    int page = 1,
    int pageSize = 20,
    String search = '',
    String status = '',
    String priority = '',
    String riskLevel = '',
    String inputType = '',
  }) async => AdminPage.fromResponse(
    await _get(
      '/reviews/admin/list',
      query: _query(
        page: page,
        pageSize: pageSize,
        search: search,
        values: {
          'review_status': status,
          'priority': priority,
          'risk_level': riskLevel,
          'input_type': inputType,
        },
      ),
    ),
  );

  Future<List<Map<String, dynamic>>> loadReviews() async =>
      (await loadReviewPage()).items;

  Future<Map<String, dynamic>> loadReviewDetail(int caseId) async =>
      _asMap(await _get('/reviews/admin/$caseId'));

  Future<Map<String, dynamic>> startReview(int caseId) async =>
      _asMap(await _post('/reviews/admin/$caseId/start', const {}));

  Future<Map<String, dynamic>> submitReviewDecision(
    int caseId, {
    required String decision,
    required String notes,
  }) async => _asMap(
    await _post('/reviews/admin/$caseId/decision', {
      'decision': decision,
      'notes': notes,
    }),
  );

  Future<AdminPage> loadCommunityPage({
    int page = 1,
    int pageSize = 20,
    String search = '',
    String status = '',
    String category = '',
  }) async => AdminPage.fromResponse(
    await _get(
      '/admin/community/reports',
      query: _query(
        page: page,
        pageSize: pageSize,
        search: search,
        values: {'status': status, 'category': category},
      ),
    ),
  );

  Future<List<Map<String, dynamic>>> loadCommunityReports() async =>
      (await loadCommunityPage()).items;

  Future<Map<String, dynamic>> actOnCommunityReport(
    int reportId, {
    required String action,
    String notes = '',
  }) async => _asMap(
    await _post('/admin/community/reports/$reportId/action', {
      'action': action,
      'notes': notes,
    }),
  );

  Future<AdminPage> loadKnowledgePage({
    int page = 1,
    int pageSize = 20,
    String search = '',
    String status = '',
    String category = '',
  }) async => AdminPage.fromResponse(
    await _get(
      '/admin/knowledge',
      query: _query(
        page: page,
        pageSize: pageSize,
        search: search,
        values: {'status': status, 'category': category},
      ),
    ),
  );

  Future<List<Map<String, dynamic>>> loadKnowledgeBase() async =>
      (await loadKnowledgePage()).items;

  Future<Map<String, dynamic>> createKnowledge(
    Map<String, dynamic> payload,
  ) async => _asMap(await _post('/admin/knowledge', payload));

  Future<Map<String, dynamic>> updateKnowledge(
    int entryId,
    Map<String, dynamic> payload,
  ) async => _asMap(await _patch('/admin/knowledge/$entryId', payload));

  Future<Map<String, dynamic>> approveKnowledge(int entryId) async =>
      _asMap(await _patch('/admin/knowledge/$entryId/approve', const {}));

  Future<Map<String, dynamic>> archiveKnowledge(int entryId) async =>
      _asMap(await _patch('/admin/knowledge/$entryId/archive', const {}));

  Future<Map<String, dynamic>> reindexKnowledge(int entryId) async =>
      _asMap(await _post('/admin/knowledge/$entryId/reindex', const {}));

  Future<Map<String, dynamic>> deleteKnowledge(int entryId) async =>
      _asMap(await _delete('/admin/knowledge/$entryId'));

  Future<AdminPage> loadUsersPage({
    int page = 1,
    int pageSize = 20,
    String search = '',
    String role = '',
    String status = '',
  }) async => AdminPage.fromResponse(
    await _get(
      '/admin/users',
      query: _query(
        page: page,
        pageSize: pageSize,
        search: search,
        values: {'role': role, 'status': status},
      ),
    ),
  );

  Future<List<Map<String, dynamic>>> loadUsers() async =>
      (await loadUsersPage()).items;

  Future<Map<String, dynamic>> loadUserDetail(int userId) async =>
      _asMap(await _get('/admin/users/$userId'));

  Future<Map<String, dynamic>> updateUserStatus(
    int userId, {
    required bool isActive,
  }) async => _asMap(
    await _patch('/admin/users/$userId/status', {'is_active': isActive}),
  );

  Future<Map<String, dynamic>> loadMonitoring() async =>
      _asMap(await _get('/admin/health'));

  Future<AdminPage> loadAuditPage({int page = 1, int pageSize = 20}) async =>
      AdminPage.fromResponse(
        await _get(
          '/admin/audit',
          query: _query(page: page, pageSize: pageSize),
        ),
      );

  Future<dynamic> _get(String path, {Map<String, String>? query}) async {
    final token = await _requiredToken();
    final queryString = query == null || query.isEmpty
        ? ''
        : '?${Uri(queryParameters: query).query}';
    return api.get('$path$queryString', token: token);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async =>
      api.postJson(path, body, token: await _requiredToken());

  Future<dynamic> _patch(String path, Map<String, dynamic> body) async =>
      api.patchJson(path, body, token: await _requiredToken());

  Future<dynamic> _delete(String path) async =>
      api.delete(path, token: await _requiredToken());

  Future<String> _requiredToken() async {
    final token = await tokenProvider();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Your admin session has expired.',
        statusCode: 401,
      );
    }
    return token;
  }

  Map<String, String> _query({
    required int page,
    required int pageSize,
    String search = '',
    Map<String, String> values = const {},
  }) {
    final query = <String, String>{
      'skip': '${(page - 1).clamp(0, 1000000) * pageSize}',
      'limit': '$pageSize',
    };
    if (search.trim().isNotEmpty) query['search'] = search.trim();
    for (final entry in values.entries) {
      if (entry.value.trim().isNotEmpty) query[entry.key] = entry.value.trim();
    }
    return query;
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  throw const FormatException('The admin API returned an invalid response.');
}

int _intValue(dynamic value, int fallback) =>
    value is num ? value.toInt() : fallback;

String adminValue(Object? value) {
  if (value == null) return 'Not reported';
  if (value is bool) return value ? 'Active' : 'Inactive';
  if (value is DateTime) return value.toLocal().toString();
  if (value is Map || value is List) return value.toString();
  return value.toString();
}
