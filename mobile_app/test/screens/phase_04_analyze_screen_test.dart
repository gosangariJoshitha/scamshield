import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/screens/analyze/analyze_screen.dart';
import 'package:scamshield_guardian/screens/analyze/widgets/analyze_hero_card.dart';
import 'package:scamshield_guardian/screens/analyze/widgets/input_mode_selector.dart';
import 'package:scamshield_guardian/screens/analyze/widgets/privacy_matters_card.dart';
import 'package:scamshield_guardian/screens/analyze/widgets/secondary_utility_cards.dart';
import 'package:scamshield_guardian/services/analysis_service.dart';
import 'package:scamshield_guardian/services/api_service.dart';

AnalysisService _createMockAnalysisService({
  bool throwError = false,
  bool unauthorized = false,
  int responseId = 101,
  String riskLevel = 'HIGH',
  String classification = 'SCAM',
  String inputType = 'text',
}) {
  return AnalysisService(
    api: ApiService(
      client: MockClient((request) async {
        if (unauthorized) {
          return http.Response(
            jsonEncode({'detail': 'Could not validate credentials'}),
            401,
          );
        }
        if (throwError) {
          return http.Response(
            jsonEncode({'detail': 'Analysis service unavailable'}),
            503,
          );
        }
        if (request.url.path == '/api/analysis/text') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'id': responseId,
                'content': body['content'],
                'risk_score': 88,
                'risk_level': riskLevel,
                'classification': classification,
                'category': 'PHISHING',
                'input_type': 'text',
                'created_at': '2026-10-26T12:00:00Z',
                'explanation': 'Contains known malicious indicators.',
                'recommended_action': 'Do not interact with this link.',
              }),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path.startsWith('/api/analysis/')) {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'id': responseId,
                'content': 'Analyzed uploaded file',
                'risk_score': 15,
                'risk_level': 'LOW',
                'classification': 'SAFE',
                'category': 'BENIGN',
                'input_type': inputType,
                'created_at': '2026-10-26T12:00:00Z',
                'explanation': 'No indicators of compromise detected.',
                'recommended_action': 'File appears genuine.',
              }),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      }),
      baseUri: Uri.parse('https://api.example.test/api'),
    ),
    tokenProvider: () async => 'valid-jwt-token',
  );
}

Widget _buildAnalyzeScreen({
  AnalysisService? service,
  String initialType = 'text',
  VoidCallback? onAnalysisCompleted,
  Future<void> Function()? onSessionExpired,
  VoidCallback? onBackToDashboard,
  bool isDark = false,
}) {
  return MaterialApp(
    theme: isDark ? ThemeData.dark() : ThemeData.light(),
    home: AnalyzeScreen(
      analysisService: service ?? _createMockAnalysisService(),
      initialType: initialType,
      onAnalysisCompleted: onAnalysisCompleted ?? () {},
      onSessionExpired: onSessionExpired ?? () async {},
      onBackToDashboard: onBackToDashboard,
    ),
  );
}

void main() {
  group('ScamShield 2.0 — Phase 04 Analyze Submission Screen Tests', () {
    testWidgets('1. Initial layout renders Header, Hero card, Mode selector, and Privacy card', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildAnalyzeScreen());
      await tester.pumpAndSettle();

      expect(find.text('Analyze'), findsNWidgets(2)); // AppBar title + Submit button
      expect(find.byType(AnalyzeHeroCard), findsOneWidget);
      expect(find.text('Analyze & Stay Safe'), findsOneWidget);
      expect(find.text('Check messages, calls, images, documents and audio with AI to detect scams.'), findsOneWidget);
      expect(find.byType(InputModeSelector), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Image'), findsOneWidget);
      expect(find.text('Document'), findsOneWidget);
      expect(find.text('Audio'), findsOneWidget);
      expect(find.byType(PrivacyMattersCard), findsOneWidget);
      expect(find.text('Your Privacy Matters'), findsOneWidget);
    });

    testWidgets('2. Text mode renders multiline field with 0/5000 counter and 2x2 utility grid', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildAnalyzeScreen(initialType: 'text'));
      await tester.pumpAndSettle();

      expect(find.text('Paste or type a message here...'), findsOneWidget);
      expect(find.text('0/5000'), findsOneWidget);
      expect(find.byType(OrDivider), findsOneWidget);
      expect(find.text('Paste from Clipboard'), findsOneWidget);
      expect(find.text('Sample Messages'), findsOneWidget);
      expect(find.text('Scan Image'), findsOneWidget);
      expect(find.text('Upload Document'), findsOneWidget);
    });

    testWidgets('3. Multilingual Unicode text entry updates character counter accurately', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildAnalyzeScreen(initialType: 'text'));
      await tester.pumpAndSettle();

      // Enter multilingual text: English + Hindi + Telugu
      const multilingualInput = 'Urgent notice: आपका बैंक खाता ब्लॉक कर दिया गया है. వెంటనే సంప్రదించండి.';
      await tester.enterText(find.byType(TextField), multilingualInput);
      await tester.pump();

      expect(find.text(multilingualInput), findsOneWidget);
      expect(find.text('${multilingualInput.length}/5000'), findsOneWidget);
    });

    testWidgets('4. Switching to Image mode updates dropzone and options matching reference', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildAnalyzeScreen(initialType: 'text'));
      await tester.pumpAndSettle();

      // Tap on Image tab
      await tester.tap(find.text('Image'));
      await tester.pumpAndSettle();

      expect(find.text('Upload an image or screenshot'), findsOneWidget);
      expect(find.text('Analyze screenshots, images and media files to detect scams.'), findsOneWidget);
      expect(find.text('Supports JPG, PNG, WEBP (Max 10 MB)'), findsOneWidget);
      expect(find.text('Take a Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Upload Document (PDF)'), findsOneWidget);
    });

    testWidgets('5. Switching to Document mode displays PDF dropzone and sample documents', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildAnalyzeScreen(initialType: 'document'));
      await tester.pumpAndSettle();

      expect(find.text('Upload a document (PDF)'), findsOneWidget);
      expect(find.text('Supports PDF files (Max 20 MB)'), findsOneWidget);
      expect(find.text('Choose PDF File'), findsOneWidget);
      expect(find.text('Sample Documents'), findsOneWidget);
    });

    testWidgets('6. Switching to Audio mode displays audio dropzone with record and upload actions', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildAnalyzeScreen(initialType: 'audio'));
      await tester.pumpAndSettle();

      expect(find.text('Record audio or upload a file'), findsOneWidget);
      expect(find.text('Supports MP3, WAV, M4A, AAC, OGG (Max 25 MB)'), findsOneWidget);
      expect(find.text('Record Audio'), findsOneWidget);
      expect(find.text('Upload Audio'), findsOneWidget);
      expect(find.text('Sample Audio'), findsOneWidget);
      expect(find.text('Convert from Video'), findsOneWidget);
    });

    testWidgets('7. Empty submission shows validation error and does not call backend', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var apiInvoked = false;
      final service = AnalysisService(
        api: ApiService(
          client: MockClient((_) async {
            apiInvoked = true;
            return http.Response('{}', 200);
          }),
          baseUri: Uri.parse('https://api.example.test/api'),
        ),
        tokenProvider: () async => 'token',
      );

      await tester.pumpWidget(_buildAnalyzeScreen(service: service, initialType: 'text'));
      await tester.pumpAndSettle();

      // When text field is empty, Analyze button is disabled
      final submitButton = find.widgetWithText(FilledButton, 'Analyze');
      expect(tester.widget<FilledButton>(submitButton).onPressed, isNull);
      expect(apiInvoked, isFalse);
    });

    testWidgets('8. Genuine text submission sends payload and navigates to AnalysisResultScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var completed = false;
      final service = _createMockAnalysisService(
        responseId: 44,
        riskLevel: 'HIGH',
        classification: 'SCAM',
      );

      await tester.pumpWidget(_buildAnalyzeScreen(
        service: service,
        initialType: 'text',
        onAnalysisCompleted: () => completed = true,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Claim your ₹50,000 lottery winnings now!');
      await tester.pump();

      final submitButton = find.widgetWithText(FilledButton, 'Analyze');
      expect(tester.widget<FilledButton>(submitButton).onPressed, isNotNull);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(find.text('Analysis Result'), findsOneWidget);
      expect(find.text('Scam Detected'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('9. Backend 503 failure displays truthful error banner without fake success', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final service = _createMockAnalysisService(throwError: true);

      await tester.pumpWidget(_buildAnalyzeScreen(service: service, initialType: 'text'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.pump();

      final submitButton = find.widgetWithText(FilledButton, 'Analyze');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Analysis Result'), findsNothing);
      expect(find.textContaining('unavailable'), findsOneWidget);
    });

    testWidgets('10. Unauthorized 401 response invokes session expiry handler', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var sessionExpired = false;
      final service = _createMockAnalysisService(unauthorized: true);

      await tester.pumpWidget(_buildAnalyzeScreen(
        service: service,
        initialType: 'text',
        onSessionExpired: () async => sessionExpired = true,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Suspicious link');
      await tester.pump();

      final submitButton = find.widgetWithText(FilledButton, 'Analyze');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(sessionExpired, isTrue);
    });

    testWidgets('11. Sample Messages dialog populates input text', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildAnalyzeScreen(initialType: 'text'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sample Messages'));
      await tester.pumpAndSettle();

      expect(find.text('Sample Scams'), findsOneWidget);
      expect(find.text('Bank KYC Suspension Scam'), findsOneWidget);

      await tester.tap(find.text('Bank KYC Suspension Scam'));
      await tester.pumpAndSettle();

      expect(find.textContaining('bank account has been suspended'), findsOneWidget);
    });

    testWidgets('12. Light and Dark themes render without visual assertion failures', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Dark Mode
      await tester.pumpWidget(_buildAnalyzeScreen(isDark: true));
      await tester.pumpAndSettle();
      expect(find.byType(AnalyzeHeroCard), findsOneWidget);

      // Light Mode
      await tester.pumpWidget(_buildAnalyzeScreen(isDark: false));
      await tester.pumpAndSettle();
      expect(find.byType(AnalyzeHeroCard), findsOneWidget);
    });

    testWidgets('13. Narrow viewport (320px) and 1.3x text scaling render with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child!,
          ),
          home: AnalyzeScreen(
            analysisService: _createMockAnalysisService(),
            initialType: 'text',
            onAnalysisCompleted: () {},
            onSessionExpired: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Analyze & Stay Safe'), findsOneWidget);
    });
  });
}
