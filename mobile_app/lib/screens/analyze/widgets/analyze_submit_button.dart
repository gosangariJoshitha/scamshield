import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// Primary "Analyze ✨ →" button conforming to ScamShield 2.0 design tokens.
class AnalyzeSubmitButton extends StatelessWidget {
  const AnalyzeSubmitButton({
    required this.onPressed,
    this.loading = false,
    this.label = 'Analyze',
    super.key,
  });

  final VoidCallback? onPressed;
  final bool loading;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final onPrimaryColor = isDark ? const Color(0xFF101820) : Colors.white;

    final disabledBg = isDark
        ? const Color(0xFF22343F)
        : const Color(0xFFCBD5E1);
    final disabledFg = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8);

    final isEnabled = onPressed != null && !loading;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          disabledBackgroundColor: loading ? primaryColor : disabledBg,
          disabledForegroundColor: loading ? onPrimaryColor : disabledFg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          elevation: isEnabled ? 2 : 0,
          splashFactory: InkRipple.splashFactory,
        ),
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
                    'Analyzing...',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: onPrimaryColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isEnabled ? onPrimaryColor : disabledFg,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: isEnabled
                        ? (isDark ? const Color(0xFF101820) : const Color(0xFFA8EDF3))
                        : disabledFg,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: isEnabled ? onPrimaryColor : disabledFg,
                  ),
                ],
              ),
      ),
    );
  }
}
