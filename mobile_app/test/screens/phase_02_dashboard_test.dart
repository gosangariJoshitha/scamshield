import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/models/user.dart';
import 'package:scamshield_guardian/screens/home/home_screen.dart';
import 'package:scamshield_guardian/services/analysis_service.dart';
import 'package:scamshield_guardian/services/api_service.dart';

const _testUser = User(
  id: 1,
  fullName: 'Joshitha Gosangari',
  email: 'joshitha@example.com',
  role: 'user',
  isActive: true,
  emailVerified: true,
  twoFactorEnabled: false,
);

AnalysisService _createMockAnalysisService({
  int totalAnalyses = 4,
  int scamsDetected = 2,
  int safeMessages = 2,
  int highRisk = 1,
  int totalCalls = 3,
}) {
  return AnalysisService(
    api: ApiService(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/analysis/dashboard')) {
          return http.Response(
            jsonEncode({
              'total_analyses': totalAnalyses,
              'scams_detected': scamsDetected,
              'safe_messages': safeMessages,
              'high_risk': highRisk,
            }),
            200,
          );
        }
        if (request.url.path.contains('/calls/history')) {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'call_id': 'call_1',
                  'phone_number': '+919876543210',
                  'contact_name': 'Suspected Bank Agent',
                  'call_type': 'INCOMING',
                  'status': 'COMPLETED',
                  'risk_score': 85,
                  'risk_level': 'HIGH',
                  'created_at': DateTime.now().toIso8601String(),
                }
              ],
              'total': totalCalls,
              'page': 1,
              'limit': 1,
              'has_next': false,
            }),
            200,
          );
        }
        // Analysis history list
        final now = DateTime.now();
        return http.Response(
          jsonEncode([
            {
              'id': 101,
              'content': 'Urgent KYC update required today',
              'risk_score': 85,
              'risk_level': 'HIGH',
              'classification': 'SCAM',
              'category': 'PHISHING',
              'input_type': 'text',
              'created_at': now.toIso8601String(),
              'explanation': 'Phishing attempt detected.',
              'recommended_action': 'Do not click the link.',
            },
            {
              'id': 102,
              'content': 'Your electricity bill is overdue',
              'risk_score': 60,
              'risk_level': 'MEDIUM',
              'classification': 'SUSPICIOUS',
              'category': 'UTILITY_FRAUD',
              'input_type': 'text',
              'created_at': now.subtract(const Duration(days: 3)).toIso8601String(),
              'explanation': 'Unverified billing claim.',
              'recommended_action': 'Verify via official electricity board portal.',
            },
            {
              'id': 103,
              'content': 'Meeting agenda for tomorrow',
              'risk_score': 10,
              'risk_level': 'LOW',
              'classification': 'SAFE',
              'category': 'GENERAL',
              'input_type': 'text',
              'created_at': now.subtract(const Duration(days: 15)).toIso8601String(),
              'explanation': 'Clean business message.',
              'recommended_action': 'No action needed.',
            },
            {
              'id': 104,
              'content': 'Grocery store receipt',
              'risk_score': 5,
              'risk_level': 'LOW',
              'classification': 'SAFE',
              'category': 'RECEIPT',
              'input_type': 'image',
              'created_at': now.subtract(const Duration(days: 45)).toIso8601String(),
              'explanation': 'Standard grocery receipt.',
              'recommended_action': 'Safe to keep.',
            },
          ]),
          200,
        );
      }),
      baseUri: Uri.parse('https://api.example.test/api'),
    ),
    tokenProvider: () async => 'test-bearer-token',
  );
}

Widget _buildHomeTestWidget({
  bool isDarkMode = true,
  int totalCalls = 3,
}) {
  return MaterialApp(
    theme: ThemeData(brightness: isDarkMode ? Brightness.dark : Brightness.light),
    home: HomeScreen(
      user: _testUser,
      analysisService: _createMockAnalysisService(totalCalls: totalCalls),
      onLogout: () async {},
      onSessionExpired: () async {},
      isDarkMode: isDarkMode,
      onToggleTheme: () {},
    ),
  );
}

void main() {
  group('Phase 2: Home Dashboard & Security Overview Tests', () {
    testWidgets('Dashboard renders user greeting and prominent section headers', (
      tester,
    ) async {
      await tester.pumpWidget(_buildHomeTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Joshitha 👋'), findsOneWidget);
      expect(find.text('Overall Stats'), findsOneWidget);
      expect(find.text('AI Threat Defence'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Stay Informed'), findsOneWidget);
    });

    testWidgets('Security Overview displays Lifetime Overview filter tag', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHomeTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Lifetime Overview'), findsOneWidget);
      expect(find.text('Overall Stats'), findsOneWidget);
    });

    testWidgets('Quick Actions renders 4 threat channels', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHomeTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Text & Links'), findsOneWidget);
      expect(find.text('Live Guard'), findsOneWidget);
      expect(find.text('QR & PDF'), findsOneWidget);
      expect(find.text('Voice AI'), findsOneWidget);
    });

    testWidgets('Stay Informed card renders security guidance', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHomeTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Stay Informed'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Stay Informed'), findsOneWidget);
    });

    testWidgets('Calls analyzed count is displayed on the dashboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHomeTestWidget(totalCalls: 5));
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
      expect(find.text('Calls\nChecked'), findsOneWidget);
    });

    testWidgets('Notification Center opens and displays title', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHomeTestWidget());
      await tester.pumpAndSettle();

      final notificationIcon = find.byTooltip('Notifications');
      expect(notificationIcon, findsOneWidget);
      await tester.tap(notificationIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('Dashboard does not overflow on a narrow 320px phone viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHomeTestWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Dashboard adapts with large text scaling without RenderFlex errors', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: _buildHomeTestWidget(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
