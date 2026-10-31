import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class ProtectionGrid2x2 extends StatelessWidget {
  const ProtectionGrid2x2({
    this.onTapCallProtection,
    this.onTapMessageProtection,
    this.onTapLinkProtection,
    this.onTapWebProtection,
    super.key,
  });

  final VoidCallback? onTapCallProtection;
  final VoidCallback? onTapMessageProtection;
  final VoidCallback? onTapLinkProtection;
  final VoidCallback? onTapWebProtection;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ProtectionCard(
                icon: Icons.phone_in_talk_rounded,
                title: 'Call Protection',
                badgeText: 'Active',
                badgeColor: const Color(0xFF10B981),
                description: 'Identifies and analyzes suspicious calls in real-time.',
                onTap: onTapCallProtection,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProtectionCard(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Message Protection',
                badgeText: 'Active',
                badgeColor: const Color(0xFF10B981),
                description: 'Scans SMS and messaging apps for scam content.',
                onTap: onTapMessageProtection,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ProtectionCard(
                icon: Icons.link_rounded,
                title: 'Link Protection',
                badgeText: 'Active',
                badgeColor: const Color(0xFF10B981),
                description: 'Checks suspicious links before you open them.',
                onTap: onTapLinkProtection,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProtectionCard(
                icon: Icons.language_rounded,
                title: 'Web Protection',
                badgeText: 'Active',
                badgeColor: const Color(0xFF10B981),
                description: 'Warns about risky and phishing websites.',
                onTap: onTapWebProtection,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProtectionCard extends StatelessWidget {
  const _ProtectionCard({
    required this.icon,
    required this.title,
    required this.badgeText,
    required this.badgeColor,
    required this.description,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String badgeText;
  final Color badgeColor;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: const Color(0xFF0284C7),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.navy,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
