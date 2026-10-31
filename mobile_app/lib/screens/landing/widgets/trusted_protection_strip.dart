import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// "TRUSTED PROTECTION" 3-pillar trust strip matching the hero fold
/// of the approved ScamShield 2.0 blueprint (1000261210.png).
///
/// Features colorful glowing circular icon containers for each security pillar.
class TrustedProtectionStrip extends StatelessWidget {
  const TrustedProtectionStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor =
        isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight;
    final labelColor =
        isDark ? AppColors.textMainDark : AppColors.textMainLight;

    return Column(
      children: [
        // Micro-header with subtle divider lines
        Row(
          children: [
            Expanded(
              child: Divider(
                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                    .withValues(alpha: 0.6),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'TRUSTED PROTECTION',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                  color: headerColor,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                    .withValues(alpha: 0.6),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 3 Colorful Trust Pillars
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _PillarItem(
                icon: Icons.verified_user_rounded,
                label: 'AI-Powered\nAnalysis',
                iconColor: isDark ? const Color(0xFF22D3EE) : const Color(0xFF0891B2),
                bgTint: isDark ? const Color(0xFF083344) : const Color(0xFFE0F2FE),
                labelColor: labelColor,
              ),
            ),
            Expanded(
              child: _PillarItem(
                icon: Icons.lock_rounded,
                label: 'Your Data\nStays Private',
                iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                bgTint: isDark ? const Color(0xFF1E293B) : const Color(0xFFDBEAFE),
                labelColor: labelColor,
              ),
            ),
            Expanded(
              child: _PillarItem(
                icon: Icons.groups_rounded,
                label: 'Safer Digital\nCommunities',
                iconColor: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                bgTint: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                labelColor: labelColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PillarItem extends StatelessWidget {
  const _PillarItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgTint,
    required this.labelColor,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgTint;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgTint,
            shape: BoxShape.circle,
            border: Border.all(
              color: iconColor.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.20),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, size: 19, color: iconColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.25,
            color: labelColor,
          ),
        ),
      ],
    );
  }
}
