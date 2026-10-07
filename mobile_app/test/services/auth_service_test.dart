import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/services/api_service.dart';
import 'package:scamshield_guardian/services/auth_service.dart';

void main() {
  test(
    'sign-up submits normalized account fields and reads verification state',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/auth/signup');
        expect(jsonDecode(request.body), {
          'full_name': 'Sam User',
          'email': 'sam@example.com',
          'password': 'StrongPass1',
        });
        return http.Response(
          jsonEncode({
            'account_created': true,
            'email_verified': false,
            'verification_email_sent': true,
            'verification_challenge_id': 'challenge-id',
            'message': 'Account created.',
          }),
          200,
        );
      });
      final auth = AuthService(
        api: ApiService(
          client: client,
          baseUri: Uri.parse('https://api.example.test/api'),
        ),
      );

      final result = await auth.signUp(
        fullName: '  Sam User  ',
        email: ' sam@example.com ',
        password: 'StrongPass1',
      );

      expect(result.verificationEmailSent, isTrue);
      expect(result.challengeId, 'challenge-id');
    },
  );

  test('email verification uses the existing verification endpoint', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/auth/verify-email');
      expect(jsonDecode(request.body), {
        'challenge_id': 'challenge-id',
        'code': '123456',
      });
      return http.Response('{"email_verified":true}', 200);
    });
    final auth = AuthService(
      api: ApiService(
        client: client,
        baseUri: Uri.parse('https://api.example.test/api'),
      ),
    );

    await expectLater(
      auth.verifyEmail(challengeId: 'challenge-id', code: '123456'),
      completes,
    );
  });

  test('admin login keeps the admin verification challenge and role', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final client = MockClient((request) async {
      if (request.url.path == '/api/auth/admin/login') {
        expect(request.method, 'POST');
        expect(request.bodyFields, {
          'username': 'admin@example.com',
          'password': 'StrongPass1',
          'remember_me': 'true',
        });
        return http.Response(
          '{"requires_two_factor":true,"challenge_id":"admin-challenge"}',
          200,
        );
      }
      if (request.url.path == '/api/auth/login/verify') {
        expect(request.method, 'POST');
        expect(jsonDecode(request.body), {
          'challenge_id': 'admin-challenge',
          'code': '123456',
          'remember_me': true,
        });
        return http.Response('{"access_token":"admin-token"}', 200);
      }
      expect(request.url.path, '/api/auth/me');
      expect(request.headers['authorization'], 'Bearer admin-token');
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
    });
    final auth = AuthService(
      api: ApiService(
        client: client,
        baseUri: Uri.parse('https://api.example.test/api'),
      ),
    );

    final challenge = await auth.login(
      'admin@example.com',
      'StrongPass1',
      isAdmin: true,
    );
    expect(challenge.isAdmin, isTrue);
    expect(challenge.challengeId, 'admin-challenge');

    final result = await auth.verifyLogin(
      challengeId: challenge.challengeId!,
      code: '123456',
      isAdmin: challenge.isAdmin,
    );
    expect(result.isAdmin, isTrue);
    expect(result.user?.role, 'admin');
    expect(await auth.getStoredAdminToken(), 'admin-token');
    expect(await auth.getStoredToken(), isNull);
  });

  test(
    'password reset uses backend code request and reset contracts',
    () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/auth/forgot-password') {
          expect(jsonDecode(request.body), {'email': 'user@example.com'});
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
      });
      final auth = AuthService(
        api: ApiService(
          client: client,
          baseUri: Uri.parse('https://api.example.test/api'),
        ),
      );

      final challengeId = await auth.requestPasswordReset(' user@example.com ');
      expect(challengeId, 'reset-challenge');
      await expectLater(
        auth.resetPassword(
          challengeId: challengeId,
          code: '123456',
          newPassword: 'NewStrongPass1',
        ),
        completes,
      );
    },
  );
}
