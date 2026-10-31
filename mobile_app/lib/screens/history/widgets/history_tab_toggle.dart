import 'package:flutter/material.dart';

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
    final containerBg = isDark ? const Color(0xFF131F2A) : const Color(0xFFE2E8F0);
    final activeBg = const Color(0xFF0284C7);
    final activeTextColor = Colors.white;
    final inactiveTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF243447) : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 1. Analysis History Tab
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: isCallTab ? () => onChanged(false) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: !isCallTab ? activeBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
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
              ),
            ),
          ),

          // 2. Call History Tab
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: !isCallTab ? () => onChanged(true) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCallTab ? activeBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
