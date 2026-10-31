import 'package:flutter/material.dart';
import '../../../models/analysis_record.dart';
import '../../../theme/app_colors.dart';

class ResultDetailsCard extends StatelessWidget {
  const ResultDetailsCard({
    required this.analysis,
    super.key,
  });

  final AnalysisRecord analysis;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headlineColor = isDark ? Colors.white : AppColors.navy;
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final valueColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final dividerColor = isDark ? const Color(0xFF243447) : const Color(0xFFF1F5F9);

    final riskLevel = analysis.riskLevel.trim().toUpperCase();
    final isSafe = riskLevel == 'LOW' || analysis.classification.toUpperCase() == 'GENUINE';

    // Risk Color mapping
    final Color riskDotColor = switch (riskLevel) {
      'CRITICAL' => const Color(0xFFDC2626),
      'HIGH' => const Color(0xFFEF4444),
      'MEDIUM' => const Color(0xFFF59E0B),
      'LOW' || 'SAFE' => const Color(0xFF10B981),
      _ => const Color(0xFF64748B),
    };

    final String riskDisplay = switch (riskLevel) {
      'CRITICAL' => 'Critical',
      'HIGH' => 'High',
      'MEDIUM' => 'Medium',
      'LOW' || 'SAFE' => 'Low',
      _ => analysis.riskLevel,
    };

    // Content Type mapping
    final (IconData typeIcon, String typeLabel) = _contentTypeDetails(analysis.inputType);

    // Confidence percentage (truthful only)
    final double? confidenceValue = analysis.llmConfidence ?? analysis.mlProbability;
    final String? confidenceText = confidenceValue != null
        ? '${(confidenceValue * 100).round()}%'
        : (analysis.riskScore > 0 ? '${analysis.riskScore}%' : null);

    // Links assessment
    final hasSuspiciousLink = analysis.indicators.any(
          (ind) => ind.toLowerCase().contains('link') || ind.toLowerCase().contains('url'),
        ) ||
        analysis.retrievedEvidence.any(
          (ev) => ev.pattern.toLowerCase().contains('link') || ev.pattern.toLowerCase().contains('url'),
        );
    final String linksDisplay = hasSuspiciousLink
        ? '1 Suspicious Link'
        : (isSafe ? '0' : 'No suspicious links');

    // Indicators display
    final String indicatorsDisplay = analysis.indicators.isNotEmpty
        ? analysis.indicators.join(', ')
        : 'None detected';

    // Pattern display
    final String patternDisplay = isSafe
        ? 'Normal / Legitimate'
        : _formatCategory(analysis.category);

    // Why Flagged / Why Not Flagged
    final bool isFlagged = !isSafe && (analysis.classification.toUpperCase() == 'SCAM' || riskLevel != 'LOW');
    final String flagLabel = isFlagged ? 'Why Flagged' : 'Why Not Flagged';
    final String flagExplanation = isFlagged
        ? (analysis.explanation?.trim().isNotEmpty == true
            ? analysis.explanation!
            : 'Contains suspicious request patterns or elements common in scams.')
        : 'No known scam patterns or suspicious elements were detected.';

    // Formatted timestamp
    final String timestampText = _formatTimestamp(analysis.createdAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: headlineColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),

          // Row 1: Content Type
          _DetailRow(
            label: 'Content Type',
            labelColor: labelColor,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(typeIcon, size: 14, color: const Color(0xFF0284C7)),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    typeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: valueColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: dividerColor, height: 20, thickness: 1),

          // Row 2: Risk Level
          _DetailRow(
            label: 'Risk Level',
            labelColor: labelColor,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: riskDotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  riskDisplay,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: riskDotColor,
                  ),
                ),
              ],
            ),
          ),

          // Row 3: Confidence (only if available)
          if (confidenceText != null) ...[
            Divider(color: dividerColor, height: 20, thickness: 1),
            _DetailRow(
              label: 'Confidence',
              labelColor: labelColor,
              child: Text(
                confidenceText,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ),
          ],

          // Row 4: Links Detected
          Divider(color: dividerColor, height: 20, thickness: 1),
          _DetailRow(
            label: 'Links Detected',
            labelColor: labelColor,
            child: Text(
              linksDisplay,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: hasSuspiciousLink ? const Color(0xFFEF4444) : valueColor,
              ),
            ),
          ),

          // Row 5: Scam Indicators
          Divider(color: dividerColor, height: 20, thickness: 1),
          _DetailRow(
            label: 'Scam Indicators',
            labelColor: labelColor,
            child: Text(
              indicatorsDisplay,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: analysis.indicators.isNotEmpty
                    ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626))
                    : labelColor,
              ),
            ),
          ),

          // Row 6: Message Pattern
          Divider(color: dividerColor, height: 20, thickness: 1),
          _DetailRow(
            label: 'Message Pattern',
            labelColor: labelColor,
            child: Text(
              patternDisplay,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),

          // Row 7: Why Flagged / Why Not Flagged
          Divider(color: dividerColor, height: 20, thickness: 1),
          _DetailRow(
            label: flagLabel,
            labelColor: labelColor,
            child: Text(
              flagExplanation,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: valueColor,
                height: 1.35,
              ),
            ),
          ),

          // Row 8: Timestamp
          Divider(color: dividerColor, height: 20, thickness: 1),
          _DetailRow(
            label: 'Analysis Time',
            labelColor: labelColor,
            child: Text(
              timestampText,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: labelColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static (IconData, String) _contentTypeDetails(String inputType) {
    return switch (inputType.toLowerCase()) {
      'image' => (Icons.image_outlined, 'Image / Screenshot'),
      'document' || 'pdf' => (Icons.description_outlined, 'Document (PDF)'),
      'audio' => (Icons.mic_none_rounded, 'Audio Recording'),
      'call' => (Icons.phone_in_talk_rounded, 'Phone Call'),
      _ => (Icons.chat_bubble_outline_rounded, 'Text Message'),
    };
  }

  static String _formatCategory(String rawCategory) {
    if (rawCategory.isEmpty) return 'Common scam pattern detected';
    final cleaned = rawCategory.replaceAll('_', ' ').replaceAll('-', ' ');
    return cleaned
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  static String _formatTimestamp(DateTime time) {
    final local = time.toLocal();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[(local.month - 1).clamp(0, 11)];
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$month ${local.day}, ${local.year} • $hour:$minute $period';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.labelColor,
    required this.child,
  });

  final String label;
  final Color labelColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 105),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: child,
          ),
        ),
      ],
    );
  }
}
