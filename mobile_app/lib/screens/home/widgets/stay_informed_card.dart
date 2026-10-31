import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// "Stay Informed" educational card matching Section G of the approved
/// ScamShield 2.0 Home Dashboard blueprint (home and analysis page.jpeg).
class StayInformedCard extends StatelessWidget {
  const StayInformedCard({
    this.onTap,
    super.key,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF192630) : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
    final headlineColor =
        isDark ? AppColors.textMainDark : AppColors.textMainLight;
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Glowing Amber Lightbulb Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF452205) : const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(
                        alpha: isDark ? 0.25 : 0.15,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 22,
                    color: Color(0xFFF59E0B), // Amber
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title and Advice
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Stay Informed',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: headlineColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Check messages, calls, images and documents to stay safe from scams.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: subtitleColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Chevron Affordance
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
