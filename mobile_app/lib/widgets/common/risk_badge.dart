import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Reusable status and risk badge adhering to ScamShield 2.0 semantic tokens.
/// Always pairs a clear text label with color to ensure high-contrast accessibility.
class RiskBadge extends StatelessWidget {
  const RiskBadge({
    required this.label,
    this.riskLevel,
    this.icon,
    this.dense = false,
    super.key,
  });

  final String label;
  final String? riskLevel;
  final IconData? icon;
  final bool dense;

  IconData? _resolveIcon() {
    if (icon != null) return icon;
    final normalized = (riskLevel ?? '').toUpperCase().trim();
    return switch (normalized) {
      'CRITICAL' => Icons.dangerous_rounded,
      'HIGH' => Icons.warning_rounded,
      'MEDIUM' || 'SUSPICIOUS' || 'WARNING' => Icons.warning_amber_rounded,
      'LOW' || 'SAFE' || 'GENUINE' => Icons.check_circle_rounded,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppColors.riskColor(riskLevel, isDark: isDark);
    final bg = AppColors.riskBackground(riskLevel, isDark: isDark);
    final displayIcon = _resolveIcon();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 12,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppSpacing.roundedPill,
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.5 : 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (displayIcon != null) ...[
            Icon(displayIcon, size: dense ? 12 : 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: dense ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
