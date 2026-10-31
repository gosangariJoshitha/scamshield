import 'package:flutter/material.dart';
import '../../../models/analysis_record.dart';
import '../../../theme/app_colors.dart';

class ResultBottomActions extends StatelessWidget {
  const ResultBottomActions({
    required this.analysis,
    this.onAnalyzeAnother,
    this.onOpenHistory,
    super.key,
  });

  final AnalysisRecord analysis;
  final VoidCallback? onAnalyzeAnother;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;

        final analyzeButton = OutlinedButton.icon(
          onPressed: onAnalyzeAnother ?? () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.sync_rounded, size: 18, color: primaryColor),
          label: Text(
            'Analyze Another',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            side: BorderSide(color: primaryColor.withValues(alpha: 0.8), width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        final saveToHistoryButton = OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  analysis.id > 0
                      ? 'Analysis #${analysis.id} is securely stored in your History.'
                      : 'Analysis record is preserved.',
                  style: const TextStyle(fontFamily: 'Inter'),
                ),
                behavior: SnackBarBehavior.floating,
                action: onOpenHistory != null
                    ? SnackBarAction(
                        label: 'View',
                        textColor: primaryColor,
                        onPressed: onOpenHistory!,
                      )
                    : null,
              ),
            );
          },
          icon: Icon(Icons.bookmark_border_rounded, size: 18, color: primaryColor),
          label: Text(
            'Save to History',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            side: BorderSide(color: primaryColor.withValues(alpha: 0.8), width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              analyzeButton,
              const SizedBox(height: 10),
              saveToHistoryButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: analyzeButton),
            const SizedBox(width: 12),
            Expanded(child: saveToHistoryButton),
          ],
        );
      },
    );
  }
}
