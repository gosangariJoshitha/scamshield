import 'package:flutter/material.dart';

/// ScamShield 2.0 design system color palette.
/// Authoritative reference: SCAMSHIELD_DESIGN_SYSTEM.md.
abstract final class AppColors {
  // Brand Identity (Deep Teal, Navy, Aqua)
  static const Color primary = Color(0xFF086B73); // Main buttons, selected tabs (Light)
  static const Color primaryHover = Color(0xFF065258);
  static const Color primaryLight = Color(0xFF65D4D8); // Luminous Teal for Dark mode & highlights
  static const Color primaryTint = Color(0xFFE6F7F8); // Very soft teal highlight
  static const Color navy = Color(0xFF102A43); // Headings, brand emphasis
  static const Color aqua = Color(0xFFA8EDF3); // Soft aqua accents & badge tints

  // Dark Theme Primary
  static const Color darkPrimary = Color(0xFF65D4D8);

  // Dark Theme Surfaces & Borders (Nuanced Slate-Teal Surfaces)
  static const Color darkBackground = Color(0xFF101820); // Obsidian Teal
  static const Color darkCard = Color(0xFF192630); // Midnight Slate
  static const Color darkCardElevated = Color(0xFF22343F); // Deep Teal Gray (Raised)
  static const Color darkBorder = Color(0xFF2B3E4C); // Subtle Divider
  static const Color darkBorderLight = Color(0xFF1E293B);

  // Light Theme Surfaces & Borders
  static const Color lightBackground = Color(0xFFF4F7FA); // Off-White Slate
  static const Color lightCard = Color(0xFFFFFFFF); // Pure White Surface
  static const Color lightCardElevated = Color(0xFFF8FAFC); // Raised Surface
  static const Color lightBorder = Color(0xFFD9E2EC); // Crisp Divider
  static const Color lightBorderLight = Color(0xFFE2E8F0);

  // Text & Typography Shades (Light Theme)
  static const Color textMainLight = Color(0xFF17212B); // Main content
  static const Color textSecondaryLight = Color(0xFF486581); // Muted Navy
  static const Color textMutedLight = Color(0xFF829AB1); // Neutral Gray

  // Text & Typography Shades (Dark Theme)
  static const Color textMainDark = Color(0xFFF1F5F9); // Crisp Off-White
  static const Color textSecondaryDark = Color(0xFFB4C2CC); // Muted Text
  static const Color textMutedDark = Color(0xFF627D98); // Muted Blue-Gray

  // Semantic Risk Severity: LOW (Lower observed risk)
  static const Color riskLowLight = Color(0xFF21845A);
  static const Color riskLowDark = Color(0xFF38A169);
  static const Color riskLowBgLight = Color(0xFFE6F4EA);
  static const Color riskLowBgDark = Color(0xFF132B20);

  // Semantic Risk Severity: MEDIUM (Caution advised)
  static const Color riskMediumLight = Color(0xFFB7791F);
  static const Color riskMediumDark = Color(0xFFECC94B);
  static const Color riskMediumBgLight = Color(0xFFFEF3C7);
  static const Color riskMediumBgDark = Color(0xFF2D2614);

  // Semantic Risk Severity: HIGH (Elevated risk)
  static const Color riskHighLight = Color(0xFFD65A31);
  static const Color riskHighDark = Color(0xFFF07844);
  static const Color riskHighBgLight = Color(0xFFFFEDD5);
  static const Color riskHighBgDark = Color(0xFF331B10);

  // Semantic Risk Severity: CRITICAL (Very high assessed risk)
  static const Color riskCriticalLight = Color(0xFFB42332);
  static const Color riskCriticalDark = Color(0xFFE53E3E);
  static const Color riskCriticalBgLight = Color(0xFFFEE2E2);
  static const Color riskCriticalBgDark = Color(0xFF331418);

  // Backwards-compatible aliases for existing code
  static const Color riskSafeLight = riskLowLight;
  static const Color riskSafeDark = riskLowDark;
  static const Color riskSafeBgLight = riskLowBgLight;
  static const Color riskSafeBgDark = riskLowBgDark;

  static const Color riskWarningLight = riskMediumLight;
  static const Color riskWarningDark = riskMediumDark;
  static const Color riskWarningBgLight = riskMediumBgLight;
  static const Color riskWarningBgDark = riskMediumBgDark;

  static const Color riskInfoLight = Color(0xFF0284C7);
  static const Color riskInfoDark = Color(0xFF38BDF8);
  static const Color riskInfoBgLight = Color(0xFFF0F9FF);
  static const Color riskInfoBgDark = Color(0x2838BDF8);

  // Category Accent Tones
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentPurple = Color(0xFFA855F7);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentAmber = Color(0xFFF59E0B);

  /// Helper to get the semantic color for a given risk level string
  static Color riskColor(String? level, {required bool isDark}) {
    final normalized = (level ?? '').toUpperCase().trim();
    return switch (normalized) {
      'CRITICAL' => isDark ? riskCriticalDark : riskCriticalLight,
      'HIGH' => isDark ? riskHighDark : riskHighLight,
      'MEDIUM' || 'SUSPICIOUS' || 'WARNING' =>
        isDark ? riskMediumDark : riskMediumLight,
      'LOW' || 'SAFE' || 'GENUINE' =>
        isDark ? riskLowDark : riskLowLight,
      _ => isDark ? riskInfoDark : riskInfoLight,
    };
  }

  /// Helper to get the semantic background tint for a risk level badge
  static Color riskBackground(String? level, {required bool isDark}) {
    final normalized = (level ?? '').toUpperCase().trim();
    return switch (normalized) {
      'CRITICAL' => isDark ? riskCriticalBgDark : riskCriticalBgLight,
      'HIGH' => isDark ? riskHighBgDark : riskHighBgLight,
      'MEDIUM' || 'SUSPICIOUS' || 'WARNING' =>
        isDark ? riskMediumBgDark : riskMediumBgLight,
      'LOW' || 'SAFE' || 'GENUINE' =>
        isDark ? riskLowBgDark : riskLowBgLight,
      _ => isDark ? riskInfoBgDark : riskInfoBgLight,
    };
  }
}
