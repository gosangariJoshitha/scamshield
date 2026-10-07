import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_guardian/models/user.dart';

void main() {
  test('parses the existing backend user response contract', () {
    final user = User.fromJson({
      'id': 7,
      'full_name': 'ScamShield User',
      'email': 'user@example.com',
      'role': 'user',
      'is_active': true,
      'email_verified': false,
      'two_factor_enabled': true,
    });

    expect(user.id, 7);
    expect(user.fullName, 'ScamShield User');
    expect(user.email, 'user@example.com');
    expect(user.isActive, isTrue);
    expect(user.emailVerified, isFalse);
    expect(user.twoFactorEnabled, isTrue);
  });

  test('rejects profiles missing required backend fields', () {
    expect(() => User.fromJson({'id': 7}), throwsA(isA<FormatException>()));
  });
}
