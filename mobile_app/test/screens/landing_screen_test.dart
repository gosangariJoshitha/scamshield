import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/models/user.dart';
import 'package:scamshield_guardian/screens/landing/landing_screen.dart';
import 'package:scamshield_guardian/screens/login/admin_portal_screen.dart';
import 'package:scamshield_guardian/services/api_service.dart';
import 'package:scamshield_guardian/services/admin_portal_service.dart';
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

      expect(find.text('SCAMSHIELD'), findsOneWidget);
      expect(find.text('AI-POWERED SCAM PROTECTION'), findsOneWidget);
      expect(
        find.text('Don’t Just Detect Scams.\nUnderstand Them.'),
        findsOneWidget,
      );
      expect(find.text('GET STARTED'), findsNWidgets(2));
      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.text('Multi-channel\nProtection'), findsOneWidget);
      expect(find.text('BUILT TO HELP YOU THINK CLEARLY'), findsOneWidget);
      expect(find.text('Text Analysis'), findsOneWidget);
      expect(find.text('Image & Screenshot'), findsOneWidget);
      expect(find.text('PDF & Document'), findsOneWidget);
      expect(find.text('Audio Analysis'), findsOneWidget);
      expect(find.text('Community Insights'), findsNWidgets(2));
      expect(find.text('Live Call Guardian'), findsOneWidget);
      expect(find.text('COMING SOON'), findsNothing);
      expect(
        find.text('Planned call protection to help identify suspicious calls.'),
        findsOneWidget,
      );
      expect(find.text('Stay informed. Stay protected.'), findsOneWidget);
      expect(find.text('Your Privacy Matters'), findsOneWidget);
      expect(find.text('GET STARTED'), findsNWidgets(2));
      expect(find.byType(ScamShieldBrandMark), findsNWidgets(2));
    },
  );

  testWidgets('Get Started navigates to the backend signup form', (
    tester,
  ) async {
    await tester.pumpWidget(_landing());

    await tester.tap(find.text('GET STARTED').first);
    await tester.pumpAndSettle();

    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
  });

  testWidgets('lower-page Get Started CTA also opens signup', (tester) async {
    await tester.pumpWidget(_landing());

    final getStartedButtons = find.text('GET STARTED');
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

      await tester.tap(find.text('LOGIN').last);
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

  testWidgets('feature cards lift and highlight on pointer hover', (
    tester,
  ) async {
    await tester.pumpWidget(_landing());
    final title = find.text('Text Analysis');
    await tester.ensureVisible(title);
    final animatedCard = find
        .ancestor(of: title, matching: find.byType(AnimatedContainer))
        .first;
    expect(
      find.descendant(
        of: animatedCard,
        matching: find.byIcon(Icons.arrow_forward_rounded),
      ),
      findsNothing,
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(title));
    await mouse.moveTo(tester.getCenter(title));
    await tester.pump(const Duration(milliseconds: 200));

    final card = tester.widget<AnimatedContainer>(animatedCard);
    expect(card.transform!.getTranslation().y, -3);

    await mouse.removePointer();
  });

  testWidgets('all four bottom trust cards lift and highlight on hover', (
    tester,
  ) async {
    await tester.pumpWidget(_landing());
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();

    for (final title in [
      'Your Privacy Matters',
      'AI-Powered Analysis',
      'Risk-Aware Guidance',
      'Community Insights',
    ]) {
      final titleFinder = find.text(title).last;
      await tester.ensureVisible(titleFinder);
      final card = find
          .ancestor(of: titleFinder, matching: find.byType(AnimatedContainer))
          .first;
      await mouse.moveTo(tester.getCenter(titleFinder));
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        tester.widget<AnimatedContainer>(card).transform!.getTranslation().y,
        -2,
        reason: '$title should lift on hover',
      );

      await mouse.moveTo(const Offset(0, 0));
      await tester.pump(const Duration(milliseconds: 200));
    }

    await mouse.removePointer();
  });

  testWidgets('login action opens unified login and signup tabs', (
    tester,
  ) async {
    await tester.pumpWidget(_landing());

    await tester.tap(find.text('LOGIN'));
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

    await tester.tap(find.text('LOGIN'));
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

    await tester.tap(find.text('LOGIN'));
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
}
