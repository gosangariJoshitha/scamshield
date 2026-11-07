class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    this.relationshipType = 'Family',
    this.isActive = true,
    this.notifySms = true,
    required this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int userId;
  final String name;
  final String phoneNumber;
  final String relationshipType;
  final bool isActive;
  final bool notifySms;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      relationshipType: json['relationship_type'] as String? ?? 'Family',
      isActive: json['is_active'] as bool? ?? true,
      notifySms: json['notify_sms'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone_number': phoneNumber,
      'relationship_type': relationshipType,
      'is_active': isActive,
      'notify_sms': notifySms,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  EmergencyContact copyWith({
    int? id,
    int? userId,
    String? name,
    String? phoneNumber,
    String? relationshipType,
    bool? isActive,
    bool? notifySms,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationshipType: relationshipType ?? this.relationshipType,
      isActive: isActive ?? this.isActive,
      notifySms: notifySms ?? this.notifySms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

