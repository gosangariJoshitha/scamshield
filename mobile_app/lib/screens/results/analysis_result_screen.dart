import 'package:flutter/material.dart';
import '../../models/analysis_record.dart';
import '../../theme/app_colors.dart';
import 'widgets/multilingual_recommendation_card.dart';
import 'widgets/result_banner_card.dart';
import 'widgets/result_bottom_actions.dart';
import 'widgets/result_details_card.dart';
import 'widgets/result_summary_card.dart';

class AnalysisResultScreen extends StatelessWidget {
  const AnalysisResultScreen({
    required this.analysis,
    this.onBackToDashboard,
    this.onAnalyzeAnother,
    this.onOpenHistory,
    super.key,
  });

  final AnalysisRecord analysis;
  final VoidCallback? onBackToDashboard;
  final VoidCallback? onAnalyzeAnother;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headlineColor = isDark ? Colors.white : AppColors.navy;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: headlineColor,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Analysis Result',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18.5,
            fontWeight: FontWeight.w700,
            color: headlineColor,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Result Banner (Safe / Scam Detected / Suspicious)
                  ResultBannerCard(analysis: analysis),

                  // 2. Partial / Degraded pipeline limitations notice
                  if (analysis.processingStatus == 'COMPLETED_WITH_LIMITATIONS') ...[
                    const SizedBox(height: 12),
                    const _LimitationsNotice(),
                  ],

                  const SizedBox(height: 14),

                  // 3. Genuine Backend Summary
                  ResultSummaryCard(analysis: analysis),

                  const SizedBox(height: 14),

                  // 4. Detailed Breakdown
                  ResultDetailsCard(analysis: analysis),

                  const SizedBox(height: 14),

                  // 5. Multilingual Recommendation (English, Hindi, Telugu)
                  MultilingualRecommendationCard(analysis: analysis),

                  const SizedBox(height: 18),

                  // 6. Bottom Actions: Analyze Another & Save to History
                  ResultBottomActions(
                    analysis: analysis,
                    onAnalyzeAnother: onAnalyzeAnother,
                    onOpenHistory: onOpenHistory,
                  ),

                  const SizedBox(height: 14),

                  // 7. Security Guidance Disclaimer
                  const _DisclaimerCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LimitationsNotice extends StatelessWidget {
  const _LimitationsNotice();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706)).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706)).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Some auxiliary analysis services were temporarily unavailable. The findings above reflect verified outputs from the active pipeline.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 14,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ScamShield analysis is automated safety guidance. Always verify independently through official channels before acting.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
