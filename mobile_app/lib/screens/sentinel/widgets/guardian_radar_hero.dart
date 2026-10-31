import 'package:flutter/material.dart';
import '../../../native/call_bridge.dart';
import '../../../theme/app_colors.dart';

class GuardianRadarHero extends StatelessWidget {
  const GuardianRadarHero({
    required this.status,
    this.onTapStatus,
    this.onTapInfo,
    super.key,
  });

  final CallGuardianStatus? status;
  final VoidCallback? onTapStatus;
  final VoidCallback? onTapInfo;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRunning = status?.enabled == true && status?.serviceRunning == true;

    final Color primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF0284C7);
    final Color activeGreen = isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
    final Color inactiveGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Column(
      children: [
        // Title row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Live Call Guardian',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.navy,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 5),
            GestureDetector(
              onTap: onTapInfo,
              child: Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Active / Inactive pill
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: isRunning ? activeGreen : inactiveGray,
                shape: BoxShape.circle,
                boxShadow: isRunning
                    ? [
                        BoxShadow(
                          color: activeGreen.withValues(alpha: 0.6),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isRunning ? 'Active' : 'Inactive',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isRunning ? activeGreen : inactiveGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        Text(
          'AI listens, analyzes and alerts you during calls for suspicious activity.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),

        // Concentric Circles with Center Shield & Soundwave Badge
        SizedBox(
          width: 170,
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ripple circle
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.12),
                    width: 1.5,
                  ),
                ),
              ),
              // Middle ripple circle
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: isDark ? 0.08 : 0.05),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.22),
                    width: 1.5,
                  ),
                ),
              ),
              // Inner glowing badge
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
              ),
              // Soundwave badge at bottom right
              Positioned(
                bottom: 22,
                right: 18,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF192630) : Colors.white,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.graphic_eq_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Status bar button: "• Guardian Service • Running >"
        InkWell(
          onTap: onTapStatus,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF192630) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isRunning ? activeGreen : inactiveGray,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Guardian Service',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.navy,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isRunning ? 'Running' : 'Stopped',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isRunning ? activeGreen : inactiveGray,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
