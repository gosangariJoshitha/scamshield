import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/models/call_history_models.dart';
import 'package:scamshield_guardian/services/api_service.dart';
import 'package:scamshield_guardian/services/call_history_service.dart';

Map<String, dynamic> _mockCallDetail({
  int id = 1,
  String sessionId = 'session-test-1',
  String riskLevel = 'HIGH',
  int riskScore = 78,
}) => {
  'id': id,
  'session_id': sessionId,
  'user_id': 42,
  'started_at': '2026-10-07T10:00:00Z',
  'ended_at': '2026-10-07T10:04:37Z',
  'duration_seconds': 277,
  'guardian_enabled': true,
  'guardian_status': 'ENABLED',
  'final_risk_score': riskScore,
  'final_risk_level': riskLevel,
  'classification': 'SCAM',
  'scam_category': 'OTP Verification Scam',
  'risk_reasoning': 'The caller requested an OTP urgently.',
  'safe_action': 'Do not share OTPs or credentials.',
  'detected_indicators': ['OTP request', 'Urgency'],
  'supporting_evidence': [
    {'title': 'OTP Verification Scam', 'similarity': 'Strong match'}
  ],
  'protection_actions': [
    {'action': 'WARNING_SHOWN', 'result': 'SUCCESS'},
    {'action': 'END_CALL', 'result': 'SUCCESS'}
  ],
  'analysis_status': 'COMPLETED',
  'transcription_status': 'COMPLETED',
  'audio_status': 'AVAILABLE',
  'created_at': '2026-10-07T10:04:38Z',
};

void main() {
  group('CallHistoryService', () {
    test('finalizeCallSession sends payload with auth header and marks session as finalized', () async {
      final client = MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer token-123');
        expect(request.url.path, '/api/calls/finalize');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['session_id'], 'session-finalize-test');
        expect(body['final_risk_score'], 78);
        return http.Response(jsonEncode(_mockCallDetail(sessionId: 'session-finalize-test')), 200);
      });

      final service = CallHistoryService(
        api: ApiService(client: client, baseUri: Uri.parse('https://api.example.test/api')),
        tokenProvider: () async => 'token-123',
      );

      expect(service.isSessionFinalized('session-finalize-test'), isFalse);

      final payload = CallFinalizePayload(
        sessionId: 'session-finalize-test',
        durationSeconds: 277,
        finalRiskScore: 78,
        finalRiskLevel: 'HIGH',
        classification: 'SCAM',
        scamCategory: 'OTP Verification Scam',
      );

      final detail = await service.finalizeCallSession(payload);
      expect(detail.sessionId, 'session-finalize-test');
      expect(detail.finalRiskScore, 78);
      expect(detail.finalRiskLevel, 'HIGH');
      expect(service.isSessionFinalized('session-finalize-test'), isTrue);
    });

    test('loadCallHistory sends query parameters and parses list response', () async {
      final client = MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer token-123');
        expect(request.url.path, '/api/calls/history');
        expect(request.url.queryParameters['page'], '1');
        expect(request.url.queryParameters['limit'], '20');
        expect(request.url.queryParameters['risk_level'], 'HIGH');

        final responseJson = {
          'items': [
            _mockCallDetail(id: 1, sessionId: 's1', riskLevel: 'HIGH', riskScore: 78),
            _mockCallDetail(id: 2, sessionId: 's2', riskLevel: 'HIGH', riskScore: 65),
          ],
          'total': 2,
          'page': 1,
          'limit': 20,
          'has_next': false,
        };
        return http.Response(jsonEncode(responseJson), 200);
      });

      final service = CallHistoryService(
        api: ApiService(client: client, baseUri: Uri.parse('https://api.example.test/api')),
        tokenProvider: () async => 'token-123',
      );

      final result = await service.loadCallHistory(riskLevel: 'HIGH', page: 1, limit: 20);
      expect(result.total, 2);
      expect(result.items.length, 2);
      expect(result.items.first.sessionId, 's1');
      expect(result.items.first.finalRiskLevel, 'HIGH');
    });

    test('getCallSummary fetches detail by session_id', () async {
      final client = MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer token-123');
        expect(request.url.path, '/api/calls/session-999');
        return http.Response(jsonEncode(_mockCallDetail(sessionId: 'session-999')), 200);
      });

      final service = CallHistoryService(
        api: ApiService(client: client, baseUri: Uri.parse('https://api.example.test/api')),
        tokenProvider: () async => 'token-123',
      );

      final detail = await service.getCallSummary('session-999');
      expect(detail.sessionId, 'session-999');
      expect(detail.detectedIndicators, contains('OTP request'));
      expect(detail.protectionActions.length, 2);
    });

    test('throws 401 ApiException when auth token is unavailable', () async {
      final client = MockClient((request) async => http.Response('Unauthorized', 401));
      final service = CallHistoryService(
        api: ApiService(client: client, baseUri: Uri.parse('https://api.example.test/api')),
        tokenProvider: () async => null,
      );

      expect(
        () => service.loadCallHistory(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });
  });
}
