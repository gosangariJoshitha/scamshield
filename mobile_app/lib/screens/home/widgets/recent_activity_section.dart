import 'package:flutter/material.dart';

import '../../../models/analysis_record.dart';
import '../../../theme/app_colors.dart';

/// "Recent Activity" list section matching Section F of the approved
/// ScamShield 2.0 Home Dashboard blueprint (home and analysis page.jpeg).
class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({
    required this.recentAnalyses,
    required this.onViewAll,
    required this.onOpenRecord,
    required this.onAnalyzeFirst,
    this.loading = false,
    super.key,
  });

  final List<AnalysisRecord> recentAnalyses;
  final VoidCallback onViewAll;
  final ValueChanged<AnalysisRecord> onOpenRecord;
  final VoidCallback onAnalyzeFirst;
  final bool loading;

  static String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? "min" : "mins"} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? "hour" : "hours"} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? "day" : "days"} ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  static ({String title, IconData icon, Color color, Color bgTint, String riskText})
      _deriveRecordMeta(AnalysisRecord record, bool isDark) {
    final riskLevel = record.riskLevel.toUpperCase();
    final classification = record.classification.toUpperCase();
    final isScam = classification == 'SCAM' || riskLevel == 'HIGH' || record.riskScore >= 70;
    final isSafe = classification == 'SAFE' || riskLevel == 'LOW';

    final String title = switch (record.inputType.toLowerCase()) {
      'call' => 'Call Checked',
      'image' => 'Image Scanned',
      'document' || 'pdf' => 'Document Analyzed',
      'audio' => 'Audio Analyzed',
      _ => 'Message Analyzed',
    };

    final IconData icon = switch (record.inputType.toLowerCase()) {
      'call' => isScam ? Icons.phone_missed_rounded : Icons.phone_rounded,
      'image' => isScam ? Icons.broken_image_rounded : Icons.image_rounded,
      'document' || 'pdf' => isScam ? Icons.dangerous_outlined : Icons.description_rounded,
      _ => isScam ? Icons.error_outline_rounded : Icons.chat_bubble_rounded,
    };

    if (isScam) {
      return (
        title: title,
        icon: icon,
        color: const Color(0xFFEF4444), // Red
        bgTint: isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2),
        riskText: 'Scam detected',
      );
    } else if (isSafe) {
      return (
        title: title,
        icon: icon,
        color: const Color(0xFF10B981), // Green
        bgTint: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
        riskText: 'Safe',
      );
    } else {
      return (
        title: title,
        icon: icon,
        color: const Color(0xFFF59E0B), // Amber
        bgTint: isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
        riskText: 'Suspicious',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF192630) : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
    final headlineColor =
        isDark ? AppColors.textMainDark : AppColors.textMainLight;
    final accentColor =
        isDark ? AppColors.darkPrimary : const Color(0xFF0891B2);
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Recent Activity',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: headlineColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              InkWell(
                onTap: onViewAll,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Content
          if (recentAnalyses.isEmpty)
            // Empty State
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        size: 24,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No activity yet',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: headlineColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Your completed analyses will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton.icon(
                      onPressed: onAnalyzeFirst,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Analyze Content'),
                      style: TextButton.styleFrom(
                        foregroundColor: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Records List (up to 4 items)
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: recentAnalyses.take(4).length,
              separatorBuilder: (context, index) => Divider(
                color: borderColor.withValues(alpha: 0.7),
                height: 18,
                thickness: 0.8,
              ),
              itemBuilder: (context, index) {
                final record = recentAnalyses[index];
                final meta = _deriveRecordMeta(record, isDark);

                return InkWell(
                  onTap: () => onOpenRecord(record),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        // Colored Type Badge
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: meta.bgTint,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: meta.color.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Icon(meta.icon, size: 19, color: meta.color),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Subtitle with Risk label and Timestamp
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meta.title,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: headlineColor,
                                ),
                              ),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: meta.riskText,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: meta.color,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' • ${_formatTime(record.createdAt)}',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: subtitleColor,
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Chevron Navigation
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: subtitleColor,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
