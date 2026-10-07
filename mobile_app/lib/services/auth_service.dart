import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import 'api_service.dart';

class LoginResult {
  const LoginResult.authenticated(this.user, {this.isAdmin = false})
    : challengeId = null;
  const LoginResult.requiresVerification(
    this.challengeId, {
    this.isAdmin = false,
  }) : user = null;

  final User? user;
  final String? challengeId;
  final bool isAdmin;
}

class SignupResult {
  const SignupResult({required this.verificationEmailSent, this.challengeId});

  final bool verificationEmailSent;
  final String? challengeId;
}

class AuthService {
  static const _sessionRestoreTimeout = Duration(seconds: 8);

  AuthService({required this._api, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'scamshield_access_token';
  static const _adminTokenKey = 'scamshield_admin_access_token';
  final ApiService _api;
  final FlutterSecureStorage _storage;

  Future<SignupResult> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _api.postJson('/auth/signup', {
      'full_name': fullName.trim(),
      'email': email.trim(),
      'password': password,
    });
    final json = _asJsonObject(response, 'Sign-up');
    if (json['account_created'] != true) {
      throw const ApiException('ScamShield could not create the account.');
    }
    final challengeId = json['verification_challenge_id'];
    if (challengeId != null && challengeId is! String) {
      throw const ApiException(
        'ScamShield returned an invalid verification challenge.',
      );
    }
    final verificationEmailSent = json['verification_email_sent'] == true;
    if (verificationEmailSent && challengeId == null) {
      throw const ApiException(
        'ScamShield did not return the email verification request.',
      );
    }
    return SignupResult(
      verificationEmailSent: verificationEmailSent,
      challengeId: challengeId as String?,
    );
  }

  Future<void> verifyEmail({
    required String challengeId,
    required String code,
  }) async {
    final response = await _api.postJson('/auth/verify-email', {
      'challenge_id': challengeId,
      'code': code,
    });
    final json = _asJsonObject(response, 'Email verification');
    if (json['email_verified'] != true) {
      throw const ApiException('ScamShield could not verify this email.');
    }
  }

  Future<String> requestPasswordReset(String email) async {
    final response = await _api.postJson('/auth/forgot-password', {
      'email': email.trim(),
    });
    final json = _asJsonObject(response, 'Password reset');
    final challengeId = json['challenge_id'];
    if (challengeId is! String || challengeId.isEmpty) {
      throw const ApiException(
        'The password reset request could not be completed.',
      );
    }
    return challengeId;
  }

  Future<void> resetPassword({
    required String challengeId,
    required String code,
    required String newPassword,
  }) async {
    final response = await _api.postJson('/auth/reset-password', {
      'challenge_id': challengeId,
      'code': code,
      'remember_me': false,
      'new_password': newPassword,
    });
    final json = _asJsonObject(response, 'Password reset');
    if (json['message'] is! String) {
      throw const ApiException('The password reset could not be completed.');
    }
  }

  Future<LoginResult> login(
    String email,
    String password, {
    bool isAdmin = false,
    bool rememberMe = true,
  }) async {
    final response = await _api.postForm(
      isAdmin ? '/auth/admin/login' : '/auth/login',
      {
        'username': email.trim(),
        'password': password,
        'remember_me': rememberMe.toString(),
      },
    );
    final json = _asJsonObject(response, 'Login');
    if (json['requires_two_factor'] == true) {
      final challengeId = json['challenge_id'];
      if (challengeId is! String || challengeId.isEmpty) {
        throw const ApiException(
          'The sign-in verification challenge is missing.',
        );
      }
      return LoginResult.requiresVerification(challengeId, isAdmin: isAdmin);
    }
    return _completeLogin(json, isAdmin: isAdmin, rememberMe: rememberMe);
  }

  Future<LoginResult> verifyLogin({
    required String challengeId,
    required String code,
    bool isAdmin = false,
    bool rememberMe = true,
  }) async {
    final response = await _api.postJson('/auth/login/verify', {
      'challenge_id': challengeId,
      'code': code,
      'remember_me': rememberMe,
    });
    return _completeLogin(
      _asJsonObject(response, 'Verification'),
      isAdmin: isAdmin,
      rememberMe: rememberMe,
    );
  }

  Future<User?> getCurrentUser() async {
    return _getCurrentUser(
      token: await getStoredToken(),
      expectedRole: 'user',
      clearSession: logout,
    );
  }

  Future<User?> getCurrentAdminUser() async {
    return _getCurrentUser(
      token: await getStoredAdminToken(),
      expectedRole: 'admin',
      clearSession: logoutAdmin,
    );
  }

  Future<User?> _getCurrentUser({
    required String? token,
    required String expectedRole,
    required Future<void> Function() clearSession,
  }) async {
    if (token == null) return null;
    try {
      final response = await _api.get(
        '/auth/me',
        token: token,
        requestTimeout: _sessionRestoreTimeout,
      );
      final user = User.fromJson(_asJsonObject(response, 'Profile'));
      if (user.role != expectedRole || !user.isActive) {
        await clearSession();
        return null;
      }
      return user;
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await clearSession();
        return null;
      }
      rethrow;
    } on FormatException {
      await clearSession();
      throw const ApiException(
        'ScamShield returned an invalid account profile. Please sign in again.',
      );
    }
  }

  Future<String?> getStoredToken() => _storage.read(key: _tokenKey);

  Future<String?> getStoredAdminToken() => _storage.read(key: _adminTokenKey);

  Future<bool> isAuthenticated() async => (await getStoredToken()) != null;

  Future<void> logout() => _storage.delete(key: _tokenKey);

  Future<void> logoutAdmin() => _storage.delete(key: _adminTokenKey);

  Future<LoginResult> _completeLogin(
    Map<String, dynamic> json, {
    required bool isAdmin,
    required bool rememberMe,
  }) async {
    final token = json['access_token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException('The sign-in response did not include a token.');
    }
    final profile = await _api.get('/auth/me', token: token);
    final user = User.fromJson(_asJsonObject(profile, 'Profile'));
    final expectedRole = isAdmin ? 'admin' : 'user';
    if (user.role != expectedRole || !user.isActive) {
      throw ApiException(
        isAdmin
            ? 'This account cannot access the ScamShield admin portal.'
            : 'This account cannot access the ScamShield user portal.',
      );
    }
    if (isAdmin) {
      await logout();
      if (rememberMe) {
        await _storage.write(key: _adminTokenKey, value: token);
      } else {
        await logoutAdmin();
      }
    } else {
      await logoutAdmin();
      await _storage.write(key: _tokenKey, value: token);
    }
    return LoginResult.authenticated(user, isAdmin: isAdmin);
  }

  Map<String, dynamic> _asJsonObject(dynamic value, String responseName) {
    if (value is Map<String, dynamic>) return value;
    throw ApiException('$responseName returned an invalid response.');
  }
}
