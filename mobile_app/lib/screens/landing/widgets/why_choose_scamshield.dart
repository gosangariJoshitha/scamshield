import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/common/scamshield_card.dart';

/// Descriptor for a colorful feature item in the "Why Choose ScamShield?" section.
class _FeatureItem {
  const _FeatureItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.lightBg,
    required this.darkBg,
    required this.lightIconBg,
    required this.darkIconBg,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final Color lightBg;
  final Color darkBg;
  final Color lightIconBg;
  final Color darkIconBg;
}

/// "Why Choose ScamShield?" feature section matching Section E of the
/// approved blueprint (1000261210.png).
///
/// Features colorful individual icons and a dedicated privacy showcase card.
class WhyChooseScamShieldSection extends StatelessWidget {
  const WhyChooseScamShieldSection({super.key});

  static const List<_FeatureItem> _features = [
    _FeatureItem(
      title: 'Message Analysis',
      description: 'Detect suspicious texts, links and phishing attempts.',
      icon: Icons.chat_bubble_outline_rounded,
      accentColor: Color(0xFF0284C7), // Cyan
      lightBg: Color(0xFFF0F9FF),
      darkBg: Color(0xFF082F49),
      lightIconBg: Color(0xFFE0F2FE),
      darkIconBg: Color(0xFF0C4A6E),
    ),
    _FeatureItem(
      title: 'Call Protection (Sentinel)',
      description: 'Identify potential scam calls and stay alerted.',
      icon: Icons.phone_in_talk_outlined,
      accentColor: Color(0xFF2563EB), // Vibrant Blue
      lightBg: Color(0xFFEFF6FF),
      darkBg: Color(0xFF1E293B),
      lightIconBg: Color(0xFFDBEAFE),
      darkIconBg: Color(0xFF1E3A8A),
    ),
    _FeatureItem(
      title: 'Image & Document Scan',
      description: 'Analyze screenshots, PDFs and files for hidden risks.',
      icon: Icons.document_scanner_outlined,
      accentColor: Color(0xFF0D9488), // Emerald Teal
      lightBg: Color(0xFFF0FDFA),
      darkBg: Color(0xFF042F2E),
      lightIconBg: Color(0xFFCCFBF1),
      darkIconBg: Color(0xFF134E4A),
    ),
    _FeatureItem(
      title: 'AI-Powered Insights',
      description: 'Get clear explanations and actionable safety tips.',
      icon: Icons.auto_awesome_outlined,
      accentColor: Color(0xFF7C3AED), // Vivid Purple
      lightBg: Color(0xFFFAF5FF),
      darkBg: Color(0xFF2E1065),
      lightIconBg: Color(0xFFEDE9FE),
      darkIconBg: Color(0xFF3B0764),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headlineColor =
        isDark ? AppColors.textMainDark : AppColors.textMainLight;
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Heading
        Text(
          'Why Choose ScamShield?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: headlineColor,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Smarter insights. Safer decisions. Everyday protection.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: subtitleColor,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),

        // 4 Colorful Feature Cards
        ..._features.map((feature) {
          final iconBg = isDark ? feature.darkIconBg : feature.lightIconBg;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ScamShieldCard(
              padding: const EdgeInsets.all(16),
              borderColor: feature.accentColor.withValues(
                alpha: isDark ? 0.25 : 0.18,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: feature.accentColor.withValues(
                          alpha: isDark ? 0.35 : 0.25,
                        ),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: feature.accentColor.withValues(
                            alpha: isDark ? 0.20 : 0.10,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        feature.icon,
                        size: 22,
                        color: feature.accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: headlineColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          feature.description,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: subtitleColor,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 10),

        // "Your Privacy Comes First" Showcase Card (Matching Screen 3 in 1000261210.png)
        ScamShieldCard(
          padding: const EdgeInsets.all(18),
          borderColor: isDark
              ? const Color(0xFF0D9488).withValues(alpha: 0.35)
              : const Color(0xFF0891B2).withValues(alpha: 0.25),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Phone illustration with shield checkmark
              const _PrivacyPhoneGraphic(),
              const SizedBox(width: 16),

              // Title and 4 Privacy bullet points
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Privacy Comes First',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: headlineColor,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PrivacyBullet(
                      text: 'Your data stays private',
                      textColor: subtitleColor,
                    ),
                    const SizedBox(height: 6),
                    _PrivacyBullet(
                      text: 'Secure and encrypted',
                      textColor: subtitleColor,
                    ),
                    const SizedBox(height: 6),
                    _PrivacyBullet(
                      text: 'Only authorized access',
                      textColor: subtitleColor,
                    ),
                    const SizedBox(height: 6),
                    _PrivacyBullet(
                      text: 'No unsolicited data sharing',
                      textColor: subtitleColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Phone illustration with security shield matching Screen 3 of 1000261210.png
class _PrivacyPhoneGraphic extends StatelessWidget {
  const _PrivacyPhoneGraphic();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 74,
      height: 110,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F2038) : const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF38BDF8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Phone top speaker slot
          Positioned(
            top: 7,
            child: Container(
              width: 20,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Shield with checkmark icon in center
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              size: 26,
              color: Color(0xFF10B981), // Emerald
            ),
          ),
          // Home indicator line at bottom
          Positioned(
            bottom: 7,
            child: Container(
              width: 22,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyBullet extends StatelessWidget {
  const _PrivacyBullet({
    required this.text,
    required this.textColor,
  });

  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_rounded,
          size: 16,
          color: Color(0xFF10B981), // Vibrant Green Checkmark matching 1000261210.png
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: textColor,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
