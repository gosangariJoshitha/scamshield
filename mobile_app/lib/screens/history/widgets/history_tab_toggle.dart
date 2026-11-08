import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Segmented tab toggle switching between Analysis History and Call History.
/// Conforms to ScamShield 2.0 design tokens with consistent dimensions,
/// brand primary teal active state, and high-contrast theme typography.
class HistoryTabToggle extends StatelessWidget {
  const HistoryTabToggle({
    required this.isCallTab,
    required this.onChanged,
    super.key,
  });

  final bool isCallTab;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? const Color(0xFF132029) : const Color(0xFFE8EEF3);
    final activeBg = isDark ? AppColors.darkPrimary : AppColors.primary;
    final activeTextColor = isDark ? const Color(0xFF101820) : Colors.white;
    final inactiveTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // 1. Analysis History Tab
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: isCallTab ? () => onChanged(false) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: !isCallTab ? activeBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: !isCallTab
                        ? [
                            BoxShadow(
                              color: activeBg.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.manage_search_rounded,
                        size: 17,
                        color: !isCallTab ? activeTextColor : inactiveTextColor,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Analysis History',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            fontWeight: !isCallTab ? FontWeight.w700 : FontWeight.w600,
                            color: !isCallTab ? activeTextColor : inactiveTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Call History Tab
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: !isCallTab ? () => onChanged(true) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCallTab ? activeBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isCallTab
                        ? [
                            BoxShadow(
                              color: activeBg.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.phone_in_talk_rounded,
                        size: 17,
                        color: isCallTab ? activeTextColor : inactiveTextColor,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Call History',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            fontWeight: isCallTab ? FontWeight.w700 : FontWeight.w600,
                            color: isCallTab ? activeTextColor : inactiveTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
