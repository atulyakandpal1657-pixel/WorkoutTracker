import 'package:flutter/material.dart';

/// Spacing, padding, and layout metrics for RepLog.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // Minimum accessible touch target (48dp for Android)
  static const double minTouchTarget = 48.0;

  // Corner radii
  static const double radiusXs = 6.0;
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 18.0;
  static const double radiusPill = 999.0;

  static const BorderRadius roundedSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );
  static const BorderRadius roundedMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );
  static const BorderRadius roundedLg = BorderRadius.all(
    Radius.circular(radiusLg),
  );
  static const BorderRadius roundedPill = BorderRadius.all(
    Radius.circular(radiusPill),
  );

  // Insets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
}
