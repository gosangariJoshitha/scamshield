import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// "Overall Stats" card with 4 input breakdown columns and
/// a vibrant, informative Threat Resolution Matrix.
class OverallStatsCard extends StatelessWidget {
  const OverallStatsCard({
    required this.messagesCount,
    required this.callsCount,
    required this.imagesCount,
    required this.documentsCount,
    this.scamsDetected = 0,
    this.safeCount = 0,
    this.highRiskCount = 0,
    this.loading = false,
    this.filterLabel = 'Lifetime Overview',
    super.key,
  });

  final int messagesCount;
  final int callsCount;
  final int imagesCount;
  final int documentsCount;
  final int scamsDetected;
  final int safeCount;
  final int highRiskCount;
  final bool loading;
  final String filterLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF192630) : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
    final headlineColor =
        isDark ? AppColors.textMainDark : AppColors.textMainLight;
    final accentColor =
        isDark ? AppColors.darkPrimary : const Color(0xFF0284C7);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Title & Filter Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.analytics_rounded,
                        size: 16,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Overall Stats',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: headlineColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (filterLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.18 : 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    filterLabel,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Informative Threat Outcome Pills Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF101B24) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF223545) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceAround,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: [
                _ThreatOutcomePill(
                  label: '$scamsDetected Blocked',
                  color: const Color(0xFFEF4444), // Crimson
                  icon: Icons.gpp_bad_rounded,
                  isDark: isDark,
                ),
                _ThreatOutcomePill(
                  label: '$safeCount Safe',
                  color: const Color(0xFF10B981), // Emerald
                  icon: Icons.verified_rounded,
                  isDark: isDark,
                ),
                _ThreatOutcomePill(
                  label: '$highRiskCount High Risk',
                  color: const Color(0xFFF59E0B), // Amber
                  icon: Icons.warning_amber_rounded,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4-Column Metrics with Category Helper Pills
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 340;

              return Row(
                children: [
                  Expanded(
                    child: _MetricColumn(
                      icon: Icons.chat_bubble_rounded,
                      count: messagesCount,
                      label: compact ? 'Messages' : 'Messages\nAnalyzed',
                      categoryHint: 'SMS & Web',
                      iconColor: const Color(0xFF0284C7), // Azure Blue
                      bgTint: isDark
                          ? const Color(0xFF0C2A44)
                          : const Color(0xFFE0F2FE),
                      loading: loading,
                    ),
                  ),
                  Expanded(
                    child: _MetricColumn(
                      icon: Icons.phone_rounded,
                      count: callsCount,
                      label: compact ? 'Calls' : 'Calls\nChecked',
                      categoryHint: 'Incoming',
                      iconColor: const Color(0xFF6366F1), // Royal Indigo
                      bgTint: isDark
                          ? const Color(0xFF1E1B4B)
                          : const Color(0xFFEDE9FE),
                      loading: loading,
                    ),
                  ),
                  Expanded(
                    child: _MetricColumn(
                      icon: Icons.image_rounded,
                      count: imagesCount,
                      label: compact ? 'Images' : 'Images\nScanned',
                      categoryHint: 'QR & Photos',
                      iconColor: const Color(0xFF0D9488), // Emerald Teal
                      bgTint: isDark
                          ? const Color(0xFF06332E)
                          : const Color(0xFFCCFBF1),
                      loading: loading,
                    ),
                  ),
                  Expanded(
                    child: _MetricColumn(
                      icon: Icons.description_rounded,
                      count: documentsCount,
                      label: compact ? 'Docs' : 'Documents\nAnalyzed',
                      categoryHint: 'PDF & Files',
                      iconColor: const Color(0xFF8B5CF6), // Purple Violet
                      bgTint: isDark
                          ? const Color(0xFF2E1065)
                          : const Color(0xFFF3E8FF),
                      loading: loading,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ThreatOutcomePill extends StatelessWidget {
  const _ThreatOutcomePill({
    required this.label,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  final String label;
  final Color color;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.icon,
    required this.count,
    required this.label,
    required this.categoryHint,
    required this.iconColor,
    required this.bgTint,
    required this.loading,
  });

  final IconData icon;
  final int count;
  final String label;
  final String categoryHint;
  final Color iconColor;
  final Color bgTint;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headlineColor =
        isDark ? AppColors.textMainDark : AppColors.textMainLight;
    final labelColor =
        isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular Icon Badge with Vivid Ring
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bgTint,
            shape: BoxShape.circle,
            border: Border.all(
              color: iconColor.withValues(alpha: isDark ? 0.45 : 0.35),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Icon(icon, size: 19, color: iconColor),
          ),
        ),
        const SizedBox(height: 8),

        // Value
        Text(
          loading ? '...' : '$count',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: headlineColor,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 3),

        // Subtitle (Exact string for test assertions)
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: labelColor,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 4),

        // Clear category helper pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            categoryHint,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
        ),
      ],
    );
  }
}
