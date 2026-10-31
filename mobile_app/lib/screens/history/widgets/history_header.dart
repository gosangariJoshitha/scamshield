import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class HistoryHeader extends StatelessWidget {
  const HistoryHeader({
    required this.isCallTab,
    super.key,
  });

  final bool isCallTab;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headlineColor = isDark ? Colors.white : AppColors.navy;
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cyanNeon = const Color(0xFF00E5FF);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title & Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'History',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: headlineColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isCallTab
                    ? 'View and manage your past call checks.'
                    : 'View and manage your past analyses.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: subtitleColor,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),

        // Radiant Neon Clock Badge
        Semantics(
          label: 'History Clock Indicator',
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF0A1926) : const Color(0xFFE0F7FA),
              border: Border.all(
                color: cyanNeon.withValues(alpha: isDark ? 0.6 : 0.8),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: cyanNeon.withValues(alpha: isDark ? 0.35 : 0.2),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cyanNeon.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.access_time_rounded,
                    size: 20,
                    color: cyanNeon,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
