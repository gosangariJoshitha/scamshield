import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ScamShield 2.0 typography tokens using Inter typeface hierarchy.
/// Conforms to SCAMSHIELD_DESIGN_SYSTEM.md with accessibility font scaling.
abstract final class AppTypography {
  static const String primaryFont = 'Inter';

  static TextStyle _font({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: primaryFont,
      fontFamilyFallback: const ['Roboto', '-apple-system', 'sans-serif'],
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextTheme textTheme({required bool isDark}) {
    final textColor = isDark ? AppColors.textMainDark : AppColors.textMainLight;
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final mutedColor =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return TextTheme(
      displayLarge: _font(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.15,
        color: textColor,
      ),
      displayMedium: _font(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.20,
        color: textColor,
      ),
      headlineLarge: _font(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.25,
        color: textColor,
      ),
      headlineMedium: _font(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.30,
        color: textColor,
      ),
      headlineSmall: _font(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.35,
        color: textColor,
      ),
      titleLarge: _font(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        height: 1.35,
        color: textColor,
      ),
      titleMedium: _font(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        height: 1.40,
        color: textColor,
      ),
      titleSmall: _font(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.40,
        color: secondaryColor,
      ),
      bodyLarge: _font(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.50,
        color: secondaryColor,
      ),
      bodyMedium: _font(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.45,
        color: secondaryColor,
      ),
      bodySmall: _font(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.40,
        color: mutedColor,
      ),
      labelLarge: _font(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        height: 1.0,
        color: textColor,
      ),
      labelMedium: _font(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        height: 1.0,
        color: secondaryColor,
      ),
      labelSmall: _font(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        height: 1.0,
        color: isDark ? AppColors.primaryLight : AppColors.primary,
      ),
    );
  }
}
