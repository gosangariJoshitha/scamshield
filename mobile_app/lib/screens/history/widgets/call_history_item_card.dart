import 'package:flutter/material.dart';
import '../../../models/call_history_models.dart';

class CallHistoryItemCard extends StatelessWidget {
  const CallHistoryItemCard({
    required this.call,
    required this.onTap,
    super.key,
  });

  final CallHistoryItem call;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF131F2A) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final isUnavailable = call.analysisStatus == 'AUDIO_UNAVAILABLE' ||
        call.analysisStatus == 'ANALYSIS_UNAVAILABLE' ||
        call.audioStatus == 'AUDIO_UNAVAILABLE' ||
        call.analysisStatus == 'INCOMPLETE';

    final riskLevel = call.finalRiskLevel.trim().toUpperCase();
    final classification = call.classification.trim().toUpperCase();

    final isScam = !isUnavailable && (classification == 'SCAM' || riskLevel == 'HIGH' || riskLevel == 'CRITICAL');
    final isSafe = !isUnavailable && (classification == 'SAFE' || classification == 'GENUINE' || riskLevel == 'LOW');

    // Risk badge styling
    final Color badgeBg;
    final Color badgeBorder;
    final Color badgeText;
    final String badgeLabel;

    if (isUnavailable) {
      badgeBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
      badgeBorder = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
      badgeText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
      badgeLabel = 'Unknown';
    } else if (isScam) {
      badgeBg = isDark ? const Color(0xFF2A1216) : const Color(0xFFFEF2F2);
      badgeBorder = isDark ? const Color(0xFFEF4444).withValues(alpha: 0.35) : const Color(0xFFFECACA);
      badgeText = const Color(0xFFEF4444);
      badgeLabel = 'Scam';
    } else if (isSafe) {
      badgeBg = isDark ? const Color(0xFF0B241B) : const Color(0xFFF0FDF4);
      badgeBorder = isDark ? const Color(0xFF10B981).withValues(alpha: 0.35) : const Color(0xFFBBF7D0);
      badgeText = const Color(0xFF10B981);
      badgeLabel = 'Safe';
    } else {
      badgeBg = isDark ? const Color(0xFF2A1F0D) : const Color(0xFFFFFBEB);
      badgeBorder = isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.35) : const Color(0xFFFDE68A);
      badgeText = const Color(0xFFF59E0B);
      badgeLabel = 'Suspicious';
    }

    // Phone avatar styling
    final Color avatarBg;
    final Color avatarColor;
    if (isUnavailable) {
      avatarBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
      avatarColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    } else if (isScam) {
      avatarBg = isDark ? const Color(0xFF2A1216) : const Color(0xFFFEE2E2);
      avatarColor = const Color(0xFFEF4444);
    } else if (isSafe) {
      avatarBg = isDark ? const Color(0xFF0B241B) : const Color(0xFFDCFCE7);
      avatarColor = const Color(0xFF10B981);
    } else {
      avatarBg = isDark ? const Color(0xFF2A1F0D) : const Color(0xFFFEF3C7);
      avatarColor = const Color(0xFFF59E0B);
    }

    // Caller display info
    final (String callerTitle, String callerSubtitle) = _resolveCallerInfo(call);
    final timeFormatted = _formatTimeDisplay(call.endedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Phone circle avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: avatarBg,
                  ),
                  child: Center(
                    child: Icon(Icons.call_rounded, color: avatarColor, size: 22),
                  ),
                ),
                const SizedBox(width: 12),

                // Center Column: Caller info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        callerTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        callerSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Trailing Column: Time & Badge & Chevron
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeFormatted,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: badgeBorder, width: 0.8),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: badgeText,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: subtitleColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static (String, String) _resolveCallerInfo(CallHistoryItem call) {
    final category = call.scamCategory.trim();
    final hasCategory = category.isNotEmpty && category.toLowerCase() != 'unknown' && category.toLowerCase() != 'none';

    // Check if category or session holds a caller ID or number
    if (category.startsWith('+') || category.contains(RegExp(r'\d{5}'))) {
      final sub = call.classification.isNotEmpty && call.classification != 'UNKNOWN'
          ? (call.classification == 'SCAM' ? 'Suspected spam call' : 'Protected call')
          : 'Call check';
      return (category, sub);
    }

    if (hasCategory) {
      final title = category;
      final sub = call.finalRiskScore > 0
          ? '${call.finalRiskLevel} Risk (${call.finalRiskScore}/100)'
          : '${call.formattedDuration} call';
      return (title, sub);
    }

    // Default truthful caller identifier
    final sessionPrefix = call.sessionId.length > 8
        ? call.sessionId.substring(0, 8)
        : call.sessionId;
    return ('Unknown Caller', 'Protected session #$sessionPrefix');
  }

  static String _formatTimeDisplay(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();

    final isToday = local.year == now.year && local.month == now.month && local.day == now.day;
    final isYesterday = local.year == now.year &&
        local.month == now.month &&
        local.day == now.subtract(const Duration(days: 1)).day;

    if (isToday) {
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final minute = local.minute.toString().padLeft(2, '0');
      final period = local.hour >= 12 ? 'PM' : 'AM';
      final hourStr = hour.toString().padLeft(2, '0');
      return '$hourStr:$minute $period';
    }
    if (isYesterday) {
      return 'Yesterday';
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${local.day} ${months[local.month - 1]}';
  }
}
