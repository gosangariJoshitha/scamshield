import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/brand_mark.dart';

/// Minimal footer for the ScamShield landing page.
/// Preserves the direct Admin Sign-in entry for administrator access.
class LandingFooter extends StatelessWidget {
  const LandingFooter({
    required this.onAdminSignIn,
    super.key,
  });

  final VoidCallback onAdminSignIn;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor =
        isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight;
    final primaryAccent =
        isDark ? AppColors.darkPrimary : AppColors.primary;

    return Column(
      children: [
        const ScamShieldBrandMark(size: 32),
        const SizedBox(height: 8),
        Text(
          'SCAMSHIELD',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Smarter Analysis. Safer Decisions. A Safer You.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: mutedColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _FooterLink(label: 'Privacy', color: mutedColor),
            _FooterDot(color: mutedColor),
            _FooterLink(label: 'Terms', color: mutedColor),
            _FooterDot(color: mutedColor),
            _FooterLink(label: 'Help', color: mutedColor),
            _FooterDot(color: mutedColor),
            _FooterLink(label: 'Contact', color: mutedColor),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '© 2026 ScamShield. All rights reserved.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: mutedColor.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 14),
        // Direct Admin Portal Sign-in entry point
        InkWell(
          onTap: onAdminSignIn,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 15,
                  color: primaryAccent,
                ),
                const SizedBox(width: 5),
                Text(
                  'Admin Sign-in',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _FooterDot extends StatelessWidget {
  const _FooterDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        '•',
        style: TextStyle(
          fontSize: 11,
          color: color.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
