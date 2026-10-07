class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.emailVerified,
    required this.twoFactorEnabled,
  });

  final int id;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final bool emailVerified;
  final bool twoFactorEnabled;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _requiredInt(json, 'id'),
      fullName: _requiredString(json, 'full_name'),
      email: _requiredString(json, 'email'),
      role: _requiredString(json, 'role'),
      isActive: _requiredBool(json, 'is_active'),
      emailVerified: _requiredBool(json, 'email_verified'),
      twoFactorEnabled: json['two_factor_enabled'] as bool? ?? false,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('User response is missing $key.');
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    throw FormatException('User response is missing $key.');
  }

  static bool _requiredBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is bool) return value;
    throw FormatException('User response is missing $key.');
  }
}
