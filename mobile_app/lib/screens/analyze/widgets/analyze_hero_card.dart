import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// Luminous hero card matching "Analyze & Stay Safe" across all 4 reference screens.
class AnalyzeHeroCard extends StatelessWidget {
  const AnalyzeHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? const Color(0xFF14242E)
        : const Color(0xFFE8F7F9);
    final borderColor = isDark
        ? const Color(0xFF1F3543)
        : const Color(0xFFC3EDF3);
    final primaryTeal = isDark
        ? AppColors.darkPrimary
        : AppColors.primary;
    final subtitleColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: borderColor, width: 1.2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF162A36),
                  Color(0xFF111E27),
                ]
              : const [
                  Color(0xFFEFFBFC),
                  Color(0xFFE2F5F8),
                ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sparkle-surrounded Document Search Vector Badge
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Top-left sparkle
                Positioned(
                  top: 4,
                  left: 2,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: primaryTeal.withValues(alpha: 0.8),
                  ),
                ),
                // Bottom-right sparkle
                Positioned(
                  bottom: 6,
                  right: 2,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 12,
                    color: primaryTeal.withValues(alpha: 0.7),
                  ),
                ),
                // Center Icon Container
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F323D)
                        : const Color(0xFFD6F3F7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryTeal.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    Icons.manage_search_rounded,
                    size: 34,
                    color: primaryTeal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Analyze & Stay Safe',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: primaryTeal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check messages, calls, images, documents and audio with AI to detect scams.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}
