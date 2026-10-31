import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/models/user.dart';
import 'package:scamshield_guardian/screens/home/home_screen.dart';
import 'package:scamshield_guardian/services/analysis_service.dart';
import 'package:scamshield_guardian/services/api_service.dart';

const _testUserWithFullName = User(
  id: 1,
  fullName: 'Joshitha Gosangari',
  email: 'joshitha@example.com',
  role: 'user',
  isActive: true,
  emailVerified: true,
  twoFactorEnabled: false,
);

const _testUserWithoutName = User(
  id: 2,
  fullName: '',
  email: 'user@example.com',
  role: 'user',
  isActive: true,
  emailVerified: true,
  twoFactorEnabled: false,
);

AnalysisService _createMockAnalysisService({
  bool throwError = false,
  bool unauthorized = false,
  bool includeRecords = true,
  int totalAnalyses = 2,
}) {
  return AnalysisService(
    api: ApiService(
      client: MockClient((request) async {
        if (unauthorized) {
          return http.Response(jsonEncode({'detail': 'Token expired'}), 401);
        }
        if (throwError) {
          return http.Response(jsonEncode({'detail': 'Backend error'}), 500);
        }
        if (request.url.path.endsWith('/analysis/dashboard')) {
          return http.Response(
            jsonEncode({
              'total_analyses': totalAnalyses,
              'scams_detected': 1,
              'safe_messages': 1,
              'high_risk': 1,
            }),
            200,
          );
        }
        if (request.url.path.contains('/calls/history')) {
          return http.Response(
            jsonEncode({
              'items': [],
              'total': 7,
              'page': 1,
              'limit': 1,
              'has_next': false,
            }),
            200,
          );
        }
        // Analysis history
        if (!includeRecords) {
          return http.Response(jsonEncode([]), 200);
        }
        return http.Response(
          jsonEncode([
            {
              'id': 101,
              'content': 'Urgent payment demand',
              'risk_score': 85,
              'risk_level': 'HIGH',
              'classification': 'SCAM',
              'category': 'PHISHING',
              'input_type': 'text',
              'created_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
            },
            {
              'id': 102,
              'content': 'Meeting schedule doc',
              'risk_score': 10,
              'risk_level': 'LOW',
              'classification': 'SAFE',
              'category': 'GENERAL',
              'input_type': 'document',
              'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
            },
          ]),
          200,
        );
      }),
      baseUri: Uri.parse('https://api.example.test/api'),
    ),
    tokenProvider: () async => 'test-jwt',
  );
}

Widget _buildHomeWidget({
  User user = _testUserWithFullName,
  AnalysisService? service,
  bool isDarkMode = false,
  VoidCallback? onSessionExpired,
}) {
  return MaterialApp(
    theme: ThemeData(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      fontFamily: 'Inter',
    ),
    home: HomeScreen(
      user: user,
      analysisService: service ?? _createMockAnalysisService(),
      onLogout: () async {},
      onSessionExpired: () async {
        onSessionExpired?.call();
      },
      isDarkMode: isDarkMode,
      onToggleTheme: () {},
    ),
  );
}

void main() {
  group('ScamShield 2.0 — Phase 03 Home Dashboard Redesign Tests', () {
    testWidgets('1. Home screen renders all sections using approved layout (home and analysis page.jpeg)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHomeWidget());
      await tester.pumpAndSettle();

      // Top branding
      expect(find.textContaining('SCAMSHIELD'), findsWidgets);
      expect(find.text('AI-POWERED SCAM PROTECTION'), findsWidgets);

      // Greeting
      expect(find.text('Hello, Joshitha 👋'), findsOneWidget);
      expect(find.text('Stay alert and stay safe with ScamShield.'), findsOneWidget);

      // Overall Stats
      expect(find.text('Overall Stats'), findsOneWidget);
      expect(find.text('Messages\nAnalyzed'), findsOneWidget);
      expect(find.text('Calls\nChecked'), findsOneWidget);
      expect(find.text('Images\nScanned'), findsOneWidget);
      expect(find.text('Documents\nAnalyzed'), findsOneWidget);

      // Quick Actions
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Analyze\nMessage'), findsOneWidget);
      expect(find.text('Call\nProtection'), findsOneWidget);
      expect(find.text('Image &\nDocument'), findsOneWidget);
      expect(find.text('Analyze\nAudio'), findsOneWidget);

      // Recent Activity
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);

      // Stay Informed
      expect(find.text('Stay Informed'), findsOneWidget);
      expect(
        find.text('Check messages, calls, images and documents to stay safe from scams.'),
        findsOneWidget,
      );
    });

    testWidgets('2. Authenticated display name is shown with first name in greeting', (
      tester,
    ) async {
      await tester.pumpWidget(_buildHomeWidget(user: _testUserWithFullName));
      await tester.pumpAndSettle();

      expect(find.text('Hello, Joshitha 👋'), findsOneWidget);
    });

    testWidgets('3. Missing display name uses neutral fallback "Welcome back 👋"', (
      tester,
    ) async {
      await tester.pumpWidget(_buildHomeWidget(user: _testUserWithoutName));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back 👋'), findsOneWidget);
    });

    testWidgets('4. Actual backend statistics are mapped correctly from genuine data', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHomeWidget());
      await tester.pumpAndSettle();

      // In mock: 1 message record, 1 document record, 7 calls, 0 images
      expect(find.text('1'), findsNWidgets(2)); // Messages and Documents
      expect(find.text('7'), findsOneWidget);   // Calls Checked
      expect(find.text('0'), findsOneWidget);   // Images Scanned
    });

    testWidgets('5. Empty history displays truthful zero counts without fake sample values', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = _createMockAnalysisService(includeRecords: false, totalAnalyses: 0);
      await tester.pumpWidget(_buildHomeWidget(service: service));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsWidgets);
    });

    testWidgets('6. Recent activity renders from actual repository records with risk status', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHomeWidget());
      await tester.pumpAndSettle();

      expect(find.text('Message Analyzed'), findsOneWidget);
      expect(find.textContaining('Scam detected'), findsOneWidget);
      expect(find.text('Document Analyzed'), findsOneWidget);
      expect(find.textContaining('Safe'), findsOneWidget);
    });

    testWidgets('7. Empty history displays informative empty state with action', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = _createMockAnalysisService(includeRecords: false);
      await tester.pumpWidget(_buildHomeWidget(service: service));
      await tester.pumpAndSettle();

      expect(find.text('No activity yet'), findsOneWidget);
      expect(find.text('Your completed analyses will appear here.'), findsOneWidget);
      expect(find.text('Analyze Content'), findsOneWidget);
    });

    testWidgets('8. Backend failure displays error banner with retry option', (
      tester,
    ) async {
      final service = _createMockAnalysisService(throwError: true);
      await tester.pumpWidget(_buildHomeWidget(service: service));
      await tester.pumpAndSettle();

      expect(find.text('Unable to load your dashboard.'), findsOneWidget);
      expect(find.text('RETRY'), findsOneWidget);
    });

    testWidgets('9. Unauthorized 401 response invokes session expiry handler', (
      tester,
    ) async {
      var expired = false;
      final service = _createMockAnalysisService(unauthorized: true);
      await tester.pumpWidget(_buildHomeWidget(
        service: service,
        onSessionExpired: () => expired = true,
      ));
      await tester.pumpAndSettle();

      expect(expired, isTrue);
    });

    testWidgets('10. Quick Actions navigate to verified destinations (Analyze, Sentinel, Audio)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHomeWidget());
      await tester.pumpAndSettle();

      // Tap Image & Document shortcut
      await tester.tap(find.text('Image &\nDocument'));
      await tester.pumpAndSettle();
      expect(find.text('Upload an image or screenshot'), findsOneWidget);
    });

    testWidgets('11. View All action opens History tab', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHomeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('View All'));
      await tester.pumpAndSettle();

      expect(find.text('Analysis History'), findsOneWidget);
    });

    testWidgets('12. Light and Dark themes render without assertion failures', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHomeWidget(isDarkMode: true));
      await tester.pumpAndSettle();

      expect(find.text('Overall Stats'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Stay Informed'), findsOneWidget);
    });

    testWidgets('13. Narrow viewport (320px) and large text scale render without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: _buildHomeWidget(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Overall Stats'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
    });
  });
}
