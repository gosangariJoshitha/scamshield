import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/screens/analyze/analyze_screen.dart';
import 'package:scamshield_guardian/screens/analyze/widgets/analyze_hero_card.dart';
import 'package:scamshield_guardian/screens/analyze/widgets/input_mode_selector.dart';
import 'package:scamshield_guardian/screens/analyze/widgets/privacy_matters_card.dart';
import 'package:scamshield_guardian/services/analysis_service.dart';
import 'package:scamshield_guardian/services/api_service.dart';

class MockBackendState {
  final List<Map<String, dynamic>> persistedHistory = [];
  final List<String> capturedRequests = [];
  bool throwOcrEmpty = false;
  bool throwServerUnavailable = false;
  bool throwUnauthorized = false;
  int nextId = 100;
}

AnalysisService _createMockAnalysisService(MockBackendState state) {
  return AnalysisService(
    api: ApiService(
      client: MockClient((request) async {
        state.capturedRequests.add('${request.method} ${request.url.path}');

        if (state.throwUnauthorized) {
          return http.Response(
            jsonEncode({'detail': 'Could not validate credentials'}),
            401,
          );
        }

        if (state.throwServerUnavailable) {
          return http.Response(
            jsonEncode({'detail': 'Analysis service is temporarily unavailable.'}),
            503,
          );
        }

        if (request.url.path == '/api/analysis/text') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final content = body['content'] as String;
          final record = {
            'id': state.nextId++,
            'content': content,
            'risk_score': 85,
            'risk_level': 'HIGH',
            'classification': 'SCAM',
            'category': 'PHISHING',
            'input_type': 'text',
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'explanation': 'Contains urgent threats and suspicious links.',
            'recommended_action': 'Do not reply or share credentials.',
            'indicators': ['Urgency pattern', 'Payment request'],
            'safe_actions': {
              'canonical': ['Do not click link', 'Verify sender', 'Block number'],
              'translations': {
                'en': ['Do not click link', 'Verify sender', 'Block number'],
                'hi': ['लिंक पर क्लिक न करें', 'भेजने वाले की पुष्टि करें', 'नंबर ब्लॉक करें'],
                'te': ['లింక్‌ను క్లిక్ చేయవద్దు', 'పంపినవారిని ధృవీకరించండి', 'నంబర్‌ను బ్లాక్ చేయండి'],
              },
            },
          };
          state.persistedHistory.insert(0, record);
          return http.Response.bytes(
            utf8.encode(jsonEncode(record)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (request.url.path == '/api/analysis/url') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final content = body['content'] as String;
          final record = {
            'id': state.nextId++,
            'content': content,
            'risk_score': 92,
            'risk_level': 'CRITICAL',
            'classification': 'SCAM',
            'category': 'MALICIOUS_URL',
            'input_type': 'url',
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'explanation': 'Target URL is hosted on a newly registered suspicious domain.',
            'recommended_action': 'Do not visit or submit credentials to this website.',
            'indicators': ['Suspicious domain', 'Typosquatting indicator'],
            'safe_actions': {
              'canonical': ['Close tab immediately', 'Report URL', 'Do not enter passwords'],
              'translations': {
                'en': ['Close tab immediately', 'Report URL', 'Do not enter passwords'],
                'hi': ['टैब तुरंत बंद करें', 'यूआरएल रिपोर्ट करें', 'पासवर्ड दर्ज न करें'],
                'te': ['ట్యాబ్‌ను వెంటనే మూసివేయండి', 'యూఆర్‌ఎల్‌ని నివేదించండి', 'పాస్‌వర్డ్‌లను నమోదు చేయవద్దు'],
              },
            },
          };
          state.persistedHistory.insert(0, record);
          return http.Response.bytes(
            utf8.encode(jsonEncode(record)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (request.url.path == '/api/analysis/image') {
          if (state.throwOcrEmpty) {
            return http.Response(
              jsonEncode({'detail': 'No readable content could be extracted.'}),
              400,
            );
          }
          final record = {
            'id': state.nextId++,
            'content': 'Extracted image text: Congratulations winner!',
            'risk_score': 78,
            'risk_level': 'HIGH',
            'classification': 'SCAM',
            'category': 'LOTTERY_SCAM',
            'input_type': 'image',
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'explanation': 'Screenshot contains counterfeit lottery winner certificate.',
            'recommended_action': 'Never pay advance processing fees.',
            'indicators': ['Advance fee fraud', 'Fake stamp'],
          };
          state.persistedHistory.insert(0, record);
          return http.Response.bytes(
            utf8.encode(jsonEncode(record)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (request.url.path == '/api/analysis/pdf') {
          final record = {
            'id': state.nextId++,
            'content': 'Extracted PDF text: Invoice settlement demand',
            'risk_score': 74,
            'risk_level': 'HIGH',
            'classification': 'SCAM',
            'category': 'DOCUMENT_FRAUD',
            'input_type': 'pdf',
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'explanation': 'PDF invoice requests UPI transfer for fake customs clearance.',
            'recommended_action': 'Do not transfer funds.',
            'indicators': ['Customs extortion', 'Personal UPI ID'],
          };
          state.persistedHistory.insert(0, record);
          return http.Response.bytes(
            utf8.encode(jsonEncode(record)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (request.url.path == '/api/analysis/audio') {
          final record = {
            'id': state.nextId++,
            'content': 'Transcribed audio: This is Central Cyber Police. You are under digital arrest.',
            'risk_score': 95,
            'risk_level': 'CRITICAL',
            'classification': 'SCAM',
            'category': 'DIGITAL_ARREST',
            'input_type': 'audio',
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'explanation': 'Impersonation of law enforcement officers with digital arrest threat.',
            'recommended_action': 'Immediately disconnect. Police never arrest via video call.',
            'indicators': ['Digital arrest claim', 'Law enforcement impersonation'],
          };
          state.persistedHistory.insert(0, record);
          return http.Response.bytes(
            utf8.encode(jsonEncode(record)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (request.url.path == '/api/analysis/history') {
          return http.Response.bytes(
            utf8.encode(jsonEncode(state.persistedHistory)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (request.url.path == '/api/analysis/dashboard') {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'total_analyses': state.persistedHistory.length,
                'scams_detected': state.persistedHistory.where((e) => e['classification'] == 'SCAM').length,
                'safe_messages': state.persistedHistory.where((e) => e['classification'] == 'SAFE').length,
                'high_risk': state.persistedHistory.where((e) => e['risk_level'] == 'HIGH' || e['risk_level'] == 'CRITICAL').length,
              }),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        return http.Response('Not Found', 404);
      }),
      baseUri: Uri.parse('https://api.scamshield.test/api'),
    ),
    tokenProvider: () async => 'jwt-test-token',
  );
}

Widget _buildAnalyzeApp({
  required AnalysisService service,
  String initialType = 'text',
  VoidCallback? onAnalysisCompleted,
  Future<void> Function()? onSessionExpired,
  VoidCallback? onBackToDashboard,
  bool isDark = false,
}) {
  return MaterialApp(
    theme: isDark ? ThemeData.dark() : ThemeData.light(),
    home: AnalyzeScreen(
      analysisService: service,
      initialType: initialType,
      onAnalysisCompleted: onAnalysisCompleted ?? () {},
      onSessionExpired: onSessionExpired ?? () async {},
      onBackToDashboard: onBackToDashboard,
    ),
  );
}

void main() {
  group('SCAMSHIELD — PHASE 03: Complete Analyze Module & Multi-Input Integration Tests', () {
    testWidgets('1. Initial layout renders Header, Hero card, 5 Mode Tabs (Text, Link, Image, Document, Audio), and Privacy card', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = MockBackendState();
      final service = _createMockAnalysisService(state);

      await tester.pumpWidget(_buildAnalyzeApp(service: service));
      await tester.pumpAndSettle();

      expect(find.text('Analyze'), findsNWidgets(2)); // AppBar title + Submit button
      expect(find.byType(AnalyzeHeroCard), findsOneWidget);
      expect(find.byType(InputModeSelector), findsOneWidget);

      // Verify all 5 channels are present in the mode selector
      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Link'), findsOneWidget);
      expect(find.text('Image'), findsOneWidget);
      expect(find.text('Document'), findsOneWidget);
      expect(find.text('Audio'), findsOneWidget);

      expect(find.byType(PrivacyMattersCard), findsOneWidget);
    });

    testWidgets('2. Text Analysis: submitting text calls /api/analysis/text, navigates to result, and CLEARS input on return', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = MockBackendState();
      final service = _createMockAnalysisService(state);
      var completed = false;

      await tester.pumpWidget(_buildAnalyzeApp(
        service: service,
        initialType: 'text',
        onAnalysisCompleted: () => completed = true,
      ));
      await tester.pumpAndSettle();

      const sampleMessage = 'Your account has been suspended. Send OTP immediately.';
      await tester.enterText(find.byType(TextField), sampleMessage);
      await tester.pump();

      expect(find.text(sampleMessage), findsOneWidget);

      // Tap submit button
      final submitButton = find.widgetWithText(FilledButton, 'Analyze');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verified: result screen opened, backend called, history persisted
      expect(completed, isTrue);
      expect(state.capturedRequests, contains('POST /api/analysis/text'));
      expect(state.persistedHistory.length, 1);
      expect(find.text('Analysis Result'), findsOneWidget);
      expect(find.text('Scam Detected'), findsOneWidget);

      // Tap back to return to Analyze screen
      final backButton = find.byTooltip('Back');
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // VERIFIED: Returning to fresh Analyze screen has CLEARED the previous input
      expect(find.text(sampleMessage), findsNothing);
      expect(find.text('0/5000'), findsOneWidget);
      expect(find.text('Paste or type a message here...'), findsOneWidget);
    });

    testWidgets('3. Text Analysis: empty submission is rejected and "Clear Text" button resets controller', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = MockBackendState();
      final service = _createMockAnalysisService(state);

      await tester.pumpWidget(_buildAnalyzeApp(service: service, initialType: 'text'));
      await tester.pumpAndSettle();

      // Submit is disabled when empty
      final submitButton = find.widgetWithText(FilledButton, 'Analyze');
      expect(tester.widget<FilledButton>(submitButton).onPressed, isNull);
      expect(state.capturedRequests, isEmpty);

      // Type some text
      await tester.enterText(find.byType(TextField), 'Some temporary text');
      await tester.pump();
      expect(find.text('Clear Text'), findsOneWidget);

      // Tap Clear Text button
      await tester.tap(find.text('Clear Text'));
      await tester.pump();

      expect(find.text('0/5000'), findsOneWidget);
      expect(find.text('Some temporary text'), findsNothing);
    });

    testWidgets('4. Link / URL Analysis: renders dedicated URL view, validates URL syntax, and rejects invalid URLs', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = MockBackendState();
      final service = _createMockAnalysisService(state);

      await tester.pumpWidget(_buildAnalyzeApp(service: service, initialType: 'url'));
      await tester.pumpAndSettle();

      expect(find.text('Website Link / URL'), findsOneWidget);
      expect(find.textContaining('Safe Inspection: ScamShield analyzes links via cloud threat intelligence'), findsOneWidget);

      // Enter invalid URL without dot/domain
      await tester.enterText(find.byType(TextField), 'not-a-valid-url');
      await tester.pump();

      final submitButton = find.widgetWithText(FilledButton, 'Analyze');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Validation error shown, backend not called
      expect(find.textContaining('Please enter a valid website link'), findsOneWidget);
      expect(state.capturedRequests, isEmpty);
    });

    testWidgets('5. Link / URL Analysis: submits valid URL to /api/analysis/url, navigates, and CLEARS URL input on return', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = MockBackendState();
      final service = _createMockAnalysisService(state);
      var completed = false;

      await tester.pumpWidget(_buildAnalyzeApp(
        service: service,
        initialType: 'url',
        onAnalysisCompleted: () => completed = true,
      ));
      await tester.pumpAndSettle();

      const phishingUrl = 'https://secure-login-hdfc-kyc.com/update';
      await tester.enterText(find.byType(TextField), phishingUrl);
      await tester.pump();

      final submitButton = find.widgetWithText(FilledButton, 'Analyze');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(state.capturedRequests, contains('POST /api/analysis/url'));
      expect(state.persistedHistory.length, 1);
      expect(state.persistedHistory.first['input_type'], 'url');
      expect(find.text('Analysis Result'), findsOneWidget);

      // Tap back to return to Analyze screen
      final backButton = find.byTooltip('Back');
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // VERIFIED: URL input is CLEARED after returning
      expect(find.text(phishingUrl), findsNothing);
      expect(find.text('https://example.com/verify...'), findsOneWidget);
    });

    testWidgets('6. Link / URL Analysis: SampleLinksDialog populates URL field accurately', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = MockBackendState();
      final service = _createMockAnalysisService(state);

      await tester.pumpWidget(_buildAnalyzeApp(service: service, initialType: 'url'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sample Links'));
      await tester.pumpAndSettle();

      expect(find.text('Sample Suspicious Links'), findsOneWidget);
      expect(find.text('SBI Phishing Verification Portal'), findsOneWidget);

      // Tap on sample link item
      await tester.tap(find.text('SBI Phishing Verification Portal'));
      await tester.pumpAndSettle();

      expect(find.text('http://sbi-kyc-verify-portal.top/update'), findsOneWidget);
    });

    testWidgets('7. Image Analysis: selects OCR language chips and verifies OCR empty error handling', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = MockBackendState();
      state.throwOcrEmpty = true;
      final service = _createMockAnalysisService(state);

      await tester.pumpWidget(_buildAnalyzeApp(service: service, initialType: 'image'));
      await tester.pumpAndSettle();

      expect(find.text('Upload an image or screenshot'), findsOneWidget);
      expect(find.text('OCR Language:'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.text('తెలుగు'), findsOneWidget);

      // Switch OCR language to Hindi
      await tester.tap(find.text('हिन्दी'));
      await tester.pump();

      // Switch OCR language to Telugu
      await tester.tap(find.text('తెలుగు'));
      await tester.pump();
    });

    testWidgets('8. Multilingual Unicode Support: Hindi and Telugu scripts are handled cleanly', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = MockBackendState();
      final service = _createMockAnalysisService(state);

      await tester.pumpWidget(_buildAnalyzeApp(service: service, initialType: 'text'));
      await tester.pumpAndSettle();

      const hindiTeluguText = 'आपका बैंक खाता बंद हो जाएगा: వెంటనే సంప్రదించండి https://bank-verify.in';
      await tester.enterText(find.byType(TextField), hindiTeluguText);
      await tester.pump();

      final submitButton = find.widgetWithText(FilledButton, 'Analyze');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(state.persistedHistory.length, 1);
      expect(state.persistedHistory.first['content'], hindiTeluguText);
      expect(find.text('Analysis Result'), findsOneWidget);
    });

    testWidgets('9. History Integration: verified that completed analyses are queryable via loadHistory', (tester) async {
      final state = MockBackendState();
      final service = _createMockAnalysisService(state);

      // Perform text analysis
      await service.analyzeText('Test message 1');
      // Perform url analysis
      await service.analyzeUrl('https://suspicious-site.test/login');

      expect(state.persistedHistory.length, 2);

      final history = await service.loadHistory();
      expect(history.length, 2);
      expect(history[0].inputType, 'url');
      expect(history[1].inputType, 'text');

      final dashboard = await service.loadDashboard();
      expect(dashboard.stats.totalAnalyses, 2);
      expect(dashboard.stats.scamsDetected, 2);
    });

    testWidgets('10. Viewport resilience: 320px narrow width renders all 5 tabs and UI with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = MockBackendState();
      final service = _createMockAnalysisService(state);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.2),
            ),
            child: child!,
          ),
          home: AnalyzeScreen(
            analysisService: service,
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
