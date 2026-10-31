import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/screens/landing/landing_screen.dart';
import 'package:scamshield_guardian/screens/landing/widgets/hero_security_illustration.dart';
import 'package:scamshield_guardian/services/api_service.dart';
import 'package:scamshield_guardian/services/auth_service.dart';
import 'package:scamshield_guardian/theme/app_theme.dart';

AuthService _mockAuthService() {
  return AuthService(
    api: ApiService(
      client: MockClient((_) async => http.Response('{}', 200)),
      baseUri: Uri.parse('https://api.example.test/api'),
    ),
  );
}

Widget _landingApp({bool isDark = false}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
    home: LandingScreen(
      authService: _mockAuthService(),
      onAuthenticated: (_) {},
      onAdminAuthenticated: (_) {},
      onThemeChanged: (_) {},
    ),
  );
}

void main() {
  group('Phase 02: ScamShield 2.0 Landing Experience Tests (1000261210.png)', () {
    testWidgets('presents the hero security illustration and core headline', (
      tester,
    ) async {
      await tester.pumpWidget(_landingApp());

      expect(find.byType(HeroSecurityIllustration), findsOneWidget);
      expect(find.text("Don't Just Detect Scams."), findsOneWidget);
      expect(find.text('Understand Them.'), findsOneWidget);
      expect(
        find.text(
          'Analyze suspicious messages, calls, images, documents and more with AI — and stay one step ahead.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'presents the 4 verified feature cards and privacy commitment card',
      (tester) async {
        await tester.pumpWidget(_landingApp());

        expect(find.text('Why Choose ScamShield?'), findsOneWidget);
        expect(find.text('Message Analysis'), findsOneWidget);
        expect(find.text('Call Protection (Sentinel)'), findsOneWidget);
        expect(find.text('Image & Document Scan'), findsOneWidget);
        expect(find.text('AI-Powered Insights'), findsOneWidget);

        expect(find.text('Your Privacy Comes First'), findsOneWidget);
        expect(find.text('Your data stays private'), findsOneWidget);
        expect(find.text('Secure and encrypted'), findsOneWidget);
        expect(find.text('Only authorized access'), findsOneWidget);
        expect(find.text('No unsolicited data sharing'), findsOneWidget);
      },
    );

    testWidgets(
      'presents Built for a Safer Digital You with capability pills and AI card',
      (tester) async {
        await tester.pumpWidget(_landingApp());

        expect(find.text('Built for a Safer'), findsOneWidget);
        expect(find.text('Digital You'), findsOneWidget);
        expect(find.text('AI Analysis'), findsNWidgets(4));
        expect(
          find.text('Powered by Advanced AI and Real-World Intelligence'),
          findsOneWidget,
        );
        expect(
          find.text(
            'We combine AI analysis with verified scam patterns to give you clear, reliable insights.',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
