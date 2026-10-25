import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/models/user.dart';
import 'package:scamshield_guardian/screens/home/home_screen.dart';
import 'package:scamshield_guardian/services/analysis_service.dart';
import 'package:scamshield_guardian/services/api_service.dart';
import 'package:scamshield_guardian/services/call_history_service.dart';

const _testUser = User(
  id: 42,
  fullName: 'Alice Guardian',
  email: 'alice@scamshield.test',
  role: 'user',
  isActive: true,
  emailVerified: true,
  twoFactorEnabled: false,
);

void main() {
  testWidgets('Full Guardian End-to-End Flow: Call Start -> Transcript -> AI Risk -> Summary -> History', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    const sessionId = '00000000-0000-4000-8000-000000000099';

    final client = MockClient((request) async {
      final path = request.url.path;

      // 0. Dashboard stats
      if (path.endsWith('/analysis/dashboard')) {
        return http.Response(
          jsonEncode({
            'total_analyses': 1,
            'scams_detected': 1,
            'safe_messages': 0,
            'high_risk': 1,
          }),
          200,
        );
      }

      // 1. Transcription chunk upload
      if (path.endsWith('/guardian/transcription/chunk')) {
        return http.Response(
          jsonEncode({
            'session_id': sessionId,
            'segments': [
              {
                'session_id': sessionId,
                'segment_id': 'seg-e2e-1',
                'sequence': 1,
                'start_time': 0.0,
                'end_time': 4.5,
                'text': 'Your bank card is blocked. Please read out your OTP now.',
                'is_final': true,
                'language': 'en',
                'source': 'CALL_AUDIO',
                'created_at': DateTime.now().toUtc().toIso8601String(),
              }
            ],
            'window_id': 'win-1',
            'status': 'OK',
            'message': 'Transcription completed.',
          }),
          200,
        );
      }

      // 2. Live Analysis segment evaluation
      if (path.endsWith('/guardian/analysis/segment')) {
        return http.Response(
          jsonEncode({
            'session_id': sessionId,
            'status': 'AI_RESULT_READY',
            'message': 'Analysis ready.',
            'processed_sequence': 1,
            'window_id': 'win-1',
            'result': {
              'risk_score': 92,
              'risk_level': 'CRITICAL',
              'classification': 'SCAM',
              'scam_category': 'OTP Verification Scam',
              'detected_indicators': ['OTP request', 'Urgency', 'Card block threat'],
              'reasoning': 'Caller creates urgency around a card block and demands an OTP.',
              'supporting_evidence': [
                {
                  'knowledge_id': 101,
                  'title': 'Banking OTP Impersonation',
                  'category': 'Vishing',
                  'similarity_score': 0.91,
                  'description': 'Scammers claim account freeze and request OTP.',
                  'indicators': ['OTP request'],
                  'safe_action': 'Never share OTP.',
                  'source': 'RBI Advisory',
                  'pattern': 'Card block threat',
                  'language': 'en',
                }
              ],
              'safe_action': 'Never share OTP, PIN, or CVV over the phone.',
              'timestamp': DateTime.now().toUtc().toIso8601String(),
            },
          }),
          200,
        );
      }

      // 3. Session finalize
      if (path.endsWith('/calls/finalize')) {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'id': 77,
            'session_id': body['session_id'].toString(),
            'user_id': 42,
            'started_at': body['started_at'],
            'ended_at': body['ended_at'],
            'duration_seconds': body['duration_seconds'],
            'guardian_enabled': true,
            'guardian_status': 'ENABLED',
            'final_risk_score': body['final_risk_score'],
            'final_risk_level': body['final_risk_level'],
            'classification': body['classification'],
            'scam_category': body['scam_category'],
            'risk_reasoning': body['risk_reasoning'],
            'safe_action': body['safe_action'],
            'detected_indicators': body['detected_indicators'],
            'supporting_evidence': body['supporting_evidence'],
            'protection_actions': body['protection_actions'],
            'analysis_status': body['analysis_status'],
            'transcription_status': body['transcription_status'],
            'audio_status': body['audio_status'],
            'created_at': DateTime.now().toUtc().toIso8601String(),
          }),
          200,
        );
      }

      // 4. Call History list
      if (path.endsWith('/calls/history')) {
        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 77,
                'session_id': sessionId,
                'started_at': DateTime.now().subtract(const Duration(seconds: 120)).toUtc().toIso8601String(),
                'ended_at': DateTime.now().toUtc().toIso8601String(),
                'duration_seconds': 120,
                'final_risk_score': 92,
                'final_risk_level': 'CRITICAL',
                'classification': 'SCAM',
                'scam_category': 'OTP Verification Scam',
                'analysis_status': 'COMPLETED',
                'transcription_status': 'COMPLETED',
                'audio_status': 'AVAILABLE',
              }
            ],
            'total': 1,
            'page': 1,
            'limit': 20,
            'has_next': false,
          }),
          200,
        );
      }

      // 5. Single Call Summary detail
      if (path.contains('/calls/$sessionId')) {
        return http.Response(
          jsonEncode({
            'id': 77,
            'session_id': sessionId,
            'user_id': 42,
            'started_at': DateTime.now().subtract(const Duration(seconds: 120)).toUtc().toIso8601String(),
            'ended_at': DateTime.now().toUtc().toIso8601String(),
            'duration_seconds': 120,
            'guardian_enabled': true,
            'guardian_status': 'ENABLED',
            'final_risk_score': 92,
            'final_risk_level': 'CRITICAL',
            'classification': 'SCAM',
            'scam_category': 'OTP Verification Scam',
            'risk_reasoning': 'Caller creates urgency around a card block and demands an OTP.',
            'safe_action': 'Never share OTP, PIN, or CVV over the phone.',
            'detected_indicators': ['OTP request', 'Urgency', 'Card block threat'],
            'supporting_evidence': [
              {'title': 'Banking OTP Impersonation', 'similarity': 'Strong match'}
            ],
            'protection_actions': [
              {'action': 'WARNING_SHOWN', 'result': 'SUCCESS'}
            ],
            'analysis_status': 'COMPLETED',
            'transcription_status': 'COMPLETED',
            'audio_status': 'AVAILABLE',
            'created_at': DateTime.now().toUtc().toIso8601String(),
          }),
          200,
        );
      }

      // Analysis history mock
      if (path.endsWith('/analysis/history')) {
        return http.Response(jsonEncode([]), 200);
      }

      // Session cleanup endpoints
      if (path.contains('/finalize')) {
        return http.Response('{}', 200);
      }

      return http.Response('{"status": "ok"}', 200);
    });

    final api = ApiService(client: client, baseUri: Uri.parse('https://api.example.test/api'));
    final analysisService = AnalysisService(api: api, tokenProvider: () async => 'valid-jwt');
    final callHistoryService = CallHistoryService(api: api, tokenProvider: () async => 'valid-jwt');

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          user: _testUser,
          analysisService: analysisService,
          callHistoryService: callHistoryService,
          isDarkMode: false,
          onToggleTheme: () {},
          onLogout: () async {},
          onSessionExpired: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Dashboard is displayed
    expect(find.text('Hello, Alice 👋'), findsOneWidget);

    // Switch to Guardian tab (index 2)
    await tester.tap(find.byIcon(Icons.shield_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Live Call Guardian'), findsWidgets);

    // Switch to History tab (index 3)
    await tester.tap(find.byIcon(Icons.history_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Analysis History'), findsWidgets);

    // Switch back to Calls tab in History
    await tester.tap(find.text('Calls'));
    await tester.pumpAndSettle();

    // Verify call history item loaded
    expect(find.text('CRITICAL RISK'), findsWidgets);
    expect(find.text('92/100'), findsOneWidget);
    expect(find.text('OTP Verification Scam'), findsWidgets);

    // Tap call item to open CallSummaryScreen
    await tester.tap(find.text('OTP Verification Scam'));
    await tester.pumpAndSettle();

    // Verify CallSummaryScreen contents
    expect(find.text('Call Summary'), findsOneWidget);
    expect(find.text('92 / 100'), findsOneWidget);
    expect(find.text('Why this result?'), findsOneWidget);
    expect(find.textContaining('Caller creates urgency around a card block'), findsOneWidget);
    expect(find.text('Detected indicators'), findsOneWidget);
    expect(find.text('OTP request'), findsOneWidget);
    expect(find.text('Safer Next Step'), findsOneWidget);
    expect(find.text('Never share OTP, PIN, or CVV over the phone.'), findsOneWidget);
    expect(find.text('Call details'), findsOneWidget);
    expect(find.text('02:00'), findsWidgets);
  });
}
