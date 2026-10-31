import 'package:flutter/material.dart';

class FinalReportBanner extends StatelessWidget {
  const FinalReportBanner({
    required this.classification,
    required this.riskLevel,
    this.subtitle,
    super.key,
  });

  final String classification;
  final String riskLevel;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final upperClass = classification.toUpperCase();
    final upperRisk = riskLevel.toUpperCase();

    final isScam = upperClass == 'SCAM' || upperRisk == 'HIGH' || upperRisk == 'CRITICAL';
    final isSafe = upperClass == 'SAFE' || upperClass == 'GENUINE' || (upperRisk == 'LOW' && !isScam);

    final Color bannerBg;
    final Color bannerBorder;
    final Color accentColor;
    final String headline;
    final String riskBadgeText;
    final String defaultSubtitle;
    final IconData shieldIcon;

    if (isScam) {
      bannerBg = isDark ? const Color(0xFF2A1216) : const Color(0xFFFEF2F2);
      bannerBorder = isDark ? const Color(0xFFEF4444).withValues(alpha: 0.35) : const Color(0xFFFECACA);
      accentColor = isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
      headline = 'Scam Call Detected';
      riskBadgeText = upperRisk == 'CRITICAL' ? 'Critical Risk' : 'High Risk';
      defaultSubtitle = 'This call contains multiple scam indicators and may be a fraudulent attempt.';
      shieldIcon = Icons.priority_high_rounded;
    } else if (isSafe) {
      bannerBg = isDark ? const Color(0xFF0B241B) : const Color(0xFFF0FDF4);
      bannerBorder = isDark ? const Color(0xFF10B981).withValues(alpha: 0.35) : const Color(0xFF86EFAC);
      accentColor = isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
      headline = 'Safe Call';
      riskBadgeText = 'Low Risk';
      defaultSubtitle = 'No known scam indicators were detected during this call.';
      shieldIcon = Icons.check_rounded;
    } else {
      bannerBg = isDark ? const Color(0xFF2A1F0D) : const Color(0xFFFFFBEB);
      bannerBorder = isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.35) : const Color(0xFFFDE68A);
      accentColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
      headline = 'Caution Advised';
      riskBadgeText = 'Medium Risk';
      defaultSubtitle = 'Suspicious elements were detected. Verify caller identity independently.';
      shieldIcon = Icons.warning_amber_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bannerBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Glowing shield badge with sparkles
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          shieldIcon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          headline,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            riskBadgeText,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle ?? defaultSubtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
