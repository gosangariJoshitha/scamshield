import '../models/app_notification.dart';
import 'api_service.dart';
import 'auth_service.dart';

class NotificationListResult {
  const NotificationListResult({
    required this.items,
    required this.total,
    required this.unreadCount,
    required this.page,
    required this.limit,
    required this.hasNext,
  });

  final List<AppNotification> items;
  final int total;
  final int unreadCount;
  final int page;
  final int limit;
  final bool hasNext;
}

class NotificationService {
  NotificationService({
    required this.api,
    this.authService,
    this.tokenProvider,
  });

  final ApiService api;
  final AuthService? authService;
  final Future<String?> Function()? tokenProvider;

  Future<String?> _resolveToken() async {
    if (tokenProvider != null) {
      return await tokenProvider!();
    }
    if (authService != null) {
      return await authService!.getStoredToken();
    }
    return null;
  }

  Future<NotificationListResult> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final token = await _resolveToken();
    final query = 'page=$page&limit=$limit&unread_only=$unreadOnly';
    final response = await api.get('/notifications?$query', token: token);
    if (response is Map<String, dynamic>) {
      final rawItems = response['items'] as List<dynamic>? ?? [];
      final items = rawItems
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();

      return NotificationListResult(
        items: items,
        total: response['total'] as int? ?? items.length,
        unreadCount: response['unread_count'] as int? ?? 0,
        page: response['page'] as int? ?? page,
        limit: response['limit'] as int? ?? limit,
        hasNext: response['has_next'] as bool? ?? false,
      );
    }
    if (response is List) {
      final items = response
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();
      return NotificationListResult(
        items: items,
        total: items.length,
        unreadCount: items.where((n) => !n.isRead).length,
        page: page,
        limit: limit,
        hasNext: false,
      );
    }

    throw const ApiException('Unexpected response while fetching notifications.');
  }

  Future<int> getUnreadCount() async {
    final token = await _resolveToken();
    try {
      final response = await api.get('/notifications/unread-count', token: token);
      if (response is Map<String, dynamic>) {
        return response['unread_count'] as int? ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<AppNotification> markAsRead(int notificationId) async {
    final token = await _resolveToken();
    final response = await api.postJson(
      '/notifications/$notificationId/read',
      {},
      token: token,
    );
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Unexpected response from server.');
    }
    return AppNotification.fromJson(response);
  }

  Future<int> markAllAsRead() async {
    final token = await _resolveToken();
    final response = await api.postJson(
      '/notifications/read-all',
      {},
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return response['marked_read'] as int? ?? 0;
    }
    return 0;
  }

  Future<bool> deleteNotification(int notificationId) async {
    final token = await _resolveToken();
    final response = await api.delete(
      '/notifications/$notificationId',
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return response['deleted'] as bool? ?? true;
    }
    return true;
  }

  Future<int> clearAll() async {
    final token = await _resolveToken();
    final response = await api.delete('/notifications', token: token);
    if (response is Map<String, dynamic>) {
      return response['deleted'] as int? ?? 0;
    }
    return 0;
  }
}
