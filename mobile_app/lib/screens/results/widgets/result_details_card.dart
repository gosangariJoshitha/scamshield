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
    final isSafe = riskLevel == 'LOW' ||
        analysis.classification.toUpperCase() == 'SAFE' ||
        analysis.classification.toUpperCase() == 'GENUINE';

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

    // Confidence: Only display reasoning confidence if legitimately provided by backend
    final double? confidenceValue = analysis.llmConfidence;
    final String? confidenceText = confidenceValue != null
        ? '${(confidenceValue * 100).round()}%'
        : null;

    // Links assessment
    final hasSuspiciousLink = analysis.indicators.any(
          (ind) => ind.toLowerCase().contains('link') || ind.toLowerCase().contains('url'),
        ) ||
        analysis.retrievedEvidence.any(
          (ev) => ev.pattern.toLowerCase().contains('link') || ev.pattern.toLowerCase().contains('url'),
        );
    final String linksDisplay = hasSuspiciousLink
        ? '1 Suspicious Link'
        : (isSafe ? '0' : 'None detected');

    // Pattern display
    final String patternDisplay = isSafe
        ? 'Normal / Legitimate'
        : _formatCategory(analysis.category);

    // Why Flagged / Why Not Flagged
    final bool isFlagged = !isSafe && (analysis.classification.toUpperCase() == 'SCAM' || riskLevel != 'LOW');
    final String flagLabel = isFlagged ? 'Why Flagged' : 'Why Not Flagged';
    final String flagExplanation = isFlagged
        ? _conciseFlagReason(analysis)
        : 'No known scam patterns or suspicious elements detected.';

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
          Divider(color: dividerColor, height: 18, thickness: 0.8),

          // Row 2: Risk Level & Assessed Score
          _DetailRow(
            label: 'Risk Level',
            labelColor: labelColor,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
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
                if (analysis.riskScore > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    ' (Score: ${analysis.riskScore}/100)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: labelColor,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Row 3: Confidence (only displayed when model provides genuine confidence)
          if (confidenceText != null) ...[
            Divider(color: dividerColor, height: 18, thickness: 0.8),
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
          Divider(color: dividerColor, height: 18, thickness: 0.8),
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

          // Row 5: Scam Indicators (Clean individual chips)
          Divider(color: dividerColor, height: 18, thickness: 0.8),
          _DetailRow(
            label: 'Scam Indicators',
            labelColor: labelColor,
            child: analysis.indicators.isEmpty
                ? Text(
                    'None detected',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: labelColor,
                    ),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.end,
                    children: analysis.indicators
                        .map(
                          (indicator) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF3B1519) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                                    : const Color(0xFFFCA5A5),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              indicator,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),

          // Row 6: Message Pattern
          Divider(color: dividerColor, height: 18, thickness: 0.8),
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

          // Row 7: Why Flagged / Why Not Flagged (concise, avoids repeating summary)
          Divider(color: dividerColor, height: 18, thickness: 0.8),
          _DetailRow(
            label: flagLabel,
            labelColor: labelColor,
            child: Text(
              flagExplanation,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: valueColor,
                height: 1.35,
              ),
            ),
          ),

          // Row 8: Timestamp
          Divider(color: dividerColor, height: 18, thickness: 0.8),
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

  static String _conciseFlagReason(AnalysisRecord analysis) {
    if (analysis.indicators.isNotEmpty) {
      return 'Flagged for: ${analysis.indicators.join(', ')}';
    }
    if (analysis.category.isNotEmpty && analysis.category.toLowerCase() != 'general') {
      return 'Pattern matches ${_formatCategory(analysis.category)}';
    }
    final exp = analysis.explanation?.trim();
    if (exp != null && exp.isNotEmpty) {
      final periodIdx = exp.indexOf('.');
      if (periodIdx > 0 && periodIdx < 95) {
        return exp.substring(0, periodIdx + 1);
      }
      if (exp.length > 90) {
        return '${exp.substring(0, 87)}...';
      }
      return exp;
    }
    return 'Suspicious request patterns identified.';
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
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
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  width: constraints.maxWidth,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: child,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
