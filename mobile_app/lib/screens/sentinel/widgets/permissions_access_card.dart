import 'package:flutter/material.dart';
import '../../../native/call_bridge.dart';
import '../../../theme/app_colors.dart';

class PermissionsAccessCard extends StatelessWidget {
  const PermissionsAccessCard({
    required this.status,
    required this.audioCapability,
    this.onRequestMicrophone,
    this.onRequestPhone,
    this.onRequestOverlay,
    this.onRequestAccessibility,
    super.key,
  });

  final CallGuardianStatus? status;
  final AudioCapability? audioCapability;
  final VoidCallback? onRequestMicrophone;
  final VoidCallback? onRequestPhone;
  final VoidCallback? onRequestOverlay;
  final VoidCallback? onRequestAccessibility;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0);

    final phoneGranted = status?.phoneStatePermissionGranted == true;
    final micGranted = status?.audioPermissionGranted == true;
    final overlayGranted = status?.callScreeningEnabled == true; // or overlay capability
    final accessibilityGranted = status?.serviceRunning == true;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 19,
                color: isDark ? AppColors.darkPrimary : const Color(0xFF0284C7),
              ),
              const SizedBox(width: 8),
              Text(
                'Permissions & Access',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.navy,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Microphone
          _PermissionRow(
            icon: Icons.mic_none_rounded,
            title: 'Microphone',
            isAllowed: micGranted,
            onTap: onRequestMicrophone,
          ),
          Divider(color: isDark ? const Color(0xFF243447) : const Color(0xFFF1F5F9), height: 16),

          // 2. Phone Access
          _PermissionRow(
            icon: Icons.phone_outlined,
            title: 'Phone Access',
            isAllowed: phoneGranted,
            onTap: onRequestPhone,
          ),
          Divider(color: isDark ? const Color(0xFF243447) : const Color(0xFFF1F5F9), height: 16),

          // 3. Draw over other apps (for floating button)
          _PermissionRow(
            icon: Icons.dashboard_customize_outlined,
            title: 'Draw over other apps\n(for floating button)',
            isAllowed: overlayGranted,
            onTap: onRequestOverlay,
          ),
          Divider(color: isDark ? const Color(0xFF243447) : const Color(0xFFF1F5F9), height: 16),

          // 4. Accessibility / Call Screening
          _PermissionRow(
            icon: Icons.settings_accessibility_rounded,
            title: 'Accessibility (Required)',
            isAllowed: accessibilityGranted,
            onTap: onRequestAccessibility,
          ),
          const SizedBox(height: 14),

          // Floating button notice banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.3 : 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFF0284C7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Floating Guardian button will appear when protection is active. You can move it anywhere on the screen.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFBAE6FD) : const Color(0xFF0369A1),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.isAllowed,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final bool isAllowed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greenColor = isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
    final orangeColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.navy,
                  height: 1.25,
                ),
              ),
            ),
            Text(
              isAllowed ? 'Allowed' : 'Required',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isAllowed ? greenColor : orangeColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: isAllowed ? greenColor : orangeColor,
            ),
          ],
        ),
      ),
    );
  }
}
