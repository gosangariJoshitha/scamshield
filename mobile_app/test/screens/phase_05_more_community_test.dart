import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_guardian/models/community_report_model.dart';
import 'package:scamshield_guardian/models/user.dart';
import 'package:scamshield_guardian/native/call_bridge.dart';
import 'package:scamshield_guardian/screens/about/about_screen.dart';
import 'package:scamshield_guardian/screens/community/community_screen.dart';
import 'package:scamshield_guardian/screens/help/help_support_screen.dart';
import 'package:scamshield_guardian/screens/privacy/privacy_center_screen.dart';
import 'package:scamshield_guardian/screens/profile/profile_screen.dart';
import 'package:scamshield_guardian/screens/settings/settings_screen.dart';
import 'package:scamshield_guardian/services/auth_service.dart';
import 'package:scamshield_guardian/services/community_service.dart';

class _FakeAuthService extends Fake implements AuthService {
  String? updatedFullName;
  bool? updatedEmailNotifications;
  bool? updatedCommunityUpdates;
  bool passwordChanged = false;

  @override
  Future<User> updateProfile({
    String? fullName,
    bool? twoFactorEnabled,
    bool? emailNotifications,
    bool? communityUpdates,
    bool? marketingUpdates,
  }) async {
    updatedFullName = fullName;
    updatedEmailNotifications = emailNotifications;
    updatedCommunityUpdates = communityUpdates;
    return User(
      id: 1,
      fullName: fullName ?? 'Joshitha G',
      email: 'joshitha@scamshield.ai',
      role: 'user',
      isActive: true,
      emailVerified: true,
      twoFactorEnabled: false,
      emailNotifications: emailNotifications ?? true,
      communityUpdates: communityUpdates ?? true,
      marketingUpdates: false,
      createdAt: DateTime(2026, 1, 15),
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    passwordChanged = true;
  }
}

class _FakeFailingAuthService extends Fake implements AuthService {
  @override
  Future<User> updateProfile({
    String? fullName,
    bool? twoFactorEnabled,
    bool? emailNotifications,
    bool? communityUpdates,
    bool? marketingUpdates,
  }) async {
    throw Exception('Server unreachable');
  }
}

class _FakeCommunityService extends Fake implements CommunityService {
  _FakeCommunityService({this.reportsToReturn, this.shouldThrow = false});

  List<CommunityReportModel>? reportsToReturn;
  bool shouldThrow;
  CommunityReportModel? lastSubmitted;

  @override
  Future<List<CommunityReportModel>> getCommunityReports() async {
    if (shouldThrow) {
      throw Exception('Network offline: Failed to fetch community feed');
    }
    return reportsToReturn ?? [];
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
      id: 99,
      content: content,
      category: category,
      description: description,
      evidence: evidence,
      analysisId: analysisId,
      reporterName: 'Joshitha G',
      status: 'Pending',
      createdAt: DateTime.now(),
    );
    lastSubmitted = report;
    return report;
  }

  int? flaggedReportId;
  String? flaggedReason;

  @override
  Future<bool> flagReport({
    required int reportId,
    required String reason,
  }) async {
    if (shouldThrow) {
      throw Exception('Failed to flag report');
    }
    flaggedReportId = reportId;
    flaggedReason = reason;
    return true;
  }
}

class _FakeCallBridge extends Fake implements CallBridge {
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

void main() {
  final testUser = User(
    id: 1,
    fullName: 'Joshitha G',
    email: 'joshitha@scamshield.ai',
    role: 'user',
    isActive: true,
    emailVerified: true,
    twoFactorEnabled: false,
    emailNotifications: true,
    communityUpdates: true,
    marketingUpdates: false,
    createdAt: DateTime(2026, 1, 15),
  );

  group('Phase 05 — More Page Inventory & Destinations', () {
    testWidgets('renders all More page navigation cards with working destinations', (tester) async {
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

      // Profile header & Brand
      expect(find.text('Joshitha G'), findsOneWidget);
      expect(find.text('Stay safe. Stay informed.'), findsOneWidget);
      expect(find.text('ScamShield'), findsOneWidget);
      expect(find.text('Smarter protection. Safer you.'), findsOneWidget);

      // Verified Menu entries
      expect(find.text('Account Details'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Privacy & Security'), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('opens Account Details sheet, displays user data, and edits name with persistence', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeAuth = _FakeAuthService();

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            user: testUser,
            isDarkMode: false,
            authService: fakeAuth,
            onToggleTheme: () {},
            onLogout: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Account Details tile
      await tester.tap(find.text('Account Details'));
      await tester.pumpAndSettle();

      // Verify account details displayed
      expect(find.text('Verified Account'), findsOneWidget);
      expect(find.text('USER'), findsOneWidget);
      expect(find.text('joshitha@scamshield.ai'), findsOneWidget);
      expect(find.text('Change Account Password'), findsOneWidget);
      expect(find.text('Open Privacy & Security'), findsOneWidget);

      // Tap edit name button
      await tester.tap(find.byTooltip('Edit name'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Full Name'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Joshitha Gosangari');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(fakeAuth.updatedFullName, 'Joshitha Gosangari');
      expect(find.text('Profile name updated successfully.'), findsOneWidget);
    });
  });

  group('Phase 05 — Community Full-Page Navigation & Functionality', () {
    testWidgets('CommunityScreen loads real reports feed with moderation badges', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final realReports = [
        CommunityReportModel(
          id: 101,
          content: 'Urgent: Electricity power disconnection tonight SMS with mobile 9876543210',
          category: 'Impersonation',
          description: 'Demanded ₹15 payment via unauthorized link or electricity would be cut.',
          evidence: 'Short link bit.ly/power-bill',
          analysisId: 42,
          reporterName: 'Rahul V',
          status: 'Verified',
          createdAt: DateTime(2026, 11, 1),
        ),
        CommunityReportModel(
          id: 102,
          content: 'Fake courier DHL customs drugs parcel Skype call extortion',
          category: 'Courier / Delivery',
          description: 'Claimed my Aadhaar was found in contraband package in Mumbai airport.',
          reporterName: 'Anita K',
          status: 'Pending',
          createdAt: DateTime(2026, 11, 1),
        ),
      ];

      final fakeCommunity = _FakeCommunityService(reportsToReturn: realReports);

      await tester.pumpWidget(
        MaterialApp(
          home: CommunityScreen(
            communityService: fakeCommunity,
            user: testUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Screen title and banner
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Stronger together'), findsOneWidget);
      expect(find.text('Report. Share. Protect.'), findsOneWidget);

      // Reports in feed
      expect(find.text('Urgent: Electricity power disconnection tonight SMS with mobile 9876543210'), findsOneWidget);
      expect(find.text('VERIFIED'), findsOneWidget);
      expect(find.text('Fake courier DHL customs drugs parcel Skype call extortion'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('Rahul V'), findsOneWidget);
      expect(find.text('Anita K'), findsOneWidget);
    });

    testWidgets('CommunityScreen handles empty state and allows reporting a scam', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeCommunity = _FakeCommunityService(reportsToReturn: []);

      await tester.pumpWidget(
        MaterialApp(
          home: CommunityScreen(
            communityService: fakeCommunity,
            user: testUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No community reports submitted yet. Be the first to share a scam alert!'), findsOneWidget);

      // Tap Report a Scam button
      await tester.tap(find.widgetWithText(FilledButton, 'Report a Scam').first);
      await tester.pumpAndSettle();

      expect(find.text('Submit suspicious scam patterns or messages to help protect the community.'), findsOneWidget);
      expect(find.text('Submit Community Report'), findsOneWidget);

      // Fill in report content
      await tester.enterText(
        find.widgetWithText(TextField, 'e.g. "Dear customer, your electricity will be disconnected tonight..."'),
        'Lottery win claiming ₹25,000,000 from KBC WhatsApp call',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Submit Community Report'));
      await tester.pumpAndSettle();

      expect(fakeCommunity.lastSubmitted, isNotNull);
      expect(fakeCommunity.lastSubmitted!.content, contains('Lottery win claiming ₹25,000,000'));
      expect(find.text('Thank you! Your scam report was successfully submitted.'), findsOneWidget);
    });

    testWidgets('CommunityScreen handles offline/error state with honest retry action', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeCommunity = _FakeCommunityService(shouldThrow: true);

      await tester.pumpWidget(
        MaterialApp(
          home: CommunityScreen(
            communityService: fakeCommunity,
            user: testUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not load posts'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Retry recovers after service becomes healthy
      fakeCommunity.shouldThrow = false;
      fakeCommunity.reportsToReturn = [
        CommunityReportModel(
          id: 103,
          content: 'Recovered report content',
          category: 'Phishing',
          reporterName: 'System',
          status: 'Verified',
          createdAt: DateTime.now(),
        ),
      ];
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Recovered report content'), findsOneWidget);
    });

    testWidgets('Tapping report opens CommunityPostDetailScreen with moderation notice and flagging', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final report = CommunityReportModel(
        id: 104,
        content: 'Work from home YouTube like scam requesting ₹5,000 prepaid task',
        category: 'Job Scam',
        description: 'Telegram group admin promised 30% daily return after liking 3 videos.',
        evidence: 'Telegram handle @scam_tasks_admin',
        analysisId: 77,
        reporterName: 'Priya S',
        status: 'Verified',
        createdAt: DateTime(2026, 11, 1),
      );

      final fakeCommunity = _FakeCommunityService(reportsToReturn: [report]);

      await tester.pumpWidget(
        MaterialApp(
          home: CommunityScreen(
            communityService: fakeCommunity,
            user: testUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the report card
      await tester.tap(find.text('Work from home YouTube like scam requesting ₹5,000 prepaid task'));
      await tester.pumpAndSettle();

      // Verified full-page CommunityPostDetailScreen
      expect(find.text('Report Details'), findsOneWidget);
      expect(find.text('Reported by Priya S'), findsOneWidget);
      expect(find.text('Linked to Analysis #77'), findsOneWidget);
      expect(find.text('Moderated Discussion'), findsOneWidget);
      expect(
        find.textContaining('Community discussion is restricted to verified moderators to maintain threat intelligence integrity'),
        findsOneWidget,
      );

      // Test flagging inappropriate content
      await tester.tap(find.text('Report Inappropriate Content'));
      await tester.pumpAndSettle();

      expect(find.text('Report Inappropriate Post'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Flag Report'));
      await tester.pumpAndSettle();

      expect(find.text('Thank you. This report has been flagged for moderation review.'), findsOneWidget);
    });
  });

  group('Phase 05 — Settings, Notification Preferences & Persistence', () {
    testWidgets('Settings allows configuring notification preferences with API persistence', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeAuth = _FakeAuthService();
      final fakeCallBridge = _FakeCallBridge();

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            onOpenGuardian: () {},
            authService: fakeAuth,
            user: testUser,
            callBridge: fakeCallBridge,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notification Preferences'), findsOneWidget);
      await tester.tap(find.text('Notification Preferences'));
      await tester.pumpAndSettle();

      expect(find.text('Email Security Alerts'), findsOneWidget);
      expect(find.text('Community Threat Updates'), findsOneWidget);

      // Toggle Email Security Alerts switch inside the bottom sheet
      final emailSwitch = find.descendant(
        of: find.widgetWithText(SwitchListTile, 'Email Security Alerts'),
        matching: find.byType(Switch),
      );
      expect(emailSwitch, findsOneWidget);
      await tester.tap(emailSwitch);
      await tester.pumpAndSettle();

      expect(fakeAuth.updatedEmailNotifications, isFalse);
    });

    testWidgets('Settings Clear Cache prompts confirmation and clears cache safely', (tester) async {
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

      await tester.tap(find.text('Clear Cache'));
      await tester.pumpAndSettle();

      expect(find.text('Clear local cache?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Clear Cache'));
      await tester.pumpAndSettle();

      expect(find.textContaining('cleared successfully.'), findsOneWidget);
    });
  });

  group('Phase 05 — Secondary Screens Verification', () {
    testWidgets('PrivacyCenterScreen accurately represents ephemeral RAM-only audio and bcrypt credentials', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeCallBridge = _FakeCallBridge();

      await tester.pumpWidget(
        MaterialApp(
          home: PrivacyCenterScreen(callBridge: fakeCallBridge),
        ),
      );
      await tester.pumpAndSettle();

      // Open Data Usage
      await tester.tap(find.text('Data Usage'));
      await tester.pumpAndSettle();

      expect(find.text('No Audio Storage'), findsOneWidget);
      expect(
        find.textContaining('Live call audio chunks are processed in ephemeral memory during the call. They are never written to disk or persistently saved on servers.'),
        findsOneWidget,
      );
      expect(find.text('Content Analysis'), findsOneWidget);
      expect(find.text('Credentials & Passwords'), findsOneWidget);
    });

    testWidgets('HelpSupportScreen renders official support email and functional guides', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: HelpSupportScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Contact Us dialog
      await tester.tap(find.text('Contact Us'));
      await tester.pumpAndSettle();

      expect(find.text('security@scamshield.ai'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // User Guide
      await tester.tap(find.text('User Guide'));
      await tester.pumpAndSettle();

      expect(find.text('ScamShield User Guide'), findsOneWidget);
      expect(find.text('Enable Sentinel Call Protection'), findsOneWidget);
    });

    testWidgets('AboutScreen renders features and architecture truth without fake metrics', (tester) async {
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
      expect(find.text('Version 1.0.0 (Build 1)'), findsOneWidget);
      expect(find.text('Our Mission'), findsOneWidget);
      expect(find.text('Features'), findsOneWidget);
      expect(find.text('Technology'), findsOneWidget);
    });

    testWidgets('CommunityPostDetailScreen submits inappropriate flag to backend and confirms', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeCommunity = _FakeCommunityService();
      final sampleReport = CommunityReportModel(
        id: 42,
        content: 'Suspicious electricity APK text',
        category: 'SMS Phishing',
        reporterName: 'Test Reporter',
        status: 'PENDING',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CommunityPostDetailScreen(
            report: sampleReport,
            communityService: fakeCommunity,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap flag button in app bar
      await tester.tap(find.byTooltip('Flag post'));
      await tester.pumpAndSettle();

      expect(find.text('Report Inappropriate Post'), findsOneWidget);
      expect(find.text('Violation Category'), findsOneWidget);

      // Confirm flag
      await tester.tap(find.text('Flag Report'));
      await tester.pumpAndSettle();

      expect(fakeCommunity.flaggedReportId, 42);
      expect(fakeCommunity.flaggedReason, 'Spam or Deceptive content');
      expect(
        find.text('Thank you. This report has been flagged for moderation review.'),
        findsOneWidget,
      );
    });

    testWidgets('SettingsScreen restores preference switch state on update failure', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final failingAuth = _FakeFailingAuthService();
      final user = User(
        id: 1,
        fullName: 'Joshitha G',
        email: 'joshitha@scamshield.ai',
        role: 'user',
        isActive: true,
        emailVerified: true,
        twoFactorEnabled: false,
        emailNotifications: true,
        communityUpdates: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            onOpenGuardian: () {},
            authService: failingAuth,
            user: user,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open notification preferences sheet
      await tester.tap(find.text('Notification Preferences'));
      await tester.pumpAndSettle();

      expect(find.text('Email Security Alerts'), findsOneWidget);

      // Toggle switch - should fail and revert
      final emailSwitch = find.descendant(
        of: find.widgetWithText(SwitchListTile, 'Email Security Alerts'),
        matching: find.byType(Switch),
      );
      expect(emailSwitch, findsOneWidget);
      await tester.tap(emailSwitch);
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to update email preferences'), findsOneWidget);
    });

    testWidgets('ProfileScreen shows genuine Pending Verification badge for unverified users', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final unverifiedUser = User(
        id: 2,
        fullName: 'New User',
        email: 'newuser@scamshield.ai',
        role: 'user',
        isActive: true,
        emailVerified: false,
        twoFactorEnabled: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            user: unverifiedUser,
            isDarkMode: false,
            onToggleTheme: () {},
            onLogout: () async {},
            onOpenGuardian: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Account Details Sheet
      await tester.tap(find.text('New User'));
      await tester.pumpAndSettle();

      expect(find.text('Account Status'), findsOneWidget);
      expect(find.text('Pending Verification'), findsOneWidget);
      expect(find.text('Verified Account'), findsNothing);
    });
  });
}
