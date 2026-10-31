import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// "Quick Actions" 4-shortcut card matching Section E of the approved
/// ScamShield 2.0 Home Dashboard blueprint (home and analysis page.jpeg).
///
/// Elevated with vibrant category colors, tactile styling, and clear
/// sub-labels indicating the supported threat modalities.
class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({
    required this.onAnalyzeMessage,
    required this.onCallProtection,
    required this.onImageDocument,
    required this.onAnalyzeAudio,
    super.key,
  });

  final VoidCallback onAnalyzeMessage;
  final VoidCallback onCallProtection;
  final VoidCallback onImageDocument;
  final VoidCallback onAnalyzeAudio;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF192630) : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
    final headlineColor =
        isDark ? AppColors.textMainDark : AppColors.textMainLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title with Icon Badge
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF65D4D8) : const Color(0xFF086B73))
                      .withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFF65D4D8) : const Color(0xFF086B73),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: headlineColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 Action Buttons
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 340;

              return Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.chat_bubble_rounded,
                      title: compact ? 'Message' : 'Analyze\nMessage',
                      tag: 'Text & Links',
                      iconColor: const Color(0xFF0284C7), // Cyan/Blue
                      bgTint: isDark
                          ? const Color(0xFF082F49)
                          : const Color(0xFFE0F2FE),
                      onTap: onAnalyzeMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.phone_rounded,
                      title: compact ? 'Calls' : 'Call\nProtection',
                      tag: 'Live Guard',
                      iconColor: const Color(0xFF2563EB), // Royal Blue
                      bgTint: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFDBEAFE),
                      onTap: onCallProtection,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.image_rounded,
                      title: compact ? 'Image/Doc' : 'Image &\nDocument',
                      tag: 'QR & PDF',
                      iconColor: const Color(0xFF0D9488), // Emerald Teal
                      bgTint: isDark
                          ? const Color(0xFF042F2E)
                          : const Color(0xFFCCFBF1),
                      onTap: onImageDocument,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.mic_rounded,
                      title: compact ? 'Audio' : 'Analyze\nAudio',
                      tag: 'Voice AI',
                      iconColor: const Color(0xFF8B5CF6), // Purple
                      bgTint: isDark
                          ? const Color(0xFF2E1065)
                          : const Color(0xFFEDE9FE),
                      onTap: onAnalyzeAudio,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.title,
    required this.tag,
    required this.iconColor,
    required this.bgTint,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String tag;
  final Color iconColor;
  final Color bgTint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? AppColors.textMainDark : AppColors.textMainLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111D27) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: iconColor.withValues(alpha: isDark ? 0.35 : 0.22),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: isDark ? 0.15 : 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Badge with Glowing Border
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgTint,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconColor.withValues(alpha: isDark ? 0.45 : 0.3),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Icon(icon, size: 20, color: iconColor),
                ),
              ),
              const SizedBox(height: 8),

              // Title (Exact string for test assertions)
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),

              // Helper tag
              Text(
                tag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
