import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/screens/analyze/analyze_screen.dart';
import 'package:scamshield_guardian/services/analysis_service.dart';
import 'package:scamshield_guardian/services/api_service.dart';

void main() {
  testWidgets('submits text to the existing API and presents the result', (
    tester,
  ) async {
    var completed = false;
    final service = AnalysisService(
      api: ApiService(
        client: MockClient((request) async {
          expect(request.url.path, '/api/analysis/text');
          expect(request.headers['authorization'], startsWith('Bearer '));
          expect(jsonDecode(request.body), {
            'content': 'Please verify this payment link',
          });
          return http.Response(
            jsonEncode({
              'id': 31,
              'content': 'Please verify this payment link',
              'risk_score': 86,
              'risk_level': 'HIGH',
              'classification': 'SCAM',
              'category': 'PHISHING',
              'input_type': 'text',
              'created_at': '2026-10-06T10:00:00Z',
              'explanation': 'The request uses an untrusted payment link.',
              'recommended_action': 'Verify using the official website.',
            }),
            200,
          );
        }),
        baseUri: Uri.parse('https://api.example.test/api'),
      ),
      tokenProvider: () async => 'session-token',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AnalyzeScreen(
          analysisService: service,
          initialType: 'text',
          onSessionExpired: () async {},
          onAnalysisCompleted: () => completed = true,
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextField),
      'Please verify this payment link',
    );
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Please verify this payment link',
    );
    final submitButton = find.widgetWithText(FilledButton, 'ANALYZE');
    expect(tester.widget<FilledButton>(submitButton).onPressed, isNotNull);
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(find.text('Analysis Result'), findsOneWidget);
    expect(find.text('HIGH'), findsOneWidget);
    expect(find.text('SCAM'), findsOneWidget);
    expect(find.text('Verify using the official website.'), findsOneWidget);
  });
}
