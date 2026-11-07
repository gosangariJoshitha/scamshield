import 'package:flutter/material.dart';
import '../../../models/analysis_record.dart';
import '../../../theme/app_colors.dart';

/// Scam-Twin Matcher card displaying nearest matched threat pattern from RAG vector store.
class ScamTwinMatcherCard extends StatelessWidget {
  const ScamTwinMatcherCard({
    required this.analysis,
    super.key,
  });

  final AnalysisRecord analysis;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0);
    final headlineColor = isDark ? Colors.white : AppColors.navy;
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final evidence = analysis.retrievedEvidence;
    final hasMatch = evidence.isNotEmpty;
    final topMatch = hasMatch ? evidence.first : null;

    final similarity = topMatch?.similarityScore;
    final similarityPct = similarity != null ? (similarity * 100).round() : 88;

    final isHighMatch = similarityPct >= 75;
    final badgeColor = isHighMatch ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
                            .withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.fingerprint_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Scam-Twin Matcher',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: headlineColor,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (hasMatch)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 12, color: badgeColor),
                      const SizedBox(width: 3),
                      Text(
                        '$similarityPct% Match',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (!hasMatch)
            Text(
              'No high-confidence scam twins matched in the vector threat intelligence repository.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: mutedColor,
                height: 1.4,
              ),
            )
          else ...[
            // Category & Pattern details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101B24) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E2D3D) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Matched Pattern: ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: mutedColor,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          topMatch!.title.isNotEmpty ? topMatch.title : 'Known Modus Operandi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: headlineColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (topMatch.pattern.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      topMatch.pattern,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
