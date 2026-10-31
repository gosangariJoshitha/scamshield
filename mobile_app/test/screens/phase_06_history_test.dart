import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/screens/history/history_screen.dart';
import 'package:scamshield_guardian/screens/history/widgets/date_section_header.dart';
import 'package:scamshield_guardian/screens/history/widgets/history_filter_pills.dart';
import 'package:scamshield_guardian/services/analysis_service.dart';
import 'package:scamshield_guardian/services/api_service.dart';
import 'package:scamshield_guardian/services/call_history_service.dart';

http.Response _jsonResponse(dynamic data, [int status = 200]) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(data)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

Map<String, dynamic> _mockAnalysisJson({
  required int id,
  required String content,
  required String classification,
  required String riskLevel,
  required String inputType,
  required DateTime createdAt,
  String? originalFilename,
  String category = 'Scam',
  int riskScore = 94,
  double llmConfidence = 0.94,
  List<String> indicators = const ['Prize claim', 'Shortened link'],
  String explanation = 'This message contains a prize claim with urgent action.',
  List<String> safeActions = const ['Do not click on any links.', 'Block and report.'],
  Map<String, List<String>> actionTranslations = const {
    'en': ['Do not click on any links in this message.', 'Block and report the sender.'],
    'hi': ['इस संदेश में किसी भी लिंक पर क्लिक न करें।', 'प्रेषक को ब्लॉक और रिपोर्ट करें।'],
    'te': ['ఈ సందేశంలోని ఏ లింక్‌లను క్లిక్ చేయవద్దు.', 'పంపినవారిని బ్లాక్ చేసి నివేదించండి.'],
  },
}) => {
  'id': id,
  'content': content,
  'classification': classification,
  'risk_level': riskLevel,
  'input_type': inputType,
  'category': category,
  'risk_score': riskScore,
  'llm_confidence': llmConfidence,
  'ml_probability': 0.92,
  'created_at': createdAt.toUtc().toIso8601String(),
  'original_filename': originalFilename,
  'explanation': explanation,
  'indicators': indicators,
  'safe_actions': {
    'canonical': safeActions,
    'translations': actionTranslations,
    'default_language': 'en',
  },
};

Map<String, dynamic> _mockCallItem({
  int id = 1,
  String sessionId = 'session-test-01',
  String riskLevel = 'HIGH',
  int riskScore = 88,
  String category = 'Suspected spam call',
  DateTime? endedAt,
}) => {
  'id': id,
  'session_id': sessionId,
  'started_at': (endedAt ?? DateTime.now()).subtract(const Duration(minutes: 3)).toUtc().toIso8601String(),
  'ended_at': (endedAt ?? DateTime.now()).toUtc().toIso8601String(),
  'duration_seconds': 180,
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
  String sessionId = 'session-test-01',
}) => {
  'id': id,
  'session_id': sessionId,
  'started_at': DateTime.now().subtract(const Duration(minutes: 3)).toUtc().toIso8601String(),
  'ended_at': DateTime.now().toUtc().toIso8601String(),
  'duration_seconds': 180,
  'guardian_enabled': true,
  'guardian_status': 'ENABLED',
  'final_risk_score': 88,
  'final_risk_level': 'HIGH',
  'classification': 'SCAM',
  'scam_category': 'Suspected spam call',
  'risk_reasoning': 'The caller claimed to represent a bank and demanded urgent OTP verification.',
  'safe_action': 'Hang up immediately and contact the bank directly.',
  'detected_indicators': ['Bank impersonation', 'Urgent OTP demand'],
  'supporting_evidence': [],
  'protection_actions': [],
  'analysis_status': 'COMPLETED',
  'transcription_status': 'COMPLETED',
  'audio_status': 'AVAILABLE',
};

void main() {
  final now = DateTime.now();
  final todayTime = DateTime(now.year, now.month, now.day, 10, 42);
  final yesterdayTime = DateTime(now.year, now.month, now.day, 14, 20).subtract(const Duration(days: 1));

  late List<Map<String, dynamic>> analysisRecords;
  late List<Map<String, dynamic>> callRecords;

  setUp(() {
    analysisRecords = [
      _mockAnalysisJson(
        id: 101,
        content: 'You have won a prize of ₹50,000! Click http://bit.ly/claim-now',
        classification: 'SCAM',
        riskLevel: 'HIGH',
        inputType: 'text',
        category: 'prize_claim',
        createdAt: todayTime,
      ),
      _mockAnalysisJson(
        id: 102,
        content: 'Your account has been credited with ₹2,500. For details visit bank app.',
        classification: 'GENUINE',
        riskLevel: 'LOW',
        inputType: 'text',
        category: 'banking',
        riskScore: 8,
        llmConfidence: 0.92,
        indicators: [],
        explanation: 'This message appears to be from a legitimate source.',
        createdAt: todayTime.subtract(const Duration(hours: 1)),
      ),
      _mockAnalysisJson(
        id: 103,
        content: 'Screenshot verification',
        classification: 'SUSPICIOUS',
        riskLevel: 'MEDIUM',
        inputType: 'image',
        originalFilename: 'Screenshot_20261024_0930.jpg',
        category: 'screenshot',
        createdAt: todayTime.subtract(const Duration(hours: 2)),
      ),
      _mockAnalysisJson(
        id: 104,
        content: 'Job offer verification',
        classification: 'SCAM',
        riskLevel: 'HIGH',
        inputType: 'pdf',
        originalFilename: 'offer_letter.pdf',
        category: 'job_offer',
        createdAt: yesterdayTime,
      ),
      _mockAnalysisJson(
        id: 105,
        content: 'Voice note analysis',
        classification: 'SUSPICIOUS',
        riskLevel: 'MEDIUM',
        inputType: 'audio',
        originalFilename: 'audio_20261023_1812.m4a',
        category: 'audio',
        createdAt: yesterdayTime.subtract(const Duration(hours: 2)),
      ),
    ];

    callRecords = [
      _mockCallItem(
        id: 201,
        sessionId: 'session-call-01',
        riskLevel: 'HIGH',
        riskScore: 92,
        category: '+91 98765 43210',
        endedAt: todayTime,
      ),
      _mockCallItem(
        id: 202,
        sessionId: 'session-call-02',
        riskLevel: 'LOW',
        riskScore: 10,
        category: '+91 91234 56789',
        endedAt: todayTime.subtract(const Duration(hours: 1)),
      ),
      _mockCallItem(
        id: 203,
        sessionId: 'session-call-03',
        riskLevel: 'HIGH',
        riskScore: 85,
        category: '+91 81234 67890',
        endedAt: yesterdayTime,
      ),
    ];
  });

  group('ScamShield 2.0 — Phase 06 History & Analysis Details Tests', () {
    testWidgets('1. History screen renders header with neon clock badge and dual tabs', (tester) async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/analysis/history')) {
          return _jsonResponse(analysisRecords);
        }
        return http.Response('Not found', 404);
      });

      final api = ApiService(client: client, baseUri: Uri.parse('https://api.scamshield.test/api'));
      final analysisService = AnalysisService(api: api, tokenProvider: () async => 'valid-token');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: HistoryScreen(
              analysisService: analysisService,
              onSessionExpired: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('History'), findsOneWidget);
      expect(find.text('View and manage your past analyses.'), findsOneWidget);
      expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);

      // Verify Tab Toggle Pills
      expect(find.text('Analysis History'), findsWidgets);
      expect(find.text('Call History'), findsWidgets);

      // Verify Search Bar with Analysis Hint
      expect(find.text('Search by keyword, link or content...'), findsOneWidget);

      // Verify Filter Pills
      expect(find.widgetWithText(HistoryFilterPills, 'All'), findsOneWidget);
      expect(find.widgetWithText(HistoryFilterPills, 'Text'), findsOneWidget);
      expect(find.widgetWithText(HistoryFilterPills, 'Image'), findsOneWidget);
      expect(find.widgetWithText(HistoryFilterPills, 'Document'), findsOneWidget);
      expect(find.widgetWithText(HistoryFilterPills, 'Audio'), findsOneWidget);
    });

    testWidgets('2. Date grouping groups records into Today and Yesterday sections', (tester) async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/analysis/history')) {
          return _jsonResponse(analysisRecords);
        }
        return http.Response('Not found', 404);
      });

      final api = ApiService(client: client, baseUri: Uri.parse('https://api.scamshield.test/api'));
      final analysisService = AnalysisService(api: api, tokenProvider: () async => 'valid-token');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: HistoryScreen(
              analysisService: analysisService,
              onSessionExpired: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Date Section Headers
      expect(find.widgetWithText(DateSectionHeader, 'Today'), findsOneWidget);
      expect(find.widgetWithText(DateSectionHeader, 'Yesterday'), findsOneWidget);

      // Filename and Category Titles
      expect(find.text('offer_letter.pdf'), findsWidgets);
      expect(find.text('Screenshot_20261024_0930.jpg'), findsWidgets);
      expect(find.text('audio_20261023_1812.m4a'), findsWidgets);

      // Risk Badges
      expect(find.text('Scam'), findsWidgets);
      expect(find.text('Safe'), findsWidgets);
      expect(find.text('Suspicious'), findsWidgets);
    });

    testWidgets('3. Filter pills dynamically filter analysis records by content type', (tester) async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/analysis/history')) {
          return _jsonResponse(analysisRecords);
        }
        return http.Response('Not found', 404);
      });

      final api = ApiService(client: client, baseUri: Uri.parse('https://api.scamshield.test/api'));
      final analysisService = AnalysisService(api: api, tokenProvider: () async => 'valid-token');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: HistoryScreen(
              analysisService: analysisService,
              onSessionExpired: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Image filter pill
      await tester.tap(
        find.descendant(
          of: find.byType(HistoryFilterPills),
          matching: find.text('Image'),
        ),
      );
      await tester.pumpAndSettle();

      // Only Image item should be present
      expect(find.text('Screenshot_20261024_0930.jpg'), findsWidgets);
      expect(find.text('offer_letter.pdf'), findsNothing);

      // Tap Document filter pill
      await tester.tap(
        find.descendant(
          of: find.byType(HistoryFilterPills),
          matching: find.text('Document'),
        ),
      );
      await tester.pumpAndSettle();

      // Only Document item should be present
      expect(find.text('offer_letter.pdf'), findsWidgets);
      expect(find.text('Screenshot_20261024_0930.jpg'), findsNothing);

      // Tap All filter pill
      await tester.tap(
        find.descendant(
          of: find.byType(HistoryFilterPills),
          matching: find.text('All'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('offer_letter.pdf'), findsWidgets);
      expect(find.text('Screenshot_20261024_0930.jpg'), findsWidgets);
    });

    testWidgets('4. Search bar filters records and displays empty state with clear action', (tester) async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/analysis/history')) {
          return _jsonResponse(analysisRecords);
        }
        return http.Response('Not found', 404);
      });

      final api = ApiService(client: client, baseUri: Uri.parse('https://api.scamshield.test/api'));
      final analysisService = AnalysisService(api: api, tokenProvider: () async => 'valid-token');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: HistoryScreen(
              analysisService: analysisService,
              onSessionExpired: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search query that matches only one item
      await tester.enterText(find.byType(TextField), 'offer_letter');
      await tester.pumpAndSettle();

      expect(find.text('offer_letter.pdf'), findsWidgets);
      expect(find.text('Screenshot_20261024_0930.jpg'), findsNothing);

      // Enter search query that matches nothing
      await tester.enterText(find.byType(TextField), 'nonexistent_query_xyz');
      await tester.pumpAndSettle();

      expect(find.text('No matching results'), findsOneWidget);
      expect(find.text('No records found matching "nonexistent_query_xyz".'), findsOneWidget);
      expect(find.text('Clear search'), findsOneWidget);

      // Tap Clear search
      await tester.tap(find.text('Clear search'));
      await tester.pumpAndSettle();

      expect(find.text('offer_letter.pdf'), findsWidgets);
    });

    testWidgets('5. Critical: Tapping an item opens AnalysisDetailsScreen with exact record ID and fetches detail', (tester) async {
      var requestedDetailId = 0;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/analysis/history')) {
          return _jsonResponse(analysisRecords);
        }
        if (request.url.path.endsWith('/analysis/101')) {
          requestedDetailId = 101;
          return _jsonResponse(analysisRecords.firstWhere((r) => r['id'] == 101));
        }
        return http.Response('Not found', 404);
      });

      final api = ApiService(client: client, baseUri: Uri.parse('https://api.scamshield.test/api'));
      final analysisService = AnalysisService(api: api, tokenProvider: () async => 'valid-token');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: HistoryScreen(
              analysisService: analysisService,
              onSessionExpired: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the first item (ID 101: Prize claim message)
      await tester.tap(find.text('Prize Claim message'));
      await tester.pumpAndSettle();

      // Verify that the exact endpoint GET /analysis/101 was invoked
      expect(requestedDetailId, 101);

      // Verify AnalysisDetailsScreen loaded
      expect(find.text('Analysis Details'), findsOneWidget);
      expect(find.text('Scam Detected'), findsOneWidget);
      expect(find.text('This message shows multiple scam indicators.'), findsOneWidget);

      // Verify Content Card
      expect(find.text('Content'), findsOneWidget);
      expect(find.textContaining('You have won a prize of ₹50,000!'), findsOneWidget);

      // Verify Details Table
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('94%'), findsOneWidget);
      expect(find.text('1 Suspicious Link'), findsOneWidget);

      // Verify Explanation
      expect(find.text('Explanation'), findsOneWidget);
      expect(find.textContaining('This message contains a prize claim with urgent action.'), findsOneWidget);

      // Scroll down to Recommendations Card
      await tester.ensureVisible(find.text('Recommendation'));
      await tester.pumpAndSettle();

      // Verify Multilingual Recommendations (English, Hindi, Telugu)
      expect(find.text('Recommendation'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('हिंदी'), findsOneWidget);
      expect(find.text('తెలుగు'), findsOneWidget);

      // Switch language to Telugu
      await tester.ensureVisible(find.text('తెలుగు'));
      await tester.tap(find.text('తెలుగు'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ఈ సందేశంలోని ఏ లింక్‌లను క్లిక్ చేయవద్దు.'), findsOneWidget);

      // Switch language to Hindi
      await tester.ensureVisible(find.text('हिंदी'));
      await tester.tap(find.text('हिंदी'));
      await tester.pumpAndSettle();
      expect(find.textContaining('इस संदेश में किसी भी लिंक पर क्लिक न करें।'), findsOneWidget);

      // Verify Bottom Actions
      await tester.ensureVisible(find.text('Save to History'));
      await tester.pumpAndSettle();

      expect(find.text('Analyze Similar'), findsOneWidget);
      expect(find.text('Save to History'), findsOneWidget);

      // Tap Save to History button and verify honest confirmation SnackBar
      await tester.tap(find.text('Save to History'));
      await tester.pump();
      expect(find.textContaining('Analysis #101 is automatically preserved in your History.'), findsOneWidget);
      await tester.pumpAndSettle();

      // Tap Back button to return to History tab
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Confirm returned to History screen cleanly
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Analysis History'), findsWidgets);
    });

    testWidgets('6. Call History tab renders calls, filters, and navigates to exact call summary', (tester) async {
      var requestedCallSession = '';
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/analysis/history')) {
          return _jsonResponse(analysisRecords);
        }
        if (request.url.path.contains('/calls/history')) {
          return _jsonResponse({
            'items': callRecords,
            'total': callRecords.length,
            'page': 1,
            'limit': 20,
            'has_next': false,
          });
        }
        if (request.url.path.contains('/calls/session-call-01')) {
          requestedCallSession = 'session-call-01';
          return _jsonResponse(_mockCallDetail(id: 201, sessionId: 'session-call-01'));
        }
        return http.Response('Not found', 404);
      });

      final api = ApiService(client: client, baseUri: Uri.parse('https://api.scamshield.test/api'));
      final analysisService = AnalysisService(api: api, tokenProvider: () async => 'valid-token');
      final callHistoryService = CallHistoryService(api: api, tokenProvider: () async => 'valid-token');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
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

      // Switch to Call History tab
      await tester.tap(find.text('Call History').last);
      await tester.pumpAndSettle();

      // Verify Call History Subtitle & Search Hint
      expect(find.text('View and manage your past call checks.'), findsOneWidget);
      expect(find.text('Search by phone number or contact...'), findsOneWidget);

      // Verify Caller phone numbers and items rendered
      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.text('+91 91234 56789'), findsOneWidget);
      expect(find.text('+91 81234 67890'), findsOneWidget);

      // Tap first call item to open Call Summary
      await tester.tap(find.text('+91 98765 43210'));
      await tester.pumpAndSettle();

      // Verify exact call session was requested
      expect(requestedCallSession, 'session-call-01');
      expect(find.text('Call Summary'), findsOneWidget);

      // Tap Back to return to Call History
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Call History'), findsWidgets);
      expect(find.text('+91 98765 43210'), findsOneWidget);
    });

    testWidgets('7. Responsive Layout: renders without overflow on narrow 320px viewport in dark and light themes', (tester) async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/analysis/history')) {
          return _jsonResponse(analysisRecords);
        }
        return http.Response('Not found', 404);
      });

      final api = ApiService(client: client, baseUri: Uri.parse('https://api.scamshield.test/api'));
      final analysisService = AnalysisService(api: api, tokenProvider: () async => 'valid-token');

      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Test Light Theme on Narrow Screen
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: HistoryScreen(
              analysisService: analysisService,
              onSessionExpired: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('History'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Test Dark Theme on Narrow Screen
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: HistoryScreen(
              analysisService: analysisService,
              onSessionExpired: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('History'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
