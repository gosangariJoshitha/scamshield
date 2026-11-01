import 'package:flutter/material.dart';
import '../../../models/analysis_record.dart';

class ResultBannerCard extends StatelessWidget {
  const ResultBannerCard({
    required this.analysis,
    super.key,
  });

  final AnalysisRecord analysis;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final classification = analysis.classification.trim().toUpperCase();
    final riskLevel = analysis.riskLevel.trim().toUpperCase();

    final isSafe = classification == 'SAFE' ||
        classification == 'GENUINE' ||
        (riskLevel == 'LOW' && classification != 'SCAM');
    final isScam = classification == 'SCAM' ||
        riskLevel == 'HIGH' ||
        riskLevel == 'CRITICAL';
    final isSuspicious = !isSafe && !isScam && (classification == 'SUSPICIOUS' || riskLevel == 'MEDIUM');

    final Color bannerBg;
    final Color bannerBorder;
    final Color accentColor;
    final String headline;
    final String subtitle;
    final IconData shieldIcon;

    if (isSafe) {
      bannerBg = isDark ? const Color(0xFF0B241B) : const Color(0xFFF0FDF4);
      bannerBorder = isDark
          ? const Color(0xFF10B981).withValues(alpha: 0.35)
          : const Color(0xFF86EFAC).withValues(alpha: 0.6);
      accentColor = isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
      headline = 'Safe';
      subtitle = 'No known scam indicators were detected.';
      shieldIcon = Icons.check_rounded;
    } else if (isScam) {
      bannerBg = isDark ? const Color(0xFF2A1216) : const Color(0xFFFEF2F2);
      bannerBorder = isDark
          ? const Color(0xFFEF4444).withValues(alpha: 0.35)
          : const Color(0xFFFECACA).withValues(alpha: 0.8);
      accentColor = isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
      headline = 'Scam Detected';
      subtitle = 'This message shows multiple scam indicators.';
      shieldIcon = Icons.priority_high_rounded;
    } else if (isSuspicious) {
      bannerBg = isDark ? const Color(0xFF2A1F0D) : const Color(0xFFFFFBEB);
      bannerBorder = isDark
          ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
          : const Color(0xFFFDE68A).withValues(alpha: 0.8);
      accentColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
      headline = 'Caution Advised';
      subtitle = 'Suspicious elements detected. Proceed with caution.';
      shieldIcon = Icons.warning_amber_rounded;
    } else {
      bannerBg = isDark ? const Color(0xFF192630) : const Color(0xFFF1F5F9);
      bannerBorder = isDark
          ? const Color(0xFF334155).withValues(alpha: 0.5)
          : const Color(0xFFCBD5E1);
      accentColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
      headline = 'Inconclusive Result';
      subtitle = 'Insufficient indicators found to verify authenticity.';
      shieldIcon = Icons.help_outline_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bannerBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.12 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Polished Circular Status Icon Badge
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withValues(alpha: isDark ? 0.4 : 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    shieldIcon,
                    color: Colors.white,
                    size: isSafe ? 34 : 30,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Primary Outcome Headline
          Text(
            headline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: accentColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),

          // Grounded Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
