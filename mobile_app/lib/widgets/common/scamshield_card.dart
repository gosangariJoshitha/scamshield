import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Reusable card container conforming to ScamShield 2.0 design tokens.
/// Features 16-20px corner radii, subtle borders, and optional hover elevation.
class ScamShieldCard extends StatefulWidget {
  const ScamShieldCard({
    required this.child,
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.backgroundColor,
    this.onTap,
    this.hoverLift = 0.0,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double hoverLift;

  @override
  State<ScamShieldCard> createState() => _ScamShieldCardState();
}

class _ScamShieldCardState extends State<ScamShieldCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final defaultBorder = isDark
        ? (_hovered ? AppColors.darkPrimary : AppColors.darkBorder)
        : (_hovered ? AppColors.primary : AppColors.lightBorder);

    final radius = widget.borderRadius ?? AppSpacing.roundedCard;

    return MouseRegion(
      onEnter: (_) {
        if (widget.hoverLift > 0 && mounted) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (widget.hoverLift > 0 && mounted) setState(() => _hovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(
          0,
          _hovered ? -widget.hoverLift : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? defaultBg,
          borderRadius: radius,
          border: Border.all(
            color: widget.borderColor ?? defaultBorder,
            width: 1,
          ),
          boxShadow: [
            if (_hovered && widget.hoverLift > 0)
              BoxShadow(
                color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                    .withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: radius,
            child: Padding(
              padding: widget.padding ?? AppSpacing.cardPadding,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
