import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/services/api_service.dart';

class _StalledBodyClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(Stream<List<int>>.multi((_) {}), 200);
  }
}

void main() {
  test('posts login form to the configured API base', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://api.example.test/api/auth/login');
      expect(request.method, 'POST');
      expect(
        request.headers['content-type'],
        contains('application/x-www-form-urlencoded'),
      );
      expect(request.bodyFields, {
        'username': 'user@example.com',
        'password': 'not-stored',
        'remember_me': 'true',
      });
      return http.Response('{"access_token":"token-value"}', 200);
    });
    final api = ApiService(
      client: client,
      baseUri: Uri.parse('https://api.example.test/api'),
    );

    final response = await api.postForm('/auth/login', {
      'username': 'user@example.com',
      'password': 'not-stored',
      'remember_me': 'true',
    });

    expect(response['access_token'], 'token-value');
  });

  test('attaches bearer token to authenticated requests', () async {
    final client = MockClient((request) async {
      expect(request.headers['authorization'], startsWith('Bearer '));
      return http.Response('{"id":4}', 200);
    });
    final api = ApiService(
      client: client,
      baseUri: Uri.parse('https://api.example.test/api'),
    );

    final response = await api.get('/auth/me', token: 'secure-token');

    expect(response['id'], 4);
  });

  test('uploads analysis file as authenticated multipart data', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/analysis/image');
      expect(request.headers['authorization'], startsWith('Bearer '));
      expect(
        request.headers['content-type'],
        startsWith('multipart/form-data'),
      );
      expect(request.body, contains('filename="screenshot.png"'));
      expect(request.body, contains('name="file"'));
      expect(request.body, contains('image-bytes'));
      return http.Response('{"id":8}', 200);
    });
    final api = ApiService(
      client: client,
      baseUri: Uri.parse('https://api.example.test/api'),
    );

    final response = await api.postMultipart(
      path: '/analysis/image',
      fieldName: 'file',
      bytes: 'image-bytes'.codeUnits,
      filename: 'screenshot.png',
      token: 'session-token',
    );

    expect(response['id'], 8);
  });

  test('posts new-account data to the existing signup endpoint', () async {
    final client = MockClient((request) async {
      expect(
        request.url.toString(),
        'https://api.example.test/api/auth/signup',
      );
      expect(request.method, 'POST');
      expect(request.headers['content-type'], contains('application/json'));
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
    final api = ApiService(
      client: client,
      baseUri: Uri.parse('https://api.example.test/api'),
    );

    final response = await api.postJson('/auth/signup', {
      'full_name': 'Sam User',
      'email': 'sam@example.com',
      'password': 'StrongPass1',
    });

    expect(response['account_created'], isTrue);
    expect(response['verification_challenge_id'], 'challenge-id');
  });

  test('maps duplicate-account responses to a clear signup error', () async {
    final api = ApiService(
      client: MockClient(
        (_) async =>
            http.Response('{"detail":"Email already registered"}', 409),
      ),
      baseUri: Uri.parse('https://api.example.test/api'),
    );

    await expectLater(
      api.postJson('/auth/signup', const {}),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'An account with this email already exists.',
        ),
      ),
    );
  });

  test('converts unauthorized responses into a user-friendly error', () async {
    final api = ApiService(
      client: MockClient(
        (_) async => http.Response('{"detail":"bad credentials"}', 401),
      ),
      baseUri: Uri.parse('https://api.example.test/api'),
    );

    await expectLater(
      api.postForm('/auth/login', const {}),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'status code', 401)
            .having(
              (error) => error.message,
              'message',
              'Invalid email or password.',
            ),
      ),
    );
  });

  test('times out a response body that stops streaming', () async {
    final api = ApiService(
      client: _StalledBodyClient(),
      baseUri: Uri.parse('https://api.example.test/api'),
      timeout: const Duration(milliseconds: 10),
    );

    await expectLater(
      api.get('/health'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'The server took too long to respond. Please try again.',
        ),
      ),
    );
  });

  test('allows session restoration to use a shorter request timeout', () async {
    final api = ApiService(
      client: _StalledBodyClient(),
      baseUri: Uri.parse('https://api.example.test/api'),
      timeout: const Duration(seconds: 1),
    );

    await expectLater(
      api.get('/auth/me', requestTimeout: const Duration(milliseconds: 10)),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'The server took too long to respond. Please try again.',
        ),
      ),
    );
  });
}
