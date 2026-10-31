import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Item descriptor for capability shortcuts with custom accent palettes.
class _CapabilityItem {
  const _CapabilityItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.lightBg,
    required this.darkBg,
    required this.lightIconBg,
    required this.darkIconBg,
    required this.lightBorder,
    required this.darkBorder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color lightBg;
  final Color darkBg;
  final Color lightIconBg;
  final Color darkIconBg;
  final Color lightBorder;
  final Color darkBorder;
}

/// Supported analysis input types displayed as colorful capability shortcuts
/// matching Section D of the approved design blueprint (1000261210.png).
class CapabilityShortcuts extends StatelessWidget {
  const CapabilityShortcuts({
    required this.onCapabilitySelected,
    super.key,
  });

  final ValueChanged<String> onCapabilitySelected;

  static const List<_CapabilityItem> _items = [
    _CapabilityItem(
      title: 'Messages',
      subtitle: 'AI Analysis',
      icon: Icons.chat_bubble_outline_rounded,
      accentColor: Color(0xFF0284C7), // Sky/Cyan
      lightBg: Color(0xFFF0F9FF),
      darkBg: Color(0xFF082F49),
      lightIconBg: Color(0xFFE0F2FE),
      darkIconBg: Color(0xFF0C4A6E),
      lightBorder: Color(0xFFBAE6FD),
      darkBorder: Color(0xFF0369A1),
    ),
    _CapabilityItem(
      title: 'Calls',
      subtitle: 'Sentinel AI',
      icon: Icons.phone_outlined,
      accentColor: Color(0xFF2563EB), // Vibrant Blue
      lightBg: Color(0xFFEFF6FF),
      darkBg: Color(0xFF1E293B),
      lightIconBg: Color(0xFFDBEAFE),
      darkIconBg: Color(0xFF1E3A8A),
      lightBorder: Color(0xFFBFDBFE),
      darkBorder: Color(0xFF1D4ED8),
    ),
    _CapabilityItem(
      title: 'Images',
      subtitle: 'Visual AI',
      icon: Icons.image_outlined,
      accentColor: Color(0xFF0D9488), // Emerald Teal
      lightBg: Color(0xFFF0FDFA),
      darkBg: Color(0xFF042F2E),
      lightIconBg: Color(0xFFCCFBF1),
      darkIconBg: Color(0xFF134E4A),
      lightBorder: Color(0xFF99F6E4),
      darkBorder: Color(0xFF0F766E),
    ),
    _CapabilityItem(
      title: 'PDF & Docs',
      subtitle: 'Deep Scan',
      icon: Icons.description_outlined,
      accentColor: Color(0xFF6366F1), // Indigo/Violet
      lightBg: Color(0xFFEEF2FF),
      darkBg: Color(0xFF1E1B4B),
      lightIconBg: Color(0xFFE0E7FF),
      darkIconBg: Color(0xFF312E81),
      lightBorder: Color(0xFFC7D2FE),
      darkBorder: Color(0xFF4338CA),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? AppColors.textMainDark : AppColors.textMainLight;
    final subtitleColor =
        isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;

        return Row(
          children: _items.map((item) {
            final cardBg = isDark ? item.darkBg : item.lightBg;
            final iconBg = isDark ? item.darkIconBg : item.lightIconBg;
            final borderColor = isDark ? item.darkBorder : item.lightBorder;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => onCapabilitySelected(item.title),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: compact ? 10 : 12,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: borderColor.withValues(alpha: isDark ? 0.45 : 0.6),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: item.accentColor.withValues(
                            alpha: isDark ? 0.12 : 0.06,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: compact ? 36 : 42,
                          height: compact ? 36 : 42,
                          decoration: BoxDecoration(
                            color: iconBg,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: item.accentColor.withValues(
                                alpha: isDark ? 0.4 : 0.25,
                              ),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: item.accentColor.withValues(
                                  alpha: isDark ? 0.25 : 0.15,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            item.icon,
                            size: compact ? 19 : 22,
                            color: item.accentColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: compact ? 11.5 : 12.5,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
