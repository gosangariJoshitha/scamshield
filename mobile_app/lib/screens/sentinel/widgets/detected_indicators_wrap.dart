import 'package:flutter/material.dart';

class DetectedIndicatorsWrap extends StatelessWidget {
  const DetectedIndicatorsWrap({
    required this.indicators,
    super.key,
  });

  final List<String> indicators;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasIndicators = indicators.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFEF4444)),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Detected Indicators',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEF4444),
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (hasIndicators)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: indicators.map((ind) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A1216) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                        : const Color(0xFFFECACA),
                  ),
                ),
                child: Text(
                  ind,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                  ),
                ),
              );
            }).toList(),
          )
        else
          Text(
            'None detected. Proceeding with active call monitoring.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
      ],
    );
  }
}
