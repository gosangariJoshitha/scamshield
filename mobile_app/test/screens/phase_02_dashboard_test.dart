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
      expect(find.text('Your Security Overview'), findsOneWidget);
      expect(find.text('Threat Trends'), findsOneWidget);
      expect(find.text('Recent Analyses'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Daily Safety Tips'), findsOneWidget);
    });

    testWidgets('Security Overview filter responds dynamically and updates subtitle', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHomeTestWidget());
      await tester.pumpAndSettle();

      // Default filter is 'Last 30 Days'
      expect(find.text('Last 30 Days'), findsWidgets);
      expect(find.text('— from last month'), findsWidgets);

      // Open filter popup menu
      await tester.tap(find.text('Last 30 Days').first);
      await tester.pumpAndSettle();

      // Select 'Today'
      expect(find.text('Today'), findsOneWidget);
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      // Verify filter label and subtitle updated
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('— for today'), findsWidgets);
    });

    testWidgets('Threat Trends toggles between Daily, Weekly, and Monthly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHomeTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);

      // Switch to Daily
      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();
      expect(find.text('Analysis categories for Daily activity'), findsOneWidget);

      // Switch to Weekly
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();
      expect(find.text('Analysis categories for Weekly activity'), findsOneWidget);

      // Switch to Monthly
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();
      expect(find.text('Analysis categories for Monthly activity'), findsOneWidget);
    });

    testWidgets('Daily Safety Tips is a horizontally swipeable PageView with active dots', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHomeTestWidget());
      await tester.pumpAndSettle();

      // Scroll to Daily Safety Tips section
      await tester.scrollUntilVisible(
        find.text('Daily Safety Tips'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // First tip should be visible
      expect(find.text('Be careful with urgent KYC requests'), findsOneWidget);

      // Swipe left to advance to next tip
      await tester.drag(
        find.text('Be careful with urgent KYC requests'),
        const Offset(-400, 0),
      );
      await tester.pumpAndSettle();

      // Second tip should now be visible
      expect(find.text('Verify suspicious payment links'), findsOneWidget);
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

      // Check banner and Live Call Guardian section for real call count
      expect(find.textContaining('5 incoming calls analyzed & guarded'), findsOneWidget);
      expect(find.textContaining('5 calls analyzed & protected'), findsOneWidget);
    });

    testWidgets('Notification Center opens, displays alerts, and Clear All clears unread badge', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHomeTestWidget());
      await tester.pumpAndSettle();

      // Tap notification bell in AppBar
      final notificationIcon = find.byTooltip('Notifications');
      expect(notificationIcon, findsOneWidget);
      await tester.tap(notificationIcon);
      await tester.pumpAndSettle();

      // Notification modal bottom sheet should appear
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);

      // Tap Clear All
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      // Close modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Unread badge count should now be 0 (no badge label visible)
      expect(find.byType(Badge), findsNothing);
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
