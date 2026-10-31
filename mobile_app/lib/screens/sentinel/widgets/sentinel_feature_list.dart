import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class SentinelFeatureList extends StatelessWidget {
  const SentinelFeatureList({
    this.onTapRealTimeAlerts,
    this.onTapDatabase,
    this.onTapCommunity,
    super.key,
  });

  final VoidCallback? onTapRealTimeAlerts;
  final VoidCallback? onTapDatabase;
  final VoidCallback? onTapCommunity;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FeatureRowItem(
          icon: Icons.notifications_active_rounded,
          title: 'Real-time Alerts',
          subtitle: 'Get instant warnings for potential scams.',
          onTap: onTapRealTimeAlerts,
        ),
        const SizedBox(height: 10),
        _FeatureRowItem(
          icon: Icons.storage_rounded,
          title: 'Updated Scam Database',
          subtitle: 'Powered by latest scam patterns and community reports.',
          onTap: onTapDatabase,
        ),
        const SizedBox(height: 10),
        _FeatureRowItem(
          icon: Icons.groups_rounded,
          title: 'Community Protection',
          subtitle: 'Help others by reporting scams.',
          onTap: onTapCommunity,
        ),
      ],
    );
  }
}

class _FeatureRowItem extends StatelessWidget {
  const _FeatureRowItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.22 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.navy,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    ),
  ),
);
}
}
