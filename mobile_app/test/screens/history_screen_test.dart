import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/screens/history/history_screen.dart';
import 'package:scamshield_guardian/services/analysis_service.dart';
import 'package:scamshield_guardian/services/api_service.dart';
import 'package:scamshield_guardian/services/call_history_service.dart';

Map<String, dynamic> _mockCallItem({
  int id = 1,
  String sessionId = 'session-card-1',
  String riskLevel = 'HIGH',
  int riskScore = 78,
  String category = 'OTP Verification Scam',
}) => {
  'id': id,
  'session_id': sessionId,
  'started_at': '2026-10-07T10:00:00Z',
  'ended_at': '2026-10-07T10:04:37Z',
  'duration_seconds': 277,
  'final_risk_score': riskScore,
  'final_risk_level': riskLevel,
  'classification': 'SCAM',
  'scam_category': category,
  'analysis_status': 'COMPLETED',
  'transcription_status': 'COMPLETED',
  'audio_status': 'AVAILABLE',
};

Map<String, dynamic> _mockCallDetail({
  int id = 1,
  String sessionId = 'session-card-1',
}) => {
  'id': id,
  'session_id': sessionId,
  'started_at': '2026-10-07T10:00:00Z',
  'ended_at': '2026-10-07T10:04:37Z',
  'duration_seconds': 277,
  'guardian_enabled': true,
  'guardian_status': 'ENABLED',
  'final_risk_score': 78,
  'final_risk_level': 'HIGH',
  'classification': 'SCAM',
  'scam_category': 'OTP Verification Scam',
  'risk_reasoning': 'The caller requested an OTP.',
  'safe_action': 'Do not share OTP.',
  'detected_indicators': ['OTP request'],
  'supporting_evidence': [],
  'protection_actions': [],
  'analysis_status': 'COMPLETED',
  'transcription_status': 'COMPLETED',
  'audio_status': 'AVAILABLE',
};

void main() {
  testWidgets('HistoryScreen switches to Calls tab, displays filter chips and call items', (tester) async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/analysis/history')) {
        return http.Response(jsonEncode([]), 200);
      }
      if (request.url.path.endsWith('/calls/history')) {
        return http.Response(
          jsonEncode({
            'items': [
              _mockCallItem(id: 1, sessionId: 's1', riskLevel: 'HIGH', riskScore: 78),
              _mockCallItem(id: 2, sessionId: 's2', riskLevel: 'MEDIUM', riskScore: 48, category: 'Suspicious Request'),
            ],
            'total': 2,
            'page': 1,
            'limit': 20,
            'has_next': false,
          }),
          200,
        );
      }
      if (request.url.path.contains('/calls/s1')) {
        return http.Response(jsonEncode(_mockCallDetail(id: 1, sessionId: 's1')), 200);
      }
      return http.Response('Not found', 404);
    });

    final api = ApiService(client: client, baseUri: Uri.parse('https://api.example.test/api'));
    final analysisService = AnalysisService(api: api, tokenProvider: () async => 'token');
    final callHistoryService = CallHistoryService(api: api, tokenProvider: () async => 'token');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryScreen(
            analysisService: analysisService,
            callHistoryService: callHistoryService,
            onSessionExpired: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial Analysis tab
    expect(find.text('Analysis History'), findsOneWidget);
    expect(find.text('Analysis'), findsOneWidget);
    expect(find.text('Calls'), findsOneWidget);

    // Tap Calls tab
    await tester.tap(find.text('Calls'));
    await tester.pumpAndSettle();

    // Verify Calls tab header and filter chips
    expect(find.text('Call History'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Critical'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);

    // Verify Call items rendered
    expect(find.text('HIGH RISK'), findsOneWidget);
    expect(find.text('78/100'), findsOneWidget);
    expect(find.text('OTP Verification Scam'), findsOneWidget);

    expect(find.text('MEDIUM RISK'), findsOneWidget);
    expect(find.text('48/100'), findsOneWidget);
    expect(find.text('Suspicious Request'), findsOneWidget);

    // Tap first call item to open Call Summary
    await tester.tap(find.text('OTP Verification Scam'));
    await tester.pumpAndSettle();

    expect(find.text('Call Summary'), findsOneWidget);
    expect(find.text('Why this result?'), findsOneWidget);
  });

  testWidgets('HistoryScreen displays empty state and calls onOpenGuardian', (tester) async {
    var openedGuardian = false;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/analysis/history')) {
        return http.Response(jsonEncode([]), 200);
      }
      if (request.url.path.endsWith('/calls/history')) {
        return http.Response(
          jsonEncode({
            'items': [],
            'total': 0,
            'page': 1,
            'limit': 20,
            'has_next': false,
          }),
          200,
        );
      }
      return http.Response('Not found', 404);
    });

    final api = ApiService(client: client, baseUri: Uri.parse('https://api.example.test/api'));
    final analysisService = AnalysisService(api: api, tokenProvider: () async => 'token');
    final callHistoryService = CallHistoryService(api: api, tokenProvider: () async => 'token');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryScreen(
            analysisService: analysisService,
            callHistoryService: callHistoryService,
            onSessionExpired: () async {},
            onOpenGuardian: () => openedGuardian = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Calls tab
    await tester.tap(find.text('Calls'));
    await tester.pumpAndSettle();

    // Verify empty state
    expect(find.text('No protected calls yet'), findsOneWidget);
    expect(find.textContaining('ScamShield Guardian call summaries will appear here'), findsOneWidget);
    expect(find.text('Open Guardian'), findsOneWidget);

    // Tap Open Guardian button
    await tester.tap(find.text('Open Guardian'));
    await tester.pumpAndSettle();
    expect(openedGuardian, isTrue);
  });
}
