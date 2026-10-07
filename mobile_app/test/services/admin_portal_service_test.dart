import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/services/admin_portal_service.dart';
import 'package:scamshield_guardian/services/api_service.dart';

void main() {
  test('loads paginated reviews with the selected filters', () async {
    final service = AdminPortalService(
      api: ApiService(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/reviews/admin/list');
          expect(request.url.queryParameters, {
            'skip': '10',
            'limit': '10',
            'search': 'case 8',
            'review_status': 'IN_REVIEW',
            'risk_level': 'HIGH',
          });
          expect(request.headers['authorization'], 'Bearer admin-token');
          return http.Response(
            jsonEncode({
              'items': [
                {'id': 8, 'status': 'IN_REVIEW'},
              ],
              'total': 13,
              'page': 2,
              'page_size': 10,
              'total_pages': 2,
            }),
            200,
          );
        }),
        baseUri: Uri.parse('https://api.example.test/api'),
      ),
      tokenProvider: () async => 'admin-token',
    );

    final result = await service.loadReviewPage(
      page: 2,
      pageSize: 10,
      search: 'case 8',
      status: 'IN_REVIEW',
      riskLevel: 'HIGH',
    );

    expect(result.items.single['id'], 8);
    expect(result.total, 13);
    expect(result.page, 2);
    expect(result.totalPages, 2);
  });

  test('monitoring reads the real admin health route', () async {
    final service = AdminPortalService(
      api: ApiService(
        client: MockClient((request) async {
          expect(request.url.path, '/api/admin/health');
          return http.Response('{"database":{"status":"up"}}', 200);
        }),
        baseUri: Uri.parse('https://api.example.test/api'),
      ),
      tokenProvider: () async => 'admin-token',
    );

    expect((await service.loadMonitoring())['database']['status'], 'up');
  });

  test('community moderation sends the selected action and notes', () async {
    final service = AdminPortalService(
      api: ApiService(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/admin/community/reports/12/action');
          expect(jsonDecode(request.body), {
            'action': 'ESCALATE',
            'notes': 'Needs specialist review',
          });
          return http.Response('{"status":"success"}', 200);
        }),
        baseUri: Uri.parse('https://api.example.test/api'),
      ),
      tokenProvider: () async => 'admin-token',
    );

    expect(
      (await service.actOnCommunityReport(
        12,
        action: 'ESCALATE',
        notes: 'Needs specialist review',
      ))['status'],
      'success',
    );
  });

  test('knowledge and user mutations call the real write routes', () async {
    final requests = <String>[];
    final service = AdminPortalService(
      api: ApiService(
        client: MockClient((request) async {
          requests.add('${request.method} ${request.url.path}');
          if (request.url.path == '/api/admin/knowledge' &&
              request.method == 'POST') {
            expect(jsonDecode(request.body)['example'], 'sample message');
          }
          if (request.url.path == '/api/admin/users/5/status') {
            expect(jsonDecode(request.body), {'is_active': false});
          }
          return http.Response('{"status":"success","indexed":true}', 200);
        }),
        baseUri: Uri.parse('https://api.example.test/api'),
      ),
      tokenProvider: () async => 'admin-token',
    );

    await service.createKnowledge({
      'title': 'Test',
      'example': 'sample message',
    });
    await service.updateKnowledge(4, {'title': 'Updated'});
    await service.approveKnowledge(4);
    await service.reindexKnowledge(4);
    await service.archiveKnowledge(4);
    await service.updateUserStatus(5, isActive: false);
    await service.deleteKnowledge(4);

    expect(requests, [
      'POST /api/admin/knowledge',
      'PATCH /api/admin/knowledge/4',
      'PATCH /api/admin/knowledge/4/approve',
      'POST /api/admin/knowledge/4/reindex',
      'PATCH /api/admin/knowledge/4/archive',
      'PATCH /api/admin/users/5/status',
      'DELETE /api/admin/knowledge/4',
    ]);
  });
}
