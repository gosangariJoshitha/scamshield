import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/models/user.dart';
import 'package:scamshield_guardian/screens/login/admin_portal_screen.dart';
import 'package:scamshield_guardian/services/admin_portal_service.dart';
import 'package:scamshield_guardian/services/api_service.dart';

const _admin = User(
  id: 7,
  fullName: 'Admin User',
  email: 'admin@example.com',
  role: 'admin',
  isActive: true,
  emailVerified: true,
  twoFactorEnabled: true,
);

const _regularUser = User(
  id: 9,
  fullName: 'Regular User',
  email: 'user@example.com',
  role: 'user',
  isActive: true,
  emailVerified: true,
  twoFactorEnabled: false,
);

Widget _portal({
  required User user,
  required AdminPortalService service,
  Future<void> Function()? onLogout,
  Future<void> Function()? onSessionExpired,
}) {
  return MaterialApp(
    home: AdminPortalScreen(
      user: user,
      adminService: service,
      onLogout: onLogout ?? () async {},
      onSessionExpired: onSessionExpired ?? () async {},
      isDarkMode: false,
      onToggleTheme: () {},
    ),
  );
}

void main() {
  testWidgets('rejects non-admin accounts before loading admin data', (
    tester,
  ) async {
    var requestCount = 0;
    final service = AdminPortalService(
      api: ApiService(
        client: MockClient((_) async {
          requestCount++;
          return http.Response('{}', 200);
        }),
        baseUri: Uri.parse('https://api.example.test/api'),
      ),
      tokenProvider: () async => 'user-token',
    );

    await tester.pumpWidget(_portal(user: _regularUser, service: service));

    expect(find.text('Administrator access is required.'), findsOneWidget);
    expect(requestCount, 0);
  });

  testWidgets('shows live dashboard metrics and navigates to review queue', (
    tester,
  ) async {
    final paths = <String>[];
    final service = AdminPortalService(
      api: ApiService(
        client: MockClient((request) async {
          paths.add(request.url.path);
          if (request.url.path == '/api/admin/overview') {
            return http.Response(
              jsonEncode({
                'period_days': 30,
                'totalAnalyses': 14,
                'scamsDetected': 4,
                'highRisk': 2,
                'pendingReviews': 1,
                'communityReports': 3,
                'verifiedKnowledge': 8,
                'analysisActivity': [
                  {'date': '2026-10-06', 'count': 5},
                ],
                'recentReviews': [],
                'recentAnalyses': [],
              }),
              200,
            );
          }
          if (request.url.path == '/api/reviews/admin/list') {
            return http.Response(
              '{"items":[{"id":33,"status":"PENDING","priority":"HIGH",'
              '"risk_level":"HIGH","reporter":"member@example.com"}]}',
              200,
            );
          }
          fail('Unexpected request ${request.url.path}');
        }),
        baseUri: Uri.parse('https://api.example.test/api'),
      ),
      tokenProvider: () async => 'admin-token',
    );
    await tester.pumpWidget(_portal(user: _admin, service: service));
    await tester.pumpAndSettle();

    expect(find.text('Command center'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(find.text('Analyses'), findsOneWidget);
    expect(paths, contains('/api/admin/overview'));

    await tester.tap(find.text('Reviews'));
    await tester.pumpAndSettle();

    expect(find.text('Human Review'), findsNWidgets(2));
    expect(find.text('Record 33'), findsOneWidget);
    expect(find.textContaining('PENDING'), findsOneWidget);
    expect(paths, contains('/api/reviews/admin/list'));
  });

  testWidgets('review case records a confirmed decision after confirmation', (
    tester,
  ) async {
    var decisionWasSubmitted = false;
    final service = AdminPortalService(
      api: ApiService(
        client: MockClient((request) async {
          switch (request.url.path) {
            case '/api/admin/overview':
              return http.Response(
                '{"period_days":30,"totalAnalyses":0,"scamsDetected":0,'
                '"highRisk":0,"pendingReviews":1,"communityReports":0,'
                '"verifiedKnowledge":0,"analysisActivity":[],"recentReviews":[]}',
                200,
              );
            case '/api/reviews/admin/list':
              return http.Response(
                '{"items":[{"id":33,"status":"PENDING","priority":"HIGH",'
                '"risk_level":"HIGH","reporter":"member@example.com"}],'
                '"total":1,"page":1,"page_size":20,"total_pages":1}',
                200,
              );
            case '/api/reviews/admin/33/start':
              expect(request.method, 'POST');
              return http.Response(
                '{"success":true,"status":"IN_REVIEW"}',
                200,
              );
            case '/api/reviews/admin/33':
              return http.Response(
                '{"id":33,"status":"IN_REVIEW","priority":"HIGH",'
                '"analysis":{"original_text":"Suspicious payment message",'
                '"risk_level":"HIGH","classification":"SCAM",'
                '"explanation":"Requests an urgent payment."},'
                '"events":[]}',
                200,
              );
            case '/api/reviews/admin/33/decision':
              expect(request.method, 'POST');
              expect(jsonDecode(request.body), {
                'decision': 'CONFIRMED_SCAM',
                'notes': '',
              });
              decisionWasSubmitted = true;
              return http.Response('{"success":true,"status":"VERIFIED"}', 200);
            default:
              fail('Unexpected request ${request.method} ${request.url}');
          }
        }),
        baseUri: Uri.parse('https://api.example.test/api'),
      ),
      tokenProvider: () async => 'admin-token',
    );

    await tester.pumpWidget(_portal(user: _admin, service: service));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reviews'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review case'));
    await tester.pumpAndSettle();

    expect(find.text('Suspicious payment message'), findsOneWidget);
    await tester.tap(find.text('Submit decision'));
    await tester.pumpAndSettle();
    expect(find.text('Submit review decision?'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(decisionWasSubmitted, isTrue);
    expect(find.text('Review decision recorded.'), findsOneWidget);
  });

  testWidgets('admin portal adapts to a narrow phone viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = AdminPortalService(
      api: ApiService(
        client: MockClient(
          (_) async => http.Response(
            '{"period_days":30,"totalAnalyses":0,"scamsDetected":0,'
            '"highRisk":0,"pendingReviews":0,"communityReports":0,'
            '"verifiedKnowledge":0,"analysisActivity":[],"recentReviews":[]}',
            200,
          ),
        ),
        baseUri: Uri.parse('https://api.example.test/api'),
      ),
      tokenProvider: () async => 'admin-token',
    );

    await tester.pumpWidget(_portal(user: _admin, service: service));
    await tester.pumpAndSettle();

    expect(find.text('Command center'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
