import 'package:flutter/material.dart';
import '../../../models/analysis_record.dart';
import '../../../theme/app_colors.dart';

class ResultSummaryCard extends StatelessWidget {
  const ResultSummaryCard({
    required this.analysis,
    super.key,
  });

  final AnalysisRecord analysis;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headlineColor = isDark ? Colors.white : AppColors.navy;
    final bodyColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);

    final rawExplanation = analysis.explanation?.trim();
    final isSafe = analysis.riskLevel.trim().toUpperCase() == 'LOW' ||
        analysis.classification.trim().toUpperCase() == 'SAFE' ||
        analysis.classification.trim().toUpperCase() == 'GENUINE';

    final paragraphs = _splitIntoParagraphs(rawExplanation, isSafe);

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
            'Summary',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: headlineColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          ...paragraphs.asMap().entries.map((entry) {
            final idx = entry.key;
            final para = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: idx == paragraphs.length - 1 ? 0 : 8),
              child: Text(
                para,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.8,
                  fontWeight: FontWeight.w400,
                  color: bodyColor,
                  height: 1.48,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  static List<String> _splitIntoParagraphs(String? raw, bool isSafe) {
    if (raw == null || raw.isEmpty) {
      return [
        isSafe
            ? 'No known scam patterns or suspicious elements were identified in this message.'
            : 'Suspicious elements were detected during analysis. Please proceed with caution.',
      ];
    }

    // If explicit newlines are present, split on them
    if (raw.contains('\n\n')) {
      final list = raw
          .split(RegExp(r'\n\s*\n'))
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      if (list.isNotEmpty) return list;
    } else if (raw.contains('\n')) {
      final list = raw
          .split('\n')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      if (list.isNotEmpty) return list;
    }

    // If it's a long continuous string (> 180 chars), break at natural sentence ends
    if (raw.length > 180) {
      final sentencePattern = RegExp(r'(?<=[.!?])\s+(?=[A-Z0-9])');
      final sentences = raw.split(sentencePattern);
      if (sentences.length >= 3) {
        final paragraphs = <String>[];
        final current = StringBuffer();
        int sentenceCount = 0;
        for (final s in sentences) {
          if (current.isNotEmpty) current.write(' ');
          current.write(s);
          sentenceCount++;
          if (sentenceCount >= 2 || current.length > 130) {
            paragraphs.add(current.toString());
            current.clear();
            sentenceCount = 0;
          }
        }
        if (current.isNotEmpty) {
          paragraphs.add(current.toString());
        }
        return paragraphs;
      }
    }

    return [raw];
  }
}
