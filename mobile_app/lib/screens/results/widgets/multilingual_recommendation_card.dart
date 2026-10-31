import 'package:flutter/material.dart';
import '../../../models/analysis_record.dart';
import '../../../theme/app_colors.dart';

class MultilingualRecommendationCard extends StatefulWidget {
  const MultilingualRecommendationCard({
    required this.analysis,
    super.key,
  });

  final AnalysisRecord analysis;

  @override
  State<MultilingualRecommendationCard> createState() =>
      _MultilingualRecommendationCardState();
}

class _MultilingualRecommendationCardState
    extends State<MultilingualRecommendationCard> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    // Default to the record's defaultLanguage if valid, else 'en'
    final defaultLang = widget.analysis.defaultLanguage;
    if (defaultLang == 'hi') {
      _selectedLanguage = 'hi';
    } else if (defaultLang == 'te') {
      _selectedLanguage = 'te';
    } else {
      _selectedLanguage = 'en';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final riskLevel = widget.analysis.riskLevel.trim().toUpperCase();
    final isSafe = riskLevel == 'LOW' ||
        widget.analysis.classification.toUpperCase() == 'GENUINE';

    // Header styling
    final Color headerColor;
    final Color iconColor;
    final IconData headerIcon;
    final Color cardBg;
    final Color cardBorder;
    final Color bulletColor;

    if (isSafe) {
      headerColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
      iconColor = const Color(0xFFEAB308); // Yellow Bulb
      headerIcon = Icons.lightbulb_rounded;
      cardBg = isDark ? const Color(0xFF092017) : const Color(0xFFF0FDF4);
      cardBorder = isDark
          ? const Color(0xFF10B981).withValues(alpha: 0.3)
          : const Color(0xFF86EFAC).withValues(alpha: 0.5);
      bulletColor = isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
    } else {
      headerColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
      iconColor = const Color(0xFFEF4444); // Red Warning
      headerIcon = Icons.warning_amber_rounded;
      cardBg = isDark ? const Color(0xFF261115) : const Color(0xFFFEF2F2);
      cardBorder = isDark
          ? const Color(0xFFEF4444).withValues(alpha: 0.3)
          : const Color(0xFFFECACA).withValues(alpha: 0.8);
      bulletColor = isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
    }

    // Determine recommendations for selected language
    final localizedActions = widget.analysis.actionTranslations[_selectedLanguage];
    final bool hasLocalizedActions =
        localizedActions != null && localizedActions.isNotEmpty;

    // Fallback actions if localized are unavailable
    final displayActions = hasLocalizedActions
        ? localizedActions
        : (widget.analysis.safeActions.isNotEmpty
            ? widget.analysis.safeActions
            : _fallbackActionsFromRisk(riskLevel, isSafe));

    final bool isShowingFallbackNotice =
        !hasLocalizedActions && _selectedLanguage != 'en';

    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: bulletColor.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Icon & Title
          Row(
            children: [
              Icon(headerIcon, size: 22, color: iconColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Recommendation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: headerColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3-Pill Language Selector
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                Expanded(
                  child: _LanguageTab(
                    label: 'English',
                    isSelected: _selectedLanguage == 'en',
                    onTap: () => setState(() => _selectedLanguage = 'en'),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _LanguageTab(
                    label: 'हिंदी',
                    isSelected: _selectedLanguage == 'hi',
                    onTap: () => setState(() => _selectedLanguage = 'hi'),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _LanguageTab(
                    label: 'తెలుగు',
                    isSelected: _selectedLanguage == 'te',
                    onTap: () => setState(() => _selectedLanguage = 'te'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Honest Fallback Notice if Selected Language Translation is Unavailable
          if (isShowingFallbackNotice) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Translation in ${_languageName(_selectedLanguage)} is unavailable for this response. Showing verified English guidance.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Recommendation Bullets
          ...displayActions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: bulletColor,
                      height: 1.3,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      action,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _languageName(String code) {
    return switch (code) {
      'hi' => 'Hindi (हिंदी)',
      'te' => 'Telugu (తెలుగు)',
      _ => 'English',
    };
  }

  static List<String> _fallbackActionsFromRisk(String riskLevel, bool isSafe) {
    if (isSafe) {
      return const [
        'This message is safe to interact with.',
        'You can proceed if you trust the sender.',
        'Always stay cautious with unknown messages.',
        'Do not share sensitive information unless verified.',
      ];
    }
    return const [
      'Do not click on any links in this message.',
      'Do not share personal, banking, or OTP credentials.',
      'Block and report the sender immediately.',
      'Verify the request through official customer service channels.',
    ];
  }
}

class _LanguageTab extends StatelessWidget {
  const _LanguageTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isSelected
        ? (isDark ? AppColors.darkPrimary : AppColors.primary)
        : Colors.transparent;

    final Color textColor = isSelected
        ? (isDark ? const Color(0xFF101820) : Colors.white)
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
