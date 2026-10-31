import 'package:flutter/material.dart';
import '../../../native/call_bridge.dart';
import '../../../theme/app_colors.dart';

class SentinelHeroCard extends StatelessWidget {
  const SentinelHeroCard({
    required this.status,
    required this.onToggle,
    required this.onTapDetails,
    super.key,
  });

  final CallGuardianStatus? status;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTapDetails;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRunning = status?.enabled == true && status?.serviceRunning == true;
    final isEnabled = status?.enabled == true;

    final Color cardBg = isDark ? AppColors.darkCard : Colors.white;
    final Color borderColor = isDark
        ? (isRunning ? const Color(0xFF0284C7).withValues(alpha: 0.4) : const Color(0xFF243447))
        : (isRunning ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0));

    final String statusText;
    final Color statusColor;
    if (isRunning) {
      statusText = 'Guardian is on · Ready';
      statusColor = isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
    } else if (isEnabled) {
      statusText = 'Starting · Connecting monitoring service';
      statusColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
    } else if (status?.serviceError != null) {
      statusText = 'Attention Needed · Tap to review permissions';
      statusColor = isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
    } else {
      statusText = 'Guardian is off. Call activity is not monitored.';
      statusColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    }

    return InkWell(
      onTap: onTapDetails,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Phone badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.phone_in_talk_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Call Guardian',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.navy,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Detects and warns you about potential scam calls in real-time.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: isEnabled,
                  onChanged: (val) => onToggle(val),
                  activeThumbColor: Colors.white,
                  activeTrackColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                  inactiveThumbColor: isDark ? const Color(0xFF64748B) : Colors.white,
                  inactiveTrackColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: isDark ? const Color(0xFF243447) : const Color(0xFFF1F5F9),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
