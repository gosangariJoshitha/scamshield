import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/models/app_notification.dart';
import 'package:scamshield_guardian/models/user.dart';
import 'package:scamshield_guardian/native/call_bridge.dart';
import 'package:scamshield_guardian/screens/home/home_screen.dart';
import 'package:scamshield_guardian/screens/home/widgets/cyber_helpline_card.dart';
import 'package:scamshield_guardian/screens/notifications/notification_screen.dart';
import 'package:scamshield_guardian/services/analysis_service.dart';
import 'package:scamshield_guardian/services/api_service.dart';
import 'package:scamshield_guardian/services/call_history_service.dart';
import 'package:scamshield_guardian/services/notification_service.dart';

class TestCallBridge extends CallBridge {
  String? lastDialedNumber;

  @override
  Future<bool> launchDialer(String phoneNumber) async {
    lastDialedNumber = phoneNumber;
    return true;
  }

  @override
  Future<CallGuardianStatus> getCallGuardianStatus() async {
    return const CallGuardianStatus(
      available: true,
      supported: true,
      phoneStatePermissionGranted: true,
      notificationsPermissionGranted: true,
      enabled: true,
      serviceRunning: true,
      callState: 'IDLE',
      serviceError: null,
      callScreeningAvailable: true,
      callScreeningEnabled: true,
      incomingCallDetection: true,
      outgoingCallDetection: false,
      activeCallStateDetection: true,
      audioCaptureAvailable: true,
      audioPermissionGranted: true,
      audioProtectionEnabled: true,
      audioState: 'IDLE',
      audioSource: 'MIC',
      audioRoute: 'SPEAKER',
      audioReason: 'NORMAL',
      audioChunksCreated: 0,
      audioChunksDropped: 0,
    );
  }

  @override
  Stream<CallGuardianStatus> get guardianStatusChanges =>
      Stream.value(const CallGuardianStatus(
        available: true,
        supported: true,
        phoneStatePermissionGranted: true,
        notificationsPermissionGranted: true,
        enabled: true,
        serviceRunning: true,
        callState: 'IDLE',
        serviceError: null,
        callScreeningAvailable: true,
        callScreeningEnabled: true,
        incomingCallDetection: true,
        outgoingCallDetection: false,
        activeCallStateDetection: true,
        audioCaptureAvailable: true,
        audioPermissionGranted: true,
        audioProtectionEnabled: true,
        audioState: 'IDLE',
        audioSource: 'MIC',
        audioRoute: 'SPEAKER',
        audioReason: 'NORMAL',
        audioChunksCreated: 0,
        audioChunksDropped: 0,
      ));

  @override
  Stream<GuardianCallEvent> get callEvents => const Stream.empty();
}

class TestNotificationService extends NotificationService {
  TestNotificationService({
    required super.api,
    List<AppNotification>? initialNotifications,
  }) : notifications = initialNotifications ??
            [
              AppNotification(
                id: 1,
                userId: 101,
                title: 'High Risk Alert',
                message: 'Analysis #101 flagged suspicious URL link.',
                type: 'SECURITY_ALERT',
                isRead: false,
                createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
              ),
              AppNotification(
                id: 2,
                userId: 101,
                title: 'Safe Verification',
                message: 'SMS from official bank verified safe.',
                type: 'ANALYSIS_COMPLETE',
                isRead: true,
                createdAt: DateTime.now().subtract(const Duration(hours: 1)),
              ),
            ];

  final List<AppNotification> notifications;
  final List<int> deletedNotificationIds = [];
  bool clearAllCalled = false;

  @override
  Future<NotificationListResult> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final filtered = unreadOnly
        ? notifications.where((n) => !n.isRead).toList()
        : notifications;
    return NotificationListResult(
      items: List.from(filtered),
      total: filtered.length,
      unreadCount: notifications.where((n) => !n.isRead).length,
      page: page,
      limit: limit,
      hasNext: false,
    );
  }

  @override
  Future<int> getUnreadCount() async {
    return notifications.where((n) => !n.isRead).length;
  }

  @override
  Future<AppNotification> markAsRead(int notificationId) async {
    final idx = notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      notifications[idx] = notifications[idx].copyWith(isRead: true);
      return notifications[idx];
    }
    throw const ApiException('Notification not found');
  }

  @override
  Future<int> markAllAsRead() async {
    int count = 0;
    for (int i = 0; i < notifications.length; i++) {
      if (!notifications[i].isRead) {
        notifications[i] = notifications[i].copyWith(isRead: true);
        count++;
      }
    }
    return count;
  }

  @override
  Future<bool> deleteNotification(int notificationId) async {
    deletedNotificationIds.add(notificationId);
    notifications.removeWhere((n) => n.id == notificationId);
    return true;
  }

  @override
  Future<int> clearAll() async {
    clearAllCalled = true;
    final count = notifications.length;
    notifications.clear();
    return count;
  }
}

ApiService _createTestApi() {
  return ApiService(
    client: MockClient((request) async {
      if (request.url.path.endsWith('/analysis/dashboard')) {
        return http.Response(
          jsonEncode({
            'total_analyses': 5,
            'scams_detected': 2,
            'safe_messages': 3,
            'high_risk': 2,
          }),
          200,
        );
      }
      if (request.url.path.contains('/calls/history')) {
        return http.Response(
          jsonEncode({
            'items': [],
            'total': 0,
            'page': 1,
            'limit': 1,
            'has_next': false,
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/analysis/history')) {
        return http.Response(jsonEncode([]), 200);
      }
      return http.Response(jsonEncode({}), 200);
    }),
    baseUri: Uri.parse('https://api.example.test/api'),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testUser = User(
    id: 101,
    fullName: 'Joshitha Gosangari',
    email: 'joshitha@example.com',
    role: 'user',
    isActive: true,
    emailVerified: true,
    twoFactorEnabled: false,
  );

  const testUser2 = User(
    id: 202,
    fullName: 'Other User',
    email: 'other@example.com',
    role: 'user',
    isActive: true,
    emailVerified: true,
    twoFactorEnabled: false,
  );

  group('Phase 02: Notification Lifecycle & Persistence Tests', () {
    testWidgets('NotificationScreen loads genuine notifications and unread badge', (tester) async {
      final api = _createTestApi();
      final notifService = TestNotificationService(api: api);

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationScreen(notificationService: notifService),
        ),
      );
      await tester.pumpAndSettle();

      // Verify authoritative notifications are displayed
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('High Risk Alert'), findsOneWidget);
      expect(find.text('Analysis #101 flagged suspicious URL link.'), findsOneWidget);
      expect(find.text('Safe Verification'), findsOneWidget);
      expect(find.text('SMS from official bank verified safe.'), findsOneWidget);
    });

    testWidgets('Tapping single notification delete button removes it and updates server', (tester) async {
      final api = _createTestApi();
      final notifService = TestNotificationService(api: api);

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationScreen(notificationService: notifService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('High Risk Alert'), findsOneWidget);

      // Find and tap the individual delete icon button on the first notification
      final deleteIcons = find.byTooltip('Clear notification');
      expect(deleteIcons, findsWidgets);
      await tester.tap(deleteIcons.first);
      await tester.pumpAndSettle();

      // Verify it was deleted on service and removed from UI
      expect(notifService.deletedNotificationIds, contains(1));
      expect(find.text('High Risk Alert'), findsNothing);
      expect(find.text('Notification cleared'), findsOneWidget);
    });

    testWidgets('Clear All triggers confirmation dialog and empties notification list', (tester) async {
      final api = _createTestApi();
      final notifService = TestNotificationService(api: api);

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationScreen(notificationService: notifService),
        ),
      );
      await tester.pumpAndSettle();

      // Tap clear all icon in AppBar
      final clearAllIcon = find.byTooltip('Clear all notifications');
      expect(clearAllIcon, findsOneWidget);
      await tester.tap(clearAllIcon);
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Clear all notifications?'), findsOneWidget);
      expect(
        find.text(
          'This will remove your notification history. Your analysis and call records will remain safely intact.',
        ),
        findsOneWidget,
      );

      // Confirm clear
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      // Verify clearAll called on service and empty state shown
      expect(notifService.clearAllCalled, isTrue);
      expect(notifService.notifications.isEmpty, isTrue);
      expect(find.text('No notifications yet'), findsOneWidget);
      expect(find.text('All notifications cleared'), findsOneWidget);
    });

    testWidgets('Cleared state persists across reload and reopening', (tester) async {
      final api = _createTestApi();
      final notifService = TestNotificationService(api: api);
      await notifService.clearAll();

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationScreen(notificationService: notifService),
        ),
      );
      await tester.pumpAndSettle();

      // Pull down to refresh or re-fetch
      await notifService.getNotifications();
      expect(notifService.notifications.isEmpty, isTrue);
      expect(find.text('No notifications yet'), findsOneWidget);
    });
  });

  group('Phase 02: Cyber Helpline 1930 & Dismissal Persistence', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    testWidgets('CyberHelplineCard displays 1930 and opens details dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CyberHelplineCard(
              onDial: () async {},
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify number 1930, 24/7, and description
      expect(find.text('🇮🇳 Cyber Helpline: 1930'), findsOneWidget);
      expect(find.text('24/7'), findsOneWidget);
      expect(find.text('Call 1930'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);

      // Tap Details
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();

      // Verify details dialog content
      expect(find.text('National Cyber Helpline 1930'), findsOneWidget);
      expect(find.text('The Golden Hour Rule:'), findsOneWidget);
      expect(find.text('Understood'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();
      expect(find.text('Understood'), findsNothing);

      // Tap Dismiss button
      await tester.tap(find.byTooltip('Dismiss helpline banner'));
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
    });

    testWidgets('Tapping Call 1930 on HelplineCard invokes dial callback', (tester) async {
      bool dialed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CyberHelplineCard(
              onDial: () async => dialed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Call 1930'));
      await tester.pumpAndSettle();
      expect(dialed, isTrue);
    });

    testWidgets('HomeScreen integrates Cyber Helpline and persists dismissal per user', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      FlutterSecureStorage.setMockInitialValues({});
      final api = _createTestApi();
      final fakeBridge = TestCallBridge();
      final notifService = TestNotificationService(api: api);
      final analysisService = AnalysisService(
        api: api,
        tokenProvider: () async => 'test-jwt',
      );
      final callHistoryService = CallHistoryService(
        api: api,
        tokenProvider: () async => 'test-jwt',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            user: testUser,
            analysisService: analysisService,
            callHistoryService: callHistoryService,
            notificationService: notifService,
            callBridge: fakeBridge,
            onLogout: () async {},
            onSessionExpired: () async {},
            isDarkMode: false,
            onToggleTheme: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Helpline banner is visible on dashboard
      expect(find.text('🇮🇳 Cyber Helpline: 1930'), findsOneWidget);

      // Tap Call 1930 button
      await tester.tap(find.text('Call 1930'));
      await tester.pumpAndSettle();

      // Verify phone dialer was invoked with 1930
      expect(fakeBridge.lastDialedNumber, '1930');
      expect(find.text('Opening phone dialer for National Cyber Helpline 1930...'), findsOneWidget);

      // Verify helpline card is dismissed from UI
      expect(find.text('🇮🇳 Cyber Helpline: 1930'), findsNothing);

      // Pump new HomeScreen instance for same user to test persistent dismissal
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            user: testUser,
            analysisService: analysisService,
            callHistoryService: callHistoryService,
            notificationService: notifService,
            callBridge: fakeBridge,
            onLogout: () async {},
            onSessionExpired: () async {},
            isDarkMode: false,
            onToggleTheme: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Helpline banner should remain dismissed for testUser
      expect(find.text('🇮🇳 Cyber Helpline: 1930'), findsNothing);

      // Switch to testUser2 (account isolation): helpline banner should be visible for user 2
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            user: testUser2,
            analysisService: analysisService,
            callHistoryService: callHistoryService,
            notificationService: notifService,
            callBridge: fakeBridge,
            onLogout: () async {},
            onSessionExpired: () async {},
            isDarkMode: false,
            onToggleTheme: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('🇮🇳 Cyber Helpline: 1930'), findsOneWidget);
    });
  });
}
