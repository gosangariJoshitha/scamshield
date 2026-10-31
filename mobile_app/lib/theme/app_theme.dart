import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Centralized Material 3 theme configurations for ScamShield 2.0.
/// Conforms to SCAMSHIELD_DESIGN_SYSTEM.md.
abstract final class AppTheme {
  static ThemeData get lightTheme => _createTheme(Brightness.light);
  static ThemeData get darkTheme => _createTheme(Brightness.dark);

  static ThemeData _createTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    final baseScheme = ColorScheme(
      brightness: brightness,
      primary: primaryColor,
      onPrimary: isDark ? AppColors.darkBackground : Colors.white,
      primaryContainer: isDark
          ? AppColors.darkPrimary.withValues(alpha: 0.2)
          : AppColors.aqua.withValues(alpha: 0.35),
      onPrimaryContainer: isDark ? AppColors.darkPrimary : AppColors.navy,
      secondary: isDark ? AppColors.primaryLight : AppColors.navy,
      onSecondary: isDark ? AppColors.darkBackground : Colors.white,
      secondaryContainer: isDark
          ? AppColors.darkCardElevated
          : AppColors.lightCardElevated,
      onSecondaryContainer: isDark ? AppColors.textMainDark : AppColors.textMainLight,
      tertiary: isDark ? AppColors.primaryLight : AppColors.aqua,
      onTertiary: isDark ? AppColors.darkBackground : AppColors.navy,
      surface: isDark ? AppColors.darkCard : AppColors.lightCard,
      onSurface: isDark ? AppColors.textMainDark : AppColors.textMainLight,
      surfaceContainerHighest: isDark
          ? AppColors.darkCardElevated
          : AppColors.lightCardElevated,
      onSurfaceVariant:
          isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      outline: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      outlineVariant:
          isDark ? AppColors.darkBorderLight : AppColors.lightBorderLight,
      error: isDark ? AppColors.riskCriticalDark : AppColors.riskCriticalLight,
      onError: Colors.white,
    );

    final typography = AppTypography.textTheme(isDark: isDark);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: baseScheme,
      textTheme: typography,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        foregroundColor: baseScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: typography.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedCard,
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: typography.bodyMedium?.copyWith(
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(
            color: isDark
                ? AppColors.darkBorderLight
                : AppColors.lightBorderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(
            color: isDark
                ? AppColors.riskCriticalDark
                : AppColors.riskCriticalLight,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          elevation: 0,
          padding: AppSpacing.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
          ),
          textStyle: typography.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          padding: AppSpacing.buttonPadding,
          side: BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
          ),
          textStyle: typography.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            isDark ? AppColors.darkCard : AppColors.lightCard,
        elevation: 0,
        indicatorColor: isDark
            ? AppColors.darkPrimary.withValues(alpha: 0.22)
            : AppColors.aqua.withValues(alpha: 0.4),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: primaryColor,
              size: 24,
            );
          }
          return IconThemeData(
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return typography.labelMedium?.copyWith(
              color: primaryColor,
              fontWeight: FontWeight.w700,
            );
          }
          return typography.labelMedium?.copyWith(
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkBorderLight : AppColors.lightBorderLight,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
