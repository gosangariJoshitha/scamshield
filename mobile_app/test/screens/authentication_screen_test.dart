import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/models/user.dart';
import 'package:scamshield_guardian/screens/auth/authentication_screen.dart';
import 'package:scamshield_guardian/screens/auth/password_reset_screen.dart';
import 'package:scamshield_guardian/services/api_service.dart';
import 'package:scamshield_guardian/services/auth_service.dart';

Widget _screen({
  required AuthService auth,
  String initialMode = 'login',
  ValueChanged<bool>? onThemeChanged,
  ValueChanged<User>? onAuthenticated,
  ValueChanged<User>? onAdminAuthenticated,
}) {
  return MaterialApp(
    home: AuthenticationScreen(
      authService: auth,
      initialMode: initialMode,
      onThemeChanged: onThemeChanged ?? (_) {},
      onAuthenticated: onAuthenticated ?? (_) {},
      onAdminAuthenticated: onAdminAuthenticated ?? (_) {},
    ),
  );
}

AuthService _auth(http.Client client) => AuthService(
  api: ApiService(
    client: client,
    baseUri: Uri.parse('https://api.example.test/api'),
  ),
);

void main() {
  testWidgets('signup validates fields, password match and terms before API', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      _screen(
        auth: _auth(
          MockClient((_) async {
            requests++;
            return http.Response('{}', 200);
          }),
        ),
        initialMode: 'signup',
      ),
    );

    await tester.ensureVisible(find.text('CREATE ACCOUNT'));
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your full name.'), findsOneWidget);
    expect(find.text('Enter a valid email address.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Sam User');
    await tester.enterText(find.byType(TextFormField).at(1), 'sam@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'StrongPass1');
    await tester.enterText(find.byType(TextFormField).at(3), 'StrongPass1');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('CREATE ACCOUNT'));
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pumpAndSettle();

    expect(
      find.text('Please accept the Terms and Privacy Policy.'),
      findsOneWidget,
    );
    expect(requests, 0);
  });

  testWidgets('signup connects to existing create and email verify endpoints', (
    tester,
  ) async {
    final paths = <String>[];
    final auth = _auth(
      MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path == '/api/auth/signup') {
          expect(jsonDecode(request.body), {
            'full_name': 'Sam User',
            'email': 'sam@example.com',
            'password': 'StrongPass1',
          });
          return http.Response(
            '{"account_created":true,"email_verified":false,"verification_email_sent":true,"verification_challenge_id":"signup-challenge","message":"Created"}',
            200,
          );
        }
        expect(request.url.path, '/api/auth/verify-email');
        expect(jsonDecode(request.body), {
          'challenge_id': 'signup-challenge',
          'code': '123456',
        });
        return http.Response('{"email_verified":true}', 200);
      }),
    );
    await tester.pumpWidget(_screen(auth: auth, initialMode: 'signup'));

    await tester.enterText(find.byType(TextFormField).at(0), 'Sam User');
    await tester.enterText(find.byType(TextFormField).at(1), 'sam@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'StrongPass1');
    await tester.enterText(find.byType(TextFormField).at(3), 'StrongPass1');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.ensureVisible(find.text('CREATE ACCOUNT'));
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter the 6-digit code sent to your email.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField).at(0), '123456');
    await tester.ensureVisible(find.text('VERIFY EMAIL'));
    await tester.tap(find.text('VERIFY EMAIL'));
    await tester.pumpAndSettle();

    expect(find.text('Email is verified. Sign in to continue.'), findsNothing);
    expect(
      find.text('Your email is verified. Sign in to continue.'),
      findsOneWidget,
    );
    expect(paths, ['/api/auth/signup', '/api/auth/verify-email']);
  });

  testWidgets('signup does not claim email verification when delivery failed', (
    tester,
  ) async {
    final auth = _auth(
      MockClient(
        (_) async => http.Response(
          '{"account_created":true,"email_verified":false,"verification_email_sent":false,"message":"Account created, but the verification email could not be sent."}',
          200,
        ),
      ),
    );
    await tester.pumpWidget(_screen(auth: auth, initialMode: 'signup'));

    await tester.enterText(find.byType(TextFormField).at(0), 'Sam User');
    await tester.enterText(find.byType(TextFormField).at(1), 'sam@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'StrongPass1');
    await tester.enterText(find.byType(TextFormField).at(3), 'StrongPass1');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.ensureVisible(find.text('CREATE ACCOUNT'));
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Your account was created. Email verification is unavailable right now.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Your email is verified. Sign in to continue.'),
      findsNothing,
    );
    expect(find.text('BACK TO LOGIN'), findsOneWidget);
  });

  testWidgets('login forwards Remember me choice and displays backend errors', (
    tester,
  ) async {
    final auth = _auth(
      MockClient((request) async {
        expect(request.url.path, '/api/auth/login');
        expect(request.bodyFields['remember_me'], 'false');
        return http.Response('{"detail":"bad credentials"}', 401);
      }),
    );
    await tester.pumpWidget(_screen(auth: auth));

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'StrongPass1');
    await tester.tap(find.byType(Checkbox).first);
    await tester.ensureVisible(find.text('LOGIN'));
    await tester.tap(find.text('LOGIN').last);
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password.'), findsOneWidget);
  });

  testWidgets('login displays a clear message when the API request times out', (
    tester,
  ) async {
    final auth = AuthService(
      api: ApiService(
        client: MockClient((_) => Completer<http.Response>().future),
        baseUri: Uri.parse('https://api.example.test/api'),
        timeout: const Duration(milliseconds: 10),
      ),
    );
    await tester.pumpWidget(_screen(auth: auth));

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'StrongPass1');
    await tester.ensureVisible(find.text('LOGIN'));
    await tester.tap(find.text('LOGIN').last);
    await tester.pumpAndSettle();

    expect(
      find.text('The server took too long to respond. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('theme switch updates login, signup, and admin sign-in themes', (
    tester,
  ) async {
    final auth = _auth(MockClient((_) async => http.Response('{}', 200)));

    Future<void> verifyThemeSwitch(String initialMode) async {
      var isDarkMode = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            key: ValueKey(initialMode),
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: AuthenticationScreen(
              authService: auth,
              initialMode: initialMode,
              onThemeChanged: (value) => setState(() => isDarkMode = value),
              onAuthenticated: (_) {},
              onAdminAuthenticated: (_) {},
            ),
          ),
        ),
      );

      expect(find.byTooltip('Switch to dark theme'), findsOneWidget);
      await tester.tap(find.byTooltip('Switch to dark theme'));
      await tester.pumpAndSettle();
      expect(isDarkMode, isTrue);
      expect(
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.dark,
      );
      expect(find.byTooltip('Switch to light theme'), findsOneWidget);
    }

    await verifyThemeSwitch('login');
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
    await tester.tap(find.byTooltip('Switch to light theme'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.light,
    );

    await verifyThemeSwitch('admin');
    expect(find.text('ADMIN PORTAL'), findsOneWidget);
  });

  testWidgets('user login validates the returned role before authentication', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    User? authenticatedUser;
    var adminCallbackCalled = false;
    final auth = _auth(
      MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return http.Response('{"access_token":"user-token"}', 200);
        }
        expect(request.url.path, '/api/auth/me');
        expect(request.headers['authorization'], startsWith('Bearer '));
        return http.Response(
          jsonEncode({
            'id': 3,
            'full_name': 'Sam User',
            'email': 'sam@example.com',
            'role': 'user',
            'is_active': true,
            'email_verified': true,
            'two_factor_enabled': false,
          }),
          200,
        );
      }),
    );
    await tester.pumpWidget(
      _screen(
        auth: auth,
        onAuthenticated: (user) => authenticatedUser = user,
        onAdminAuthenticated: (_) => adminCallbackCalled = true,
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'sam@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'StrongPass1');
    tester.testTextInput.hide();
    await tester.pump();
    await tester.ensureVisible(find.text('LOGIN'));
    await tester.tap(find.text('LOGIN').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(authenticatedUser?.role, 'user');
    expect(authenticatedUser?.email, 'sam@example.com');
    expect(adminCallbackCalled, isFalse);
  });

  testWidgets('admin login verifies second factor before admin callback', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    User? authenticatedUser;
    User? adminUser;
    final auth = _auth(
      MockClient((request) async {
        if (request.url.path == '/api/auth/admin/login') {
          return http.Response(
            '{"requires_two_factor":true,"challenge_id":"admin-challenge"}',
            200,
          );
        }
        if (request.url.path == '/api/auth/login/verify') {
          expect(jsonDecode(request.body), {
            'challenge_id': 'admin-challenge',
            'code': '123456',
            'remember_me': true,
          });
          return http.Response('{"access_token":"admin-token"}', 200);
        }
        expect(request.url.path, '/api/auth/me');
        expect(request.headers['authorization'], startsWith('Bearer '));
        return http.Response(
          jsonEncode({
            'id': 7,
            'full_name': 'Admin User',
            'email': 'admin@example.com',
            'role': 'admin',
            'is_active': true,
            'email_verified': true,
            'two_factor_enabled': true,
          }),
          200,
        );
      }),
    );
    await tester.pumpWidget(
      _screen(
        auth: auth,
        initialMode: 'admin',
        onAuthenticated: (user) => authenticatedUser = user,
        onAdminAuthenticated: (user) => adminUser = user,
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'StrongPass1');
    await tester.ensureVisible(find.text('ADMIN LOGIN'));
    await tester.tap(find.text('ADMIN LOGIN'));
    await tester.pumpAndSettle();
    expect(find.text('Verification code'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '123456');
    await tester.ensureVisible(find.text('VERIFY AND SIGN IN'));
    await tester.tap(find.text('VERIFY AND SIGN IN'));
    await tester.pumpAndSettle();

    expect(adminUser?.role, 'admin');
    expect(adminUser?.email, 'admin@example.com');
    expect(authenticatedUser, isNull);
  });

  testWidgets('user portal rejects an admin profile returned by the API', (
    tester,
  ) async {
    var authenticatedCallbackCalled = false;
    final auth = _auth(
      MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return http.Response('{"access_token":"wrong-role-token"}', 200);
        }
        return http.Response(
          jsonEncode({
            'id': 7,
            'full_name': 'Admin User',
            'email': 'admin@example.com',
            'role': 'admin',
            'is_active': true,
            'email_verified': true,
            'two_factor_enabled': true,
          }),
          200,
        );
      }),
    );
    await tester.pumpWidget(
      _screen(
        auth: auth,
        onAuthenticated: (_) => authenticatedCallbackCalled = true,
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'StrongPass1');
    await tester.ensureVisible(find.text('LOGIN'));
    await tester.tap(find.text('LOGIN').last);
    await tester.pumpAndSettle();

    expect(authenticatedCallbackCalled, isFalse);
    expect(
      find.text('This account cannot access the ScamShield user portal.'),
      findsOneWidget,
    );
  });

  testWidgets('login, signup and admin sign-in fit a narrow phone screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _auth(MockClient((_) async => http.Response('{}', 200)));
    await tester.pumpWidget(_screen(auth: auth));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Already have an account? Login'));
    await tester.tap(find.text('Already have an account? Login'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Admin Sign-in'));
    await tester.tap(find.text('Admin Sign-in'));
    await tester.pumpAndSettle();

    expect(find.text('SCAMSHIELD'), findsOneWidget);
    expect(find.text('ADMIN PORTAL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('forgot password uses real reset endpoints and validates code', (
    tester,
  ) async {
    final paths = <String>[];
    final auth = _auth(
      MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path == '/api/auth/forgot-password') {
          expect(jsonDecode(request.body), {'email': 'test@example.com'});
          return http.Response(
            '{"message":"If an active account exists, a code will be sent.","challenge_id":"reset-challenge"}',
            200,
          );
        }
        expect(request.url.path, '/api/auth/reset-password');
        expect(jsonDecode(request.body), {
          'challenge_id': 'reset-challenge',
          'code': '123456',
          'remember_me': false,
          'new_password': 'NewStrongPass1',
        });
        return http.Response('{"message":"Password successfully reset."}', 200);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(home: PasswordResetScreen(authService: auth)),
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      'test@example.com',
    );
    await tester.tap(find.text('SEND RESET LINK'));
    await tester.pumpAndSettle();
    expect(find.textContaining('If an active account exists'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '123456');
    await tester.enterText(find.byType(TextFormField).at(1), 'NewStrongPass1');
    await tester.enterText(find.byType(TextFormField).at(2), 'NewStrongPass1');
    await tester.ensureVisible(find.text('RESET PASSWORD'));
    await tester.tap(find.text('RESET PASSWORD'));
    await tester.pumpAndSettle();

    expect(find.text('Password updated'), findsOneWidget);
    expect(paths, ['/api/auth/forgot-password', '/api/auth/reset-password']);
  });
}
