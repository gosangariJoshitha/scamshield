import 'package:flutter/material.dart';
import '../../../models/analysis_record.dart';

class AnalysisHistoryItemCard extends StatelessWidget {
  const AnalysisHistoryItemCard({
    required this.analysis,
    required this.onTap,
    super.key,
  });

  final AnalysisRecord analysis;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF131F2A) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final typeLabelColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    // Determine risk classification
    final classification = analysis.classification.trim().toUpperCase();
    final riskLevel = analysis.riskLevel.trim().toUpperCase();

    final isSafe = classification == 'SAFE' ||
        classification == 'GENUINE' ||
        (riskLevel == 'LOW' && classification != 'SCAM');
    final isScam = classification == 'SCAM' ||
        riskLevel == 'HIGH' ||
        riskLevel == 'CRITICAL';
    final isSuspicious = !isSafe && !isScam && (classification == 'SUSPICIOUS' || riskLevel == 'MEDIUM');

    // Risk badge styling
    final Color badgeBg;
    final Color badgeBorder;
    final Color badgeText;
    final String badgeLabel;

    if (isScam) {
      badgeBg = isDark ? const Color(0xFF2A1216) : const Color(0xFFFEF2F2);
      badgeBorder = isDark ? const Color(0xFFEF4444).withValues(alpha: 0.35) : const Color(0xFFFECACA);
      badgeText = const Color(0xFFEF4444);
      badgeLabel = 'Scam';
    } else if (isSafe) {
      badgeBg = isDark ? const Color(0xFF0B241B) : const Color(0xFFF0FDF4);
      badgeBorder = isDark ? const Color(0xFF10B981).withValues(alpha: 0.35) : const Color(0xFFBBF7D0);
      badgeText = const Color(0xFF10B981);
      badgeLabel = 'Safe';
    } else if (isSuspicious) {
      badgeBg = isDark ? const Color(0xFF2A1F0D) : const Color(0xFFFFFBEB);
      badgeBorder = isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.35) : const Color(0xFFFDE68A);
      badgeText = const Color(0xFFF59E0B);
      badgeLabel = 'Suspicious';
    } else {
      badgeBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
      badgeBorder = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
      badgeText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
      badgeLabel = classification.isNotEmpty ? classification : 'Unknown';
    }

    // Avatar Icon and Color
    final (IconData avatarIcon, Color avatarBg, Color avatarColor) = _resolveAvatar(
      analysis: analysis,
      isScam: isScam,
      isSafe: isSafe,
      isSuspicious: isSuspicious,
      isDark: isDark,
    );

    // Title and Preview
    final title = _resolveTitle(analysis);
    final preview = _resolvePreview(analysis);
    final typeLabel = _resolveTypeLabel(analysis);
    final timeFormatted = _formatTimeDisplay(analysis.createdAt);

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
                // Left circular avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: avatarBg,
                  ),
                  child: Center(
                    child: Icon(avatarIcon, color: avatarColor, size: 22),
                  ),
                ),
                const SizedBox(width: 12),

                // Center details (Title, Snippet, Type)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
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
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: typeLabelColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Trailing details (Timestamp & Risk Badge)
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  static (IconData, Color, Color) _resolveAvatar({
    required AnalysisRecord analysis,
    required bool isScam,
    required bool isSafe,
    required bool isSuspicious,
    required bool isDark,
  }) {
    final type = analysis.inputType.toLowerCase();
    if (type == 'image') {
      return (
        Icons.image_outlined,
        isDark ? const Color(0xFF2A1F0D) : const Color(0xFFFEF3C7),
        const Color(0xFFF59E0B),
      );
    }
    if (type == 'pdf') {
      return (
        Icons.description_outlined,
        isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
        const Color(0xFF6366F1),
      );
    }
    if (type == 'audio') {
      return (
        Icons.graphic_eq_rounded,
        isDark ? const Color(0xFF042F2E) : const Color(0xFFCCFBF1),
        const Color(0xFF14B8A6),
      );
    }

    // Check for link
    final isUrl = analysis.content.trim().startsWith('http://') ||
        analysis.content.trim().startsWith('https://') ||
        analysis.indicators.any((i) => i.toLowerCase().contains('link'));
    if (isUrl) {
      return (
        Icons.link_rounded,
        isDark ? const Color(0xFF082F49) : const Color(0xFFE0F2FE),
        const Color(0xFF0284C7),
      );
    }

    if (isScam) {
      return (
        Icons.priority_high_rounded,
        isDark ? const Color(0xFF2A1216) : const Color(0xFFFEE2E2),
        const Color(0xFFEF4444),
      );
    }
    if (isSafe) {
      return (
        Icons.check_rounded,
        isDark ? const Color(0xFF0B241B) : const Color(0xFFDCFCE7),
        const Color(0xFF10B981),
      );
    }
    return (
      Icons.chat_bubble_outline_rounded,
      isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      const Color(0xFF94A3B8),
    );
  }

  static String _resolveTitle(AnalysisRecord analysis) {
    if (analysis.originalFilename != null && analysis.originalFilename!.trim().isNotEmpty) {
      return analysis.originalFilename!.trim();
    }
    final category = analysis.category.trim();
    if (category.isNotEmpty && category.toLowerCase() != 'unknown' && category.toLowerCase() != 'none') {
      final formatted = category
          .replaceAll(RegExp(r'[_-]+'), ' ')
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
          .join(' ');
      return '$formatted message';
    }
    final type = analysis.inputType.toLowerCase();
    return switch (type) {
      'image' => 'Screenshot analysis',
      'pdf' => 'Document analysis',
      'audio' => 'Voice message',
      _ => 'Text analysis',
    };
  }

  static String _resolvePreview(AnalysisRecord analysis) {
    if (analysis.originalFilename != null && analysis.originalFilename!.trim().isNotEmpty) {
      return analysis.originalFilename!.trim();
    }
    final content = analysis.content.trim();
    if (content.isNotEmpty) {
      return content.replaceAll(RegExp(r'[\r\n]+'), ' ');
    }
    return 'Analysis #${analysis.id}';
  }

  static String _resolveTypeLabel(AnalysisRecord analysis) {
    final isUrl = analysis.content.trim().startsWith('http://') ||
        analysis.content.trim().startsWith('https://');
    if (isUrl) return 'Link';
    return switch (analysis.inputType.toLowerCase()) {
      'image' => 'Image',
      'pdf' => 'Document',
      'audio' => 'Audio',
      _ => 'Text',
    };
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
