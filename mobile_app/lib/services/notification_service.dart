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
    required this.authService,
  });

  final ApiService api;
  final AuthService authService;

  Future<NotificationListResult> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final token = await authService.getStoredToken();
    if (token == null) {
      throw const ApiException('Authentication required to load notifications.');
    }

    final query = 'page=$page&limit=$limit&unread_only=$unreadOnly';
    final response = await api.get('/notifications?$query', token: token);
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Unexpected response while fetching notifications.');
    }

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

  Future<int> getUnreadCount() async {
    final token = await authService.getStoredToken();
    if (token == null) return 0;

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
    final token = await authService.getStoredToken();
    if (token == null) {
      throw const ApiException('Authentication required.');
    }

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
    final token = await authService.getStoredToken();
    if (token == null) {
      throw const ApiException('Authentication required.');
    }

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

  Future<int> clearAll() async {
    final token = await authService.getStoredToken();
    if (token == null) {
      throw const ApiException('Authentication required.');
    }

    final response = await api.delete('/notifications', token: token);
    if (response is Map<String, dynamic>) {
      return response['deleted'] as int? ?? 0;
    }
    return 0;
  }
}
