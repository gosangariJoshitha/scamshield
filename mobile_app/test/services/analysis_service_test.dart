import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/services/analysis_service.dart';
import 'package:scamshield_guardian/services/api_service.dart';

Map<String, dynamic> _analysis(int id) => {
  'id': id,
  'content': 'Check this payment request',
  'risk_score': 74,
  'risk_level': 'HIGH',
  'classification': 'SCAM',
  'category': 'PHISHING',
  'input_type': 'text',
  'created_at': '2026-10-06T10:00:00Z',
  'explanation': 'Requests payment urgently.',
  'recommended_action': 'Contact the organization independently.',
  'ml_probability': 0.94,
  'llm_confidence': 0.91,
  'indicators': ['OTP request detected'],
  'retrieved_evidence_data': [
    {
      'title': 'KYC impersonation',
      'category': 'Banking',
      'similarity_score': 0.88,
      'pattern': 'Fake KYC message asks for an OTP.',
      'safe_action': 'Verify using the official banking app.',
      'source': 'Verified scam report',
    },
  ],
  'safe_actions': {
    'canonical': ['Contact the organization independently.'],
    'translations': {},
    'default_language': 'en',
  },
  'processing_status': 'COMPLETED',
};

void main() {
  test(
    'loads dashboard summary and user history with authenticated requests',
    () async {
      final client = MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer session-token');
        if (request.url.path.endsWith('/analysis/dashboard')) {
          return http.Response(
            '{"total_analyses":1,"scams_detected":1,"safe_messages":0,"high_risk":1}',
            200,
          );
        }
        expect(request.url.path, endsWith('/analysis/history'));
        return http.Response(jsonEncode([_analysis(12)]), 200);
      });
      final service = AnalysisService(
        api: ApiService(
          client: client,
          baseUri: Uri.parse('https://api.example.test/api'),
        ),
        tokenProvider: () async => 'session-token',
      );

      final data = await service.loadDashboard();

      expect(data.stats.totalAnalyses, 1);
      expect(data.stats.scamsDetected, 1);
      expect(data.recentAnalyses.single.id, 12);
      expect(data.recentAnalyses.single.riskLevel, 'HIGH');
      expect(data.recentAnalyses.single.mlProbability, 0.94);
      expect(data.recentAnalyses.single.llmConfidence, 0.91);
      expect(data.recentAnalyses.single.indicators, ['OTP request detected']);
      expect(
        data.recentAnalyses.single.retrievedEvidence.single.title,
        'KYC impersonation',
      );
      expect(data.recentAnalyses.single.safeActions, [
        'Contact the organization independently.',
      ]);
    },
  );

  test(
    'rejects malformed dashboard API data rather than inventing values',
    () async {
      final service = AnalysisService(
        api: ApiService(
          client: MockClient((request) async {
            if (request.url.path.endsWith('/analysis/dashboard')) {
              return http.Response('{"total_analyses":"unknown"}', 200);
            }
            return http.Response('[]', 200);
          }),
          baseUri: Uri.parse('https://api.example.test/api'),
        ),
        tokenProvider: () async => 'session-token',
      );

      await expectLater(
        service.loadDashboard(),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('reports a missing session as unauthorized', () async {
    final service = AnalysisService(
      api: ApiService(
        client: MockClient((_) async => http.Response('{}', 200)),
        baseUri: Uri.parse('https://api.example.test/api'),
      ),
      tokenProvider: () async => null,
    );

    await expectLater(
      service.loadHistory(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'status code',
          401,
        ),
      ),
    );
  });
}
