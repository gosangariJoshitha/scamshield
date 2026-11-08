import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({
    required this.notificationService,
    this.onOpenAnalysis,
    this.onOpenCallSummary,
    super.key,
  });

  final NotificationService notificationService;
  final void Function(int analysisId)? onOpenAnalysis;
  final void Function(String sessionId)? onOpenCallSummary;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _loading = true;
  String? _error;
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.notificationService.getNotifications(limit: 50);
      if (!mounted) return;
      setState(() {
        _notifications = result.items;
        _unreadCount = result.unreadCount;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _markRead(AppNotification notification, int index) async {
    if (notification.isRead) return;
    try {
      final updated = await widget.notificationService.markAsRead(notification.id);
      if (!mounted) return;
      setState(() {
        _notifications[index] = updated;
        _unreadCount = (_unreadCount - 1).clamp(0, 9999);
      });
    } catch (_) {
      // Keep optimistic or current state
    }
  }

  Future<void> _markAllRead() async {
    if (_unreadCount == 0) return;
    try {
      await widget.notificationService.markAllAsRead();
      if (!mounted) return;
      setState(() {
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        _unreadCount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not mark all as read: $e')),
      );
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    final index = _notifications.indexWhere((n) => n.id == notification.id);
    if (index == -1) return;
    final wasRead = notification.isRead;
    final removed = notification;
    setState(() {
      _notifications.removeAt(index);
      if (!wasRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, 9999);
      }
    });

    try {
      await widget.notificationService.deleteNotification(notification.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification cleared')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notifications.insert(index.clamp(0, _notifications.length), removed);
        if (!wasRead) {
          _unreadCount += 1;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not clear notification: $e')),
      );
    }
  }

  Future<void> _handleNotificationTap(AppNotification notification, int index) async {
    await _markRead(notification, index);

    final msg = notification.message;
    // Route if analysis ID is embedded (e.g. "Analysis #101 flagged...")
    if (widget.onOpenAnalysis != null && (notification.type == 'SECURITY_ALERT' || notification.type == 'ANALYSIS_COMPLETE')) {
      final match = RegExp(r'#(\d+)').firstMatch(msg);
      if (match != null) {
        final analysisId = int.tryParse(match.group(1) ?? '');
        if (analysisId != null) {
          widget.onOpenAnalysis!(analysisId);
          return;
        }
      }
    }

    // Route if session ID is embedded (e.g. "Protected call session test-sess-999...")
    if (widget.onOpenCallSummary != null && (notification.type == 'CALL_ALERT' || notification.type == 'CALL_COMPLETE')) {
      final match = RegExp(r'session\s+([A-Za-z0-9_\-]+)').firstMatch(msg);
      if (match != null) {
        final sessionId = match.group(1);
        if (sessionId != null && sessionId.isNotEmpty) {
          widget.onOpenCallSummary!(sessionId);
          return;
        }
      }
    }
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text(
          'This will remove your notification history. Your analysis and call records will remain safely intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.notificationService.clearAll();
      if (!mounted) return;
      setState(() {
        _notifications.clear();
        _unreadCount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications cleared')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not clear notifications: $e')),
      );
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? AppColors.textMainDark : const Color(0xFF0F172A),
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty) ...[
            if (_unreadCount > 0)
              IconButton(
                tooltip: 'Mark all as read',
                icon: const Icon(Icons.done_all_rounded),
                onPressed: _markAllRead,
              ),
            IconButton(
              tooltip: 'Clear all notifications',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _confirmClearAll,
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadNotifications,
          child: _buildBody(context, isDark, colors),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark, ColorScheme colors) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
              const SizedBox(height: 12),
              Text(
                'Unable to load notifications',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadNotifications,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCardElevated
                          : colors.primaryContainer.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 38,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'No notifications yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Security alerts, completed analysis notifications, and call protection reports will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: _notifications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _notifications[index];
        return Dismissible(
          key: ValueKey('notification_${item.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
          onDismissed: (_) {
            _deleteNotification(item);
          },
          child: _NotificationTile(
            notification: item,
            isDark: isDark,
            timestamp: _formatTimestamp(item.createdAt),
            onTap: () => _handleNotificationTap(item, index),
            onDelete: () => _deleteNotification(item),
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.timestamp,
    required this.onTap,
    this.onDelete,
  });

  final AppNotification notification;
  final bool isDark;
  final String timestamp;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cardBg = isDark
        ? (notification.isRead ? AppColors.darkCard : AppColors.darkCardElevated)
        : (notification.isRead ? AppColors.lightCard : Colors.white);

    final borderColor = isDark
        ? (notification.isRead ? AppColors.darkBorder : AppColors.darkPrimary.withValues(alpha: 0.4))
        : (notification.isRead ? AppColors.lightBorder : colors.primary.withValues(alpha: 0.35));

    return Material(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: notification.isRead ? 1 : 1.5),
      ),
      elevation: (!isDark && !notification.isRead) ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: notification.iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                notification.icon,
                color: notification.iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                          ),
                        ),
                      ),
                      if (!notification.isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timestamp,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                tooltip: 'Clear notification',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}
