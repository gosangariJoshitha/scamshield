import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/models/user.dart';
import 'package:scamshield_guardian/screens/landing/landing_screen.dart';
import 'package:scamshield_guardian/screens/login/admin_portal_screen.dart';
import 'package:scamshield_guardian/services/admin_portal_service.dart';
import 'package:scamshield_guardian/services/api_service.dart';
import 'package:scamshield_guardian/services/auth_service.dart';
import 'package:scamshield_guardian/widgets/brand_mark.dart';

AuthService _authService() {
  return AuthService(
    api: ApiService(
      client: MockClient((_) async => http.Response('{}', 200)),
      baseUri: Uri.parse('https://api.example.test/api'),
    ),
  );
}

Widget _landing({
  ValueChanged<bool>? onThemeChanged,
  AuthService? authService,
  ValueChanged<User>? onAdminAuthenticated,
}) {
  final auth = authService ?? _authService();
  return MaterialApp(
    home: LandingScreen(
      authService: auth,
      onAuthenticated: (_) {},
      onAdminAuthenticated: onAdminAuthenticated ?? (_) {},
      onThemeChanged: onThemeChanged ?? (_) {},
    ),
  );
}

void main() {
  testWidgets(
    'landing presents ScamShield branding, features and future call capability',
    (tester) async {
      await tester.pumpWidget(_landing());

      expect(find.text('ScamShield'), findsOneWidget);
      expect(find.text('SCAMSHIELD'), findsOneWidget);
      expect(find.text('AI-POWERED SCAM PROTECTION'), findsOneWidget);
      expect(find.text('Understand Them.'), findsOneWidget);
      expect(find.text('Get Started →'), findsNWidgets(2));
      expect(find.text('Login'), findsNWidgets(2));
      expect(find.text('Messages'), findsNWidgets(2));
      expect(find.text('Calls'), findsNWidgets(2));
      expect(find.text('Images'), findsOneWidget);
      expect(find.text('PDF & Docs'), findsOneWidget);
      expect(find.text('TRUSTED PROTECTION'), findsOneWidget);
      expect(find.text('Why Choose ScamShield?'), findsOneWidget);
      expect(find.text('Message Analysis'), findsOneWidget);
      expect(find.text('Call Protection (Sentinel)'), findsOneWidget);
      expect(find.text('Image & Document Scan'), findsOneWidget);
      expect(find.text('AI-Powered Insights'), findsOneWidget);
      expect(find.text('Your Privacy Comes First'), findsOneWidget);
      expect(find.text('Digital You'), findsOneWidget);
      expect(
        find.text('Powered by Advanced AI and Real-World Intelligence'),
        findsOneWidget,
      );
      expect(
        find.text('Smarter Analysis. Safer Decisions. A Safer You.'),
        findsOneWidget,
      );
      expect(find.text('Admin Sign-in'), findsOneWidget);
      expect(find.byType(ScamShieldBrandMark), findsNWidgets(2));
    },
  );

  testWidgets('Get Started navigates to the backend signup form', (
    tester,
  ) async {
    await tester.pumpWidget(_landing());

    await tester.tap(find.text('Get Started →').first);
    await tester.pumpAndSettle();

    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
  });

  testWidgets('lower-page Get Started CTA also opens signup', (tester) async {
    await tester.pumpWidget(_landing());

    final getStartedButtons = find.text('Get Started →');
    await tester.ensureVisible(getStartedButtons.last);
    await tester.tap(getStartedButtons.last);
    await tester.pumpAndSettle();

    expect(find.text('Create an account'), findsOneWidget);
  });

  testWidgets(
    'successful admin login opens the native portal without a web launch',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final api = ApiService(
        client: MockClient((request) async {
          if (request.url.path == '/api/auth/admin/login') {
            return http.Response('{"access_token":"admin-token"}', 200);
          }
          if (request.url.path == '/api/auth/me') {
            return http.Response(
              '{"id":7,"full_name":"Admin User","email":"admin@example.com",'
              '"role":"admin","is_active":true,"email_verified":true}',
              200,
            );
          }
          if (request.url.path == '/api/admin/overview') {
            expect(request.headers['authorization'], startsWith('Bearer '));
            return http.Response(
              '{"period_days":30,"totalAnalyses":14,"scamsDetected":4,'
              '"highRisk":2,"pendingReviews":1,"communityReports":3,'
              '"verifiedKnowledge":8,"analysisActivity":[],"recentReviews":[],'
              '"recentAnalyses":[]}',
              200,
            );
          }
          fail('Unexpected request ${request.url.path}');
        }),
        baseUri: Uri.parse('https://api.example.test/api'),
      );
      final auth = AuthService(api: api);
      User? adminUser;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              final currentAdmin = adminUser;
              if (currentAdmin != null) {
                return AdminPortalScreen(
                  user: currentAdmin,
                  adminService: AdminPortalService(
                    api: api,
                    tokenProvider: auth.getStoredAdminToken,
                  ),
                  onLogout: auth.logoutAdmin,
                  onSessionExpired: auth.logoutAdmin,
                  isDarkMode: false,
                  onToggleTheme: () {},
                );
              }
              return LandingScreen(
                authService: auth,
                onAuthenticated: (_) {},
                onAdminAuthenticated: (user) =>
                    setState(() => adminUser = user),
                onThemeChanged: (_) {},
              );
            },
          ),
        ),
      );

      final loginBtn = find.text('Login').first;
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Admin Sign-in'));
      await tester.tap(find.text('Admin Sign-in'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'admin@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'StrongPass1');
      await tester.ensureVisible(find.text('ADMIN LOGIN'));
      await tester.tap(find.text('ADMIN LOGIN'));
      await tester.pumpAndSettle();

      expect(find.text('Command center'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('OPEN ADMIN PORTAL'), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('capability shortcut tap displays informative feedback', (
    tester,
  ) async {
    await tester.pumpWidget(_landing());
    final callsShortcut = find.text('Calls').first;
    await tester.ensureVisible(callsShortcut);
    await tester.tap(callsShortcut);
    await tester.pump();

    expect(
      find.textContaining('Calls capability available'),
      findsOneWidget,
    );
  });

  testWidgets('login action opens unified login and signup tabs', (
    tester,
  ) async {
    await tester.pumpWidget(_landing());

    final loginBtn = find.text('Login').first;
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Admin Sign-in'), findsOneWidget);
  });

  testWidgets('signup tab changes the unified authentication form', (
    tester,
  ) async {
    await tester.pumpWidget(_landing());

    final loginBtn = find.text('Login').first;
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
  });

  testWidgets('admin entry opens the role-verified admin sign-in design', (
    tester,
  ) async {
    await tester.pumpWidget(_landing());

    final loginBtn = find.text('Login').first;
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Admin Sign-in'));
    await tester.tap(find.text('Admin Sign-in'));
    await tester.pumpAndSettle();

    expect(find.text('ADMIN PORTAL'), findsOneWidget);
    expect(find.text('SCAMSHIELD'), findsOneWidget);
    expect(find.text('Admin Sign-in'), findsOneWidget);
    expect(
      find.text('Sign in to access the ScamShield Admin Portal.'),
      findsOneWidget,
    );
    expect(find.text('ADMIN LOGIN'), findsOneWidget);
    expect(find.text('Back to Login / Sign Up'), findsOneWidget);
  });

  testWidgets('landing theme control sends the selected theme to app shell', (
    tester,
  ) async {
    var isDarkMode = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Theme(
            data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
            child: LandingScreen(
              authService: _authService(),
              onAuthenticated: (_) {},
              onAdminAuthenticated: (_) {},
              onThemeChanged: (value) => setState(() => isDarkMode = value),
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Switch to dark theme'), findsOneWidget);
    await tester.tap(find.byTooltip('Switch to dark theme'));
    await tester.pump();

    expect(isDarkMode, isTrue);
    expect(find.byTooltip('Switch to light theme'), findsOneWidget);
  });

  testWidgets(
    'landing content remains scrollable without narrow-screen overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_landing());
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Admin Sign-in link on landing footer navigates directly to admin sign-in mode',
    (tester) async {
      await tester.pumpWidget(_landing());

      final adminLink = find.text('Admin Sign-in');
      await tester.ensureVisible(adminLink);
      await tester.tap(adminLink);
      await tester.pumpAndSettle();

      expect(find.text('ADMIN PORTAL'), findsOneWidget);
      expect(find.text('ADMIN LOGIN'), findsOneWidget);
      expect(find.text('Welcome back'), findsNothing);
    },
  );
}
