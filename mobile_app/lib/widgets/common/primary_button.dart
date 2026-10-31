import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Reusable primary action button conforming to ScamShield 2.0 design tokens.
/// Enforces accessible 52px height touch targets with built-in loading and disabled states.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.dense = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final onPrimaryColor = isDark ? AppColors.darkBackground : Colors.white;

    final targetHeight = dense ? AppSpacing.buttonHeightDense : AppSpacing.buttonHeight;

    final content = SizedBox(
      height: targetHeight,
      child: Center(
        child: loading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(onPrimaryColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: onPrimaryColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: onPrimaryColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: onPrimaryColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );

    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        disabledBackgroundColor: loading ? primaryColor : primaryColor.withValues(alpha: 0.4),
        disabledForegroundColor: loading ? onPrimaryColor : onPrimaryColor.withValues(alpha: 0.6),
        splashFactory: InkRipple.splashFactory,
        minimumSize: Size(expand ? double.infinity : 0, targetHeight),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
        ),
      ),
      child: content,
    );

    if (expand) {
      return SizedBox(
        width: double.infinity,
        height: targetHeight,
        child: button,
      );
    }
    return button;
  }
}
