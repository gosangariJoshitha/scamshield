import 'package:flutter/material.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotification copyWith({
    int? id,
    int? userId,
    String? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      type: json['type'] as String? ?? 'SYSTEM',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }

  IconData get icon {
    switch (type.toUpperCase()) {
      case 'SECURITY_ALERT':
        return Icons.warning_amber_rounded;
      case 'CALL_ALERT':
        return Icons.phone_missed_rounded;
      case 'CALL_COMPLETE':
        return Icons.phone_in_talk_rounded;
      case 'ANALYSIS_COMPLETE':
        return Icons.check_circle_outline_rounded;
      case 'SYSTEM':
      default:
        return Icons.shield_rounded;
    }
  }

  Color get iconColor {
    switch (type.toUpperCase()) {
      case 'SECURITY_ALERT':
      case 'CALL_ALERT':
        return const Color(0xFFEF4444);
      case 'CALL_COMPLETE':
      case 'ANALYSIS_COMPLETE':
        return const Color(0xFF10B981);
      case 'SYSTEM':
      default:
        return const Color(0xFF06B6D4);
    }
  }
}
