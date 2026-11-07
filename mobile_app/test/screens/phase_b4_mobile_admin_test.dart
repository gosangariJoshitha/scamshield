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
  fullName: 'Super Admin',
  email: 'admin@scamshield.test',
  role: 'admin',
  isActive: true,
  emailVerified: true,
  twoFactorEnabled: true,
);

Widget _portal({
  required User user,
  required AdminPortalService service,
  Future<void> Function()? onLogout,
  Future<void> Function()? onSessionExpired,
  bool isDarkMode = false,
  VoidCallback? onToggleTheme,
}) {
  return MaterialApp(
    home: AdminPortalScreen(
      user: user,
      adminService: service,
      onLogout: onLogout ?? () async {},
      onSessionExpired: onSessionExpired ?? () async {},
      isDarkMode: isDarkMode,
      onToggleTheme: onToggleTheme ?? () {},
    ),
  );
}

void main() {
  group('Phase B4 Mobile Admin Portal Functional Tests', () {
    testWidgets('enforces 4-tab bottom navigation and drawer-only secondary modules', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = AdminPortalService(
        api: ApiService(
          client: MockClient((request) async {
            if (request.url.path == '/api/admin/overview') {
              return http.Response(
                jsonEncode({
                  'period_days': 30,
                  'totalAnalyses': 42,
                  'scamsDetected': 12,
                  'highRisk': 5,
                  'pendingReviews': 2,
                  'communityReports': 8,
                  'verifiedKnowledge': 19,
                  'analysisActivity': [],
                  'recentReviews': [],
                  'recentAnalyses': [],
                }),
                200,
              );
            }
            if (request.url.path == '/api/admin/monitoring/health' ||
                request.url.path == '/api/admin/health') {
              return http.Response(
                jsonEncode({
                  'status': 'healthy',
                  'services': {
                    'api_gateway': {'status': 'healthy', 'latency_ms': 12},
                    'database': {'status': 'healthy', 'latency_ms': 5},
                  },
                }),
                200,
              );
            }
            if (request.url.path == '/api/admin/knowledge') {
              return http.Response(
                jsonEncode({
                  'items': [
                    {
                      'id': 101,
                      'title': 'Bank KYC Phishing',
                      'category': 'Phishing SMS',
                      'pattern': 'Urgent bank KYC update required',
                      'risk_level': 'HIGH',
                      'status': 'ACTIVE',
                    }
                  ],
                  'page': 1,
                  'page_size': 20,
                  'total': 1,
                  'total_pages': 1,
                }),
                200,
              );
            }
            return http.Response('{}', 200);
          }),
          baseUri: Uri.parse('https://api.example.test/api'),
        ),
        tokenProvider: () async => 'admin-jwt-token',
      );

      await tester.pumpWidget(_portal(user: _admin, service: service));
      await tester.pumpAndSettle();

      // 1. Verify 4 bottom navigation destinations exist
      final navBar = find.byType(NavigationBar);
      expect(navBar, findsOneWidget);
      expect(find.text('Overview'), findsWidgets);
      expect(find.text('Reviews'), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);

      // Verify secondary modules are NOT in bottom navigation destinations
      expect(find.descendant(of: navBar, matching: find.text('Knowledge Base')), findsNothing);
      expect(find.descendant(of: navBar, matching: find.text('User Management')), findsNothing);
      expect(find.descendant(of: navBar, matching: find.text('System Monitoring')), findsNothing);
      expect(find.descendant(of: navBar, matching: find.text('Audit Logs')), findsNothing);

      // 2. Open drawer and verify secondary modules are present
      final scaffold = tester.firstState<ScaffoldState>(find.byType(Scaffold));
      scaffold.openDrawer();
      await tester.pumpAndSettle();

      final drawer = find.byType(Drawer);
      expect(drawer, findsOneWidget);
      expect(find.descendant(of: drawer, matching: find.text('Knowledge Base')), findsOneWidget);
      expect(find.descendant(of: drawer, matching: find.text('User Management')), findsOneWidget);
      expect(find.descendant(of: drawer, matching: find.text('System Monitoring')), findsOneWidget);
      expect(find.descendant(of: drawer, matching: find.text('Audit Logs')), findsOneWidget);
      expect(find.descendant(of: drawer, matching: find.text('Analysis Management')), findsOneWidget);

      // Verify drawer does NOT duplicate bottom nav destinations
      expect(find.descendant(of: drawer, matching: find.text('Reviews')), findsNothing);
      expect(find.descendant(of: drawer, matching: find.text('Community')), findsNothing);

      // 3. Navigate to Knowledge Base from drawer
      await tester.tap(find.descendant(of: drawer, matching: find.text('Knowledge Base')));
      await tester.pumpAndSettle();

      expect(find.text('Knowledge Base'), findsWidgets);
      expect(find.textContaining('Urgent bank KYC update required'), findsOneWidget);

      // 4. Verify back navigation returns to Overview
      final backButton = find.byTooltip('Back to overview');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Command center'), findsOneWidget);
    });

    testWidgets('Analysis Management loads entries and opens 11-section details dialog', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = AdminPortalService(
        api: ApiService(
          client: MockClient((request) async {
            if (request.url.path == '/api/admin/overview') {
              return http.Response(
                jsonEncode({
                  'period_days': 30,
                  'totalAnalyses': 1,
                  'scamsDetected': 1,
                  'highRisk': 1,
                  'pendingReviews': 0,
                  'communityReports': 0,
                  'verifiedKnowledge': 0,
                }),
                200,
              );
            }
            if (request.url.path == '/api/admin/analyses') {
              return http.Response(
                jsonEncode({
                  'items': [
                    {
                      'id': 881,
                      'input_type': 'CALL_STREAM',
                      'classification': 'SCAM',
                      'risk_level': 'CRITICAL',
                      'risk_score': 0.94,
                      'category': 'Financial Extortion',
                      'source': 'Guardian Live Stream',
                      'created_at': '2026-11-01T10:00:00Z',
                      'user': 'victim@domain.com',
                      'latency_ms': 185,
                      'explanation': 'Immediate wire transfer demand impersonating police.',
                    }
                  ],
                  'page': 1,
                  'page_size': 20,
                  'total': 1,
                  'total_pages': 1,
                  'summary': {
                    'total_scams': 1,
                    'avg_latency_ms': 185,
                  },
                }),
                200,
              );
            }
            if (request.url.path == '/api/admin/analyses/881') {
              return http.Response(
                jsonEncode({
                  'id': 881,
                  'input_type': 'CALL_STREAM',
                  'classification': 'SCAM',
                  'risk_level': 'CRITICAL',
                  'risk_score': 0.94,
                  'category': 'Financial Extortion',
                  'source': 'Guardian Live Stream',
                  'created_at': '2026-11-01T10:00:00Z',
                  'user_id': 14,
                  'raw_content': 'Police department warrant. Send money immediately.',
                  'explanation': 'Immediate wire transfer demand impersonating police.',
                  'indicators': [
                    {'name': 'Urgency', 'severity': 'CRITICAL'},
                    {'name': 'Impersonation', 'severity': 'HIGH'},
                  ],
                  'rag_context': [
                    {'source': 'KB-402', 'pattern': 'Law enforcement impostor scam'},
                  ],
                  'latency_breakdown': {
                    'transcription_ms': 75,
                    'embedding_ms': 25,
                    'vector_search_ms': 15,
                    'llm_reasoning_ms': 70,
                  },
                  'linked_review': {
                    'id': 99,
                    'status': 'RESOLVED',
                    'priority': 'HIGH',
                    'decision': 'CONFIRMED_SCAM',
                  },
                }),
                200,
              );
            }
            return http.Response('{}', 200);
          }),
          baseUri: Uri.parse('https://api.example.test/api'),
        ),
        tokenProvider: () async => 'admin-jwt-token',
      );

      await tester.pumpWidget(_portal(user: _admin, service: service));
      await tester.pumpAndSettle();

      // Open drawer -> Analysis Management
      tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Analysis Management'));
      await tester.pumpAndSettle();

      expect(find.text('Analysis Management'), findsWidgets);
      expect(find.textContaining('Financial Extortion'), findsOneWidget);
      expect(find.textContaining('CALL_STREAM'), findsOneWidget);

      // Tap to inspect analysis details dialog
      await tester.tap(find.textContaining('Financial Extortion'));
      await tester.pumpAndSettle();

      // Verify analysis modal components
      expect(find.text('Analysis #881'), findsOneWidget);
      expect(find.text('ORIGINAL CONTENT'), findsOneWidget);
      expect(find.text('LINKED HUMAN REVIEW'), findsOneWidget);
      expect(find.textContaining('Classification: SCAM'), findsOneWidget);

      // Close dialog via close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });

    testWidgets('System Monitoring renders 9 service cards and performance latencies', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = AdminPortalService(
        api: ApiService(
          client: MockClient((request) async {
            if (request.url.path == '/api/admin/overview' ||
                request.url.path == '/api/admin/monitoring') {
              return http.Response(
                jsonEncode({
                  'api': 'Healthy',
                  'database': 'Healthy',
                  'ml_model': 'Healthy',
                  'chromadb': 'HEALTHY',
                  'embedding': 'Configured',
                  'llm': 'Configured',
                  'ocr': 'Configured',
                  'speech_to_text': 'Configured',
                  'jira': 'Configured',
                }),
                200,
              );
            }
            return http.Response('{}', 200);
          }),
          baseUri: Uri.parse('https://api.example.test/api'),
        ),
        tokenProvider: () async => 'admin-jwt-token',
      );

      await tester.pumpWidget(_portal(user: _admin, service: service));
      await tester.pumpAndSettle();

      // Open drawer -> System Monitoring
      tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();
      await tester.tap(find.text('System Monitoring'));
      await tester.pumpAndSettle();

      expect(find.text('System Monitoring & Telemetry'), findsOneWidget);
      expect(find.text('FastAPI Backend'), findsOneWidget);
      expect(find.text('PostgreSQL Database'), findsOneWidget);
      expect(find.text('ChromaDB Vectors'), findsOneWidget);
      expect(find.text('Speech-to-Text (Whisper)'), findsOneWidget);
      expect(find.text('Atlassian Jira'), findsOneWidget);

      // Scroll down to latency and evaluation sections
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Pipeline Latency Breakdown'), findsOneWidget);
      expect(find.text('AI Model Benchmark Evaluation'), findsOneWidget);
    });

    testWidgets('More & Settings tab provides profile, theme toggle and audit preview', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var toggled = false;
      final service = AdminPortalService(
        api: ApiService(
          client: MockClient((request) async {
            if (request.url.path == '/api/admin/audit') {
              return http.Response(
                jsonEncode({
                  'items': [
                    {
                      'id': 1,
                      'timestamp': '2026-11-01T09:00:00Z',
                      'actor_email': 'admin@scamshield.test',
                      'action': 'USER_ROLE_UPDATED',
                      'resource_type': 'USER',
                      'resource_id': '12',
                      'status': 'SUCCESS',
                    }
                  ],
                  'page': 1,
                  'page_size': 5,
                  'total': 1,
                  'total_pages': 1,
                }),
                200,
              );
            }
            return http.Response('{"period_days":30,"totalAnalyses":0,"scamsDetected":0,"highRisk":0,"pendingReviews":0,"communityReports":0,"verifiedKnowledge":0}', 200);
          }),
          baseUri: Uri.parse('https://api.example.test/api'),
        ),
        tokenProvider: () async => 'admin-jwt-token',
      );

      await tester.pumpWidget(_portal(
        user: _admin,
        service: service,
        onToggleTheme: () => toggled = true,
      ));
      await tester.pumpAndSettle();

      // Navigate to 'More' bottom tab
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      expect(find.text('Super Admin'), findsOneWidget);
      expect(find.text('admin@scamshield.test'), findsOneWidget);
      expect(find.text('WORKSPACE MODULES'), findsOneWidget);

      expect(find.text('Dark Mode Appearance'), findsOneWidget);

      // Tap Dark Mode toggle switch
      await tester.tap(find.byType(SwitchListTile));
      expect(toggled, isTrue);

      expect(find.text('Recent Audit Activity'), findsOneWidget);
      expect(find.text('USER_ROLE_UPDATED'), findsOneWidget);
    });
  });
}
