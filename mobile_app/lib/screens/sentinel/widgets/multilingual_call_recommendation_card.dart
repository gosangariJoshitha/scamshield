import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class MultilingualCallRecommendationCard extends StatefulWidget {
  const MultilingualCallRecommendationCard({
    required this.isScam,
    this.canonicalActions = const [],
    this.actionTranslations = const {},
    this.defaultLanguage = 'en',
    super.key,
  });

  final bool isScam;
  final List<String> canonicalActions;
  final Map<String, List<String>> actionTranslations;
  final String? defaultLanguage;

  @override
  State<MultilingualCallRecommendationCard> createState() =>
      _MultilingualCallRecommendationCardState();
}

class _MultilingualCallRecommendationCardState
    extends State<MultilingualCallRecommendationCard> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    final defaultLang = widget.defaultLanguage;
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

    final Color headerColor = widget.isScam
        ? (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))
        : (isDark ? const Color(0xFF34D399) : const Color(0xFF059669));
    final Color iconColor = widget.isScam ? const Color(0xFFEF4444) : const Color(0xFFEAB308);
    final Color bulletColor = widget.isScam
        ? (isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444))
        : (isDark ? const Color(0xFF34D399) : const Color(0xFF10B981));
    final Color cardBg = widget.isScam
        ? (isDark ? const Color(0xFF261115) : const Color(0xFFFEF2F2))
        : (isDark ? const Color(0xFF092017) : const Color(0xFFF0FDF4));
    final Color cardBorder = widget.isScam
        ? (isDark ? const Color(0xFFEF4444).withValues(alpha: 0.3) : const Color(0xFFFECACA))
        : (isDark ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFF86EFAC));

    final localizedActions = widget.actionTranslations[_selectedLanguage];
    final bool hasLocalized = localizedActions != null && localizedActions.isNotEmpty;
    final List<String> actions = hasLocalized
        ? localizedActions
        : (_selectedLanguage == 'en' && widget.canonicalActions.isNotEmpty
            ? widget.canonicalActions
            : _defaultActions(widget.isScam, _selectedLanguage));

    final bool isFallbackNotice = !hasLocalized && _selectedLanguage != 'en';
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: bulletColor.withValues(alpha: isDark ? 0.08 : 0.04),
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
            children: [
              Icon(
                widget.isScam ? Icons.warning_amber_rounded : Icons.lightbulb_rounded,
                size: 20,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recommendation',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: headerColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

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
                  child: _LangPill(
                    label: 'English',
                    isSelected: _selectedLanguage == 'en',
                    onTap: () => setState(() => _selectedLanguage = 'en'),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _LangPill(
                    label: 'हिंदी',
                    isSelected: _selectedLanguage == 'hi',
                    onTap: () => setState(() => _selectedLanguage = 'hi'),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _LangPill(
                    label: 'తెలుగు',
                    isSelected: _selectedLanguage == 'te',
                    onTap: () => setState(() => _selectedLanguage = 'te'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (isFallbackNotice) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Translation in ${_langName(_selectedLanguage)} unavailable. Showing verified guidance.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Recommendation Bullets
          ...actions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 15,
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
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                        height: 1.35,
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

  static String _langName(String code) => switch (code) {
        'hi' => 'Hindi (हिंदी)',
        'te' => 'Telugu (తెలుగు)',
        _ => 'English',
      };

  static List<String> _defaultActions(bool isScam, String lang) {
    if (isScam) {
      if (lang == 'hi') {
        return const [
          'व्यक्तिगत या बैंकिंग विवरण साझा न करें।',
          'कॉल करने वाले के अनुरोध पर कोई भुगतान न करें।',
          'इस नंबर को तुरंत ब्लॉक और रिपोर्ट करें।',
          'यदि विवरण पहले ही साझा कर दिए हैं, तो तुरंत अपने बैंक से संपर्क करें।',
        ];
      }
      if (lang == 'te') {
        return const [
          'వ్యక్తిగత లేదా బ్యాంకింగ్ వివరాలను పంచుకోవద్దు.',
          'ఎటువంటి చెల్లింపులు చేయవద్దు.',
          'ఈ నంబర్‌ను బ్లాక్ చేసి రిపోర్ట్ చేయండి.',
          'సమాచారం పంచుకున్నట్లయితే, వెంటనే మీ బ్యాంకును సంప్రదించండి.',
        ];
      }
      return const [
        'Do not share any personal or banking details.',
        'Do not make any payments.',
        'Block and report this number.',
        'If you have already shared information, contact your bank immediately.',
      ];
    } else {
      if (lang == 'hi') {
        return const [
          'यह कॉल सामान्य प्रतीत होती है।',
          'अज्ञात कॉलर से संवेदनशील जानकारी साझा करते समय सावधान रहें।',
        ];
      }
      if (lang == 'te') {
        return const [
          'ఈ కాల్ సాధారణమైనదిగా కనిపిస్తుంది.',
          'తెలియని కాలర్‌తో సున్నితమైన సమాచారం పంచుకునేటప్పుడు జాగ్రత్తగా ఉండండి.',
        ];
      }
      return const [
        'This call appears normal.',
        'Always verify unknown callers before sharing sensitive information.',
      ];
    }
  }
}

class _LangPill extends StatelessWidget {
  const _LangPill({
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
    final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF0284C7);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }
}
