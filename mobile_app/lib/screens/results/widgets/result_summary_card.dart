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

    final explanation = analysis.explanation?.trim();
    final hasRealExplanation = explanation != null && explanation.isNotEmpty;

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
          const SizedBox(height: 8),
          Text(
            hasRealExplanation
                ? explanation
                : 'No specific explanation was returned by the analysis pipeline for this content.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: bodyColor,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
