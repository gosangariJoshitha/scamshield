class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.emailVerified,
    required this.twoFactorEnabled,
    this.emailNotifications = true,
    this.communityUpdates = true,
    this.marketingUpdates = false,
  });

  final int id;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final bool emailVerified;
  final bool twoFactorEnabled;
  final bool emailNotifications;
  final bool communityUpdates;
  final bool marketingUpdates;

  User copyWith({
    int? id,
    String? fullName,
    String? email,
    String? role,
    bool? isActive,
    bool? emailVerified,
    bool? twoFactorEnabled,
    bool? emailNotifications,
    bool? communityUpdates,
    bool? marketingUpdates,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      emailVerified: emailVerified ?? this.emailVerified,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      communityUpdates: communityUpdates ?? this.communityUpdates,
      marketingUpdates: marketingUpdates ?? this.marketingUpdates,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _requiredInt(json, 'id'),
      fullName: _requiredString(json, 'full_name'),
      email: _requiredString(json, 'email'),
      role: _requiredString(json, 'role'),
      isActive: _requiredBool(json, 'is_active'),
      emailVerified: _requiredBool(json, 'email_verified'),
      twoFactorEnabled: json['two_factor_enabled'] as bool? ?? false,
      emailNotifications: json['email_notifications'] as bool? ?? true,
      communityUpdates: json['community_updates'] as bool? ?? true,
      marketingUpdates: json['marketing_updates'] as bool? ?? false,
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
