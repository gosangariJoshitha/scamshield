import 'package:flutter/material.dart';

/// Spacing, radius, and layout tokens for ScamShield 2.0 (4px grid).
abstract final class AppSpacing {
  // Spacing Units (4px Base Grid)
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;

  // Component Sizes
  static const double buttonHeight = 52.0;
  static const double buttonHeightDense = 44.0;
  static const double minTouchTarget = 48.0;

  // Corner Radii (16-20px for cards, 12-14px for inputs/buttons)
  static const double radiusXs = 6.0;
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusCard = 18.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 28.0;
  static const double radiusPill = 999.0;

  static final BorderRadius roundedXs = BorderRadius.circular(radiusXs);
  static final BorderRadius roundedSm = BorderRadius.circular(radiusSm);
  static final BorderRadius roundedMd = BorderRadius.circular(radiusMd);
  static final BorderRadius roundedCard = BorderRadius.circular(radiusCard);
  static final BorderRadius roundedLg = BorderRadius.circular(radiusLg);
  static final BorderRadius roundedXl = BorderRadius.circular(radiusXl);
  static final BorderRadius roundedPill = BorderRadius.circular(radiusPill);

  // Common Padding Presets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPaddingDense = EdgeInsets.all(md);
  static const EdgeInsets badgePadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 4,
  );
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: 14,
  );

  // Max Width for Responsive Form Factor
  static const double maxContentWidth = 720.0;
}
