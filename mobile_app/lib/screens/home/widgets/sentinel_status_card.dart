import 'package:flutter/material.dart';

import '../../../native/call_bridge.dart';
import '../../../theme/app_colors.dart';

/// Sentinel Protection Status card matching Section C of the approved
/// ScamShield 2.0 Home Dashboard blueprint (home and analysis page.jpeg).
///
/// Elevated with vibrant colors, live status indicator, and clear
/// technical specifications of the active privacy and threat defenses.
class SentinelStatusCard extends StatelessWidget {
  const SentinelStatusCard({
    required this.status,
    required this.onOpenSentinel,
    super.key,
  });

  final CallGuardianStatus? status;
  final VoidCallback onOpenSentinel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF192630) : Colors.white;
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final isCallActive =
        status?.callState == 'ACTIVE' || status?.callState == 'RINGING';
    final isProtected =
        status?.enabled == true && status?.serviceRunning == true;
    final isUnavailable = status == null || !status!.available;

    final String heading;
    final String description;
    final Color accentColor;
    final Color badgeBg;
    final IconData icon;
    final String statusPill;

    if (isCallActive) {
      heading = 'Call in progress';
      description = 'Live Call Sentinel is monitoring this call.';
      accentColor = const Color(0xFF2563EB); // Vibrant Blue
      badgeBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF);
      icon = Icons.phone_in_talk_rounded;
      statusPill = '● SCANNING CALL';
    } else if (isUnavailable) {
      heading = 'Status unavailable';
      description = 'Could not verify Sentinel status on this device.';
      accentColor = const Color(0xFF64748B); // Slate
      badgeBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
      icon = Icons.shield_outlined;
      statusPill = 'OFFLINE';
    } else if (isProtected) {
      heading = "You're Protected";
      description = 'AI protection is active. Keep checking suspicious content.';
      accentColor = const Color(0xFF10B981); // Emerald Green
      badgeBg = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
      icon = Icons.shield_rounded;
      statusPill = '● 24/7 CALL SHIELD';
    } else {
      heading = 'Protection is off';
      description = 'Open Sentinel to review your protection settings.';
      accentColor = const Color(0xFFF59E0B); // Amber
      badgeBg = isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
      icon = Icons.shield_outlined;
      statusPill = '⚠️ INACTIVE';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenSentinel,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accentColor.withValues(alpha: isDark ? 0.45 : 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Row
              Row(
                children: [
                  // Circular Shield Badge with Glow
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: badgeBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: isDark ? 0.3 : 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 26,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title and Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                heading,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusPill,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: accentColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: subtitleColor,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Right Navigation Chevron
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Technical Privacy Specification Chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _SpecChip(
                    icon: Icons.lock_outline_rounded,
                    label: 'No Audio Recorded',
                    color: accentColor,
                    isDark: isDark,
                  ),
                  _SpecChip(
                    icon: Icons.radar_rounded,
                    label: 'Unknown Call Radar',
                    color: accentColor,
                    isDark: isDark,
                  ),
                  _SpecChip(
                    icon: Icons.bolt_rounded,
                    label: 'On-Device Heuristics',
                    color: accentColor,
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  const _SpecChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.18),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
