import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_guardian/models/app_notification.dart';
import 'package:scamshield_guardian/models/community_report_model.dart';
import 'package:scamshield_guardian/models/user.dart';
import 'package:scamshield_guardian/native/call_bridge.dart';
import 'package:scamshield_guardian/screens/about/about_screen.dart';
import 'package:scamshield_guardian/screens/community/community_screen.dart';
import 'package:scamshield_guardian/screens/help/help_support_screen.dart';
import 'package:scamshield_guardian/screens/notifications/notification_screen.dart';
import 'package:scamshield_guardian/screens/privacy/privacy_center_screen.dart';
import 'package:scamshield_guardian/screens/profile/profile_screen.dart';
import 'package:scamshield_guardian/screens/settings/settings_screen.dart';
import 'package:scamshield_guardian/services/api_service.dart';
import 'package:scamshield_guardian/services/auth_service.dart';
import 'package:scamshield_guardian/services/community_service.dart';
import 'package:scamshield_guardian/services/notification_service.dart';

class MockApiService extends ApiService {}

class FakeCallBridge extends CallBridge {
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
  Future<void> openAppSettings() async {}
}

class FakeAuthService extends AuthService {
  FakeAuthService() : super(api: MockApiService());

  bool loggedOut = false;
  bool accountDeleted = false;

  @override
  Future<void> logout() async {
    loggedOut = true;
  }

  @override
  Future<void> deleteAccount() async {
    accountDeleted = true;
  }
}

class FakeNotificationService extends NotificationService {
  FakeNotificationService()
      : super(api: MockApiService(), authService: FakeAuthService());

  final List<AppNotification> notifications = [
    AppNotification(
      id: 1,
      userId: 101,
      title: 'Suspicious Call Blocked',
      message: 'Incoming call from +919876543210 identified as high-risk imposter scam.',
      type: 'CALL_ALERT',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    AppNotification(
      id: 2,
      userId: 101,
      title: 'Analysis Complete',
      message: 'SMS message verified as legitimate bank communication.',
      type: 'ANALYSIS_COMPLETE',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  @override
  Future<NotificationListResult> getNotifications({int page = 1, int limit = 20, bool unreadOnly = false}) async {
    final filtered = unreadOnly ? notifications.where((n) => !n.isRead).toList() : notifications;
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
  Future<int> clearAll() async {
    final count = notifications.length;
    notifications.clear();
    return count;
  }
}

class FakeCommunityService extends CommunityService {
  FakeCommunityService()
      : super(api: MockApiService(), authService: FakeAuthService());

  final List<CommunityReportModel> reports = [
    CommunityReportModel(
      id: 1,
      content: 'Electricity bill disconnection threat link asking to pay via APK.',
      category: 'SMS Phishing',
      reporterName: 'Joshitha',
      status: 'VERIFIED',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  @override
  Future<List<CommunityReportModel>> getCommunityReports() async {
    return List.from(reports);
  }

  @override
  Future<CommunityReportModel> submitReport({
    required String content,
    required String category,
    String? description,
    String? evidence,
    int? analysisId,
  }) async {
    final report = CommunityReportModel(
      id: reports.length + 1,
      content: content,
      category: category,
      description: description,
      evidence: evidence,
      analysisId: analysisId,
      reporterName: 'Joshitha',
      status: 'PENDING',
      createdAt: DateTime.now(),
    );
    reports.insert(0, report);
    return report;
  }
}

void main() {
  const testUser = User(
    id: 101,
    fullName: 'Joshitha',
    email: 'joshitha@scamshield.ai',
    role: 'USER',
    isActive: true,
    emailVerified: true,
    twoFactorEnabled: false,
    emailNotifications: true,
  );

  group('Phase 08 - More Screen (Landing)', () {
    testWidgets('renders user profile header, brand card, and navigation tiles', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            user: testUser,
            isDarkMode: false,
            onToggleTheme: () {},
            onLogout: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Profile Header
      expect(find.text('Joshitha'), findsOneWidget);
      expect(find.text('Stay safe. Stay informed.'), findsOneWidget);

      // Brand Card
      expect(find.text('ScamShield'), findsOneWidget);
      expect(find.text('Smarter protection. Safer you.'), findsOneWidget);

      // Navigation Tiles
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Privacy & Security'), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('shows logout confirmation dialog and executes logout callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool logoutTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            user: testUser,
            isDarkMode: false,
            onToggleTheme: () {},
            onLogout: () async {
              logoutTriggered = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Logout tile
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Check Panel 7 modal dialog contents
      expect(find.text('Log out?'), findsOneWidget);
      expect(
        find.text('You will be signed out from your account. You\'ll need to log in again to access ScamShield.'),
        findsOneWidget,
      );
      expect(find.text('Log out'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap 'Log out' button inside dialog
      await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
      await tester.pumpAndSettle();

      expect(logoutTriggered, isTrue);
    });
  });

  group('Phase 08 - Settings Screen', () {
    testWidgets('renders App Preferences, Call Protection, and General sections', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool themeToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            isDarkMode: false,
            onToggleTheme: () => themeToggled = true,
            onOpenGuardian: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('App Preferences'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Floating Guardian Button'), findsOneWidget);

      expect(find.text('Call Protection'), findsOneWidget);
      expect(find.text('Call Analysis Settings'), findsOneWidget);
      expect(find.text('Auto-Answer (if supported)'), findsOneWidget);

      expect(find.text('General'), findsOneWidget);
      expect(find.text('Clear Cache'), findsOneWidget);
      expect(find.text('App Updates'), findsOneWidget);

      // Toggle Theme
      await tester.tap(find.text('Theme'));
      expect(themeToggled, isTrue);
    });

    testWidgets('shows honest Auto-Answer dialog when switch is toggled', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            onOpenGuardian: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));
      await tester.tap(switches.last);
      await tester.pumpAndSettle();

      expect(find.text('Auto-Answer Unsupported'), findsOneWidget);
      expect(find.text('Understand'), findsOneWidget);

      await tester.tap(find.text('Understand'));
      await tester.pumpAndSettle();
      expect(find.text('Auto-Answer Unsupported'), findsNothing);
    });
  });

  group('Phase 08 - Privacy & Security Screen', () {
    testWidgets('renders permissions, data usage, security options, and toggles', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeCallBridge = FakeCallBridge();
      final fakeAuth = FakeAuthService();

      await tester.pumpWidget(
        MaterialApp(
          home: PrivacyCenterScreen(
            callBridge: fakeCallBridge,
            authService: fakeAuth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy & Security'), findsOneWidget);
      expect(find.text('Your privacy matters'), findsOneWidget);
      expect(find.text('DATA & PERMISSIONS'), findsOneWidget);
      expect(find.text('App Permissions'), findsOneWidget);
      expect(find.text('Data Usage'), findsOneWidget);
      expect(find.text('Account Security'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);

      expect(find.text('PRIVACY CONTROLS'), findsOneWidget);
      expect(find.text('Data Sharing'), findsOneWidget);
      expect(find.text('Usage Analytics'), findsOneWidget);
    });

    testWidgets('opens App Permissions sheet with honest status', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: PrivacyCenterScreen(
            callBridge: FakeCallBridge(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('App Permissions'));
      await tester.pumpAndSettle();

      expect(find.text('Microphone (RECORD_AUDIO)'), findsOneWidget);
      expect(find.text('Phone State (READ_PHONE_STATE)'), findsOneWidget);
      expect(find.text('Open System App Settings'), findsOneWidget);
    });
  });

  group('Phase 08 - Community Screen', () {
    testWidgets('renders banner, action tiles, and allows reporting a scam', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeCommunity = FakeCommunityService();

      await tester.pumpWidget(
        MaterialApp(
          home: CommunityScreen(communityService: fakeCommunity),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Stronger together'), findsOneWidget);
      expect(find.text('Report a Scam'), findsOneWidget);
      expect(find.text('Community Posts'), findsOneWidget);
      expect(find.text('Scam Patterns'), findsOneWidget);
      expect(find.text('Safety Tips'), findsOneWidget);
      expect(find.text('Q&A'), findsOneWidget);
      expect(find.text('Report. Share. Protect.'), findsOneWidget);

      // Open Report a Scam dialog
      await tester.tap(find.text('Report a Scam'));
      await tester.pumpAndSettle();

      expect(find.text('Submit suspicious scam patterns or messages to help protect the community.'), findsOneWidget);
      expect(find.text('Submit Community Report'), findsOneWidget);
    });
  });

  group('Phase 08 - Help & Support Screen', () {
    testWidgets('renders help banner and tiles, and opens contact details', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: HelpSupportScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('We\'re here to help'), findsOneWidget);
      expect(find.text('FAQs'), findsOneWidget);
      expect(find.text('Contact Us'), findsOneWidget);
      expect(find.text('Report an Issue'), findsOneWidget);
      expect(find.text('User Guide'), findsOneWidget);
      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);

      // Open Contact Us modal
      await tester.tap(find.text('Contact Us'));
      await tester.pumpAndSettle();

      expect(find.text('Official Email:'), findsOneWidget);
      expect(find.text('security@scamshield.ai'), findsOneWidget);
    });
  });

  group('Phase 08 - About Screen', () {
    testWidgets('renders brand identity, version, and mission card', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AboutScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);
      expect(find.text('ScamShield'), findsOneWidget);
      expect(find.text('Detect • Analyze • Protect'), findsOneWidget);
      expect(find.textContaining('Version 1.0.0'), findsOneWidget);
      expect(find.text('Our Mission'), findsOneWidget);
      expect(find.text('Features'), findsOneWidget);
      expect(find.text('Technology'), findsOneWidget);
      expect(find.text('Acknowledgements'), findsOneWidget);
      expect(find.text('© 2026 ScamShield. All rights reserved.'), findsOneWidget);
    });
  });

  group('Phase 08 - Notification Screen (Addendum)', () {
    testWidgets('loads notifications, displays unread count, and supports Mark All Read', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeNotificationService = FakeNotificationService();

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationScreen(notificationService: fakeNotificationService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Suspicious Call Blocked'), findsOneWidget);
      expect(find.text('Analysis Complete'), findsOneWidget);
      expect(find.byTooltip('Mark all as read'), findsOneWidget);

      // Tap Mark All Read action in AppBar
      await tester.tap(find.byTooltip('Mark all as read'));
      await tester.pumpAndSettle();

      expect(find.text('All notifications marked as read'), findsOneWidget);
      expect(fakeNotificationService.notifications.every((n) => n.isRead), isTrue);
    });

    testWidgets('Clear all prompts confirmation dialog and clears list', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeNotificationService = FakeNotificationService();

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationScreen(notificationService: fakeNotificationService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Suspicious Call Blocked'), findsOneWidget);

      // Tap Clear All
      await tester.tap(find.byTooltip('Clear all notifications'));
      await tester.pumpAndSettle();

      expect(find.text('Clear all notifications?'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);

      // Confirm
      await tester.tap(find.widgetWithText(FilledButton, 'Clear All'));
      await tester.pumpAndSettle();

      // Expect empty state
      expect(find.text('No notifications yet'), findsOneWidget);
      expect(
        find.text('Security alerts, completed analysis notifications, and call protection reports will appear here.'),
        findsOneWidget,
      );
    });
  });
}
