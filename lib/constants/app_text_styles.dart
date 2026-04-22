import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';

/// Typography for KisanVeer, built on the Material 3 type scale and
/// adapted for the Poppins font face.
///
/// Two layers, mirroring `AppColors`:
///
///  1. **Material 3 scale** — `displayLarge`, `headlineMedium`,
///     `titleMedium`, `bodyLarge`, `labelSmall`, etc. Fed into
///     [ThemeData.textTheme] via [AppTheme] so any widget that reads
///     `Theme.of(context).textTheme.bodyLarge` picks them up.
///     New screens should prefer `Theme.of(context).textTheme` over
///     direct references.
///
///  2. **Legacy v1 fields** (`h1`…`h4`, `bodyLarge`, `caption`, etc.)
///     retained so existing screens continue to compile unchanged.
///     They now alias the matching M3 entries where possible; identical
///     pixel sizes so no visual drift.
class AppTextStyles {
  AppTextStyles._();

  static const String _family = 'Poppins';
  static const Color _onSurface = AppColors.textPrimary;
  static const Color _onSurfaceVariant = AppColors.textSecondary;

  // ─── Material 3 display — oversized, use sparingly ──────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _family,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: _onSurface,
    height: 1.15,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _family,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: _onSurface,
    height: 1.18,
    letterSpacing: -0.25,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: _family,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: _onSurface,
    height: 1.2,
  );

  // ─── Headline — screen-level headings ───────────────────────────────
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: _onSurface,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: _onSurface,
    height: 1.28,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: _onSurface,
    height: 1.3,
  );

  // ─── Title — section headers, card titles ───────────────────────────
  static const TextStyle titleLarge = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: _onSurface,
    height: 1.33,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: _onSurface,
    height: 1.4,
    letterSpacing: 0.15,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: _onSurface,
    height: 1.42,
    letterSpacing: 0.1,
  );

  // ─── Body — paragraph text ──────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: _onSurface,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: _onSurface,
    height: 1.5,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: _onSurfaceVariant,
    height: 1.5,
    letterSpacing: 0.4,
  );

  // ─── Label — buttons, chips, tabs, captions ─────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: _onSurface,
    height: 1.43,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: _onSurface,
    height: 1.33,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: _onSurface,
    height: 1.45,
    letterSpacing: 0.5,
  );

  /// Tabular-numeric variant of [bodyMedium] for prices, metrics, and
  /// any number that should align column-wise in a list.
  static const TextStyle numeric = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: _onSurface,
    height: 1.4,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Emphasised numeric — hero numbers on dashboards and market screens.
  static const TextStyle numericEmphasis = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: _onSurface,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // ─── Legacy v1 aliases (retained for source compatibility) ─────────
  // These map v1 names onto the v2 M3 scale at the same pixel sizes so
  // already-built screens render identically until migrated.

  static const TextStyle h1 = headlineLarge; // 28
  static const TextStyle h2 = headlineMedium; // 24
  static const TextStyle h3 = headlineSmall; // 20
  static const TextStyle h4 = titleLarge; // 18

  /// Legacy alias — prefer [titleLarge] for section/card headings.
  static const TextStyle heading = headlineSmall; // 20, bold (v1 used 20/700)

  /// Legacy alias — prefer [titleMedium].
  static const TextStyle subtitle = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: _onSurfaceVariant,
    height: 1.5,
  );

  /// Legacy alias — prefer [bodyLarge].
  static const TextStyle body = bodyLarge;

  /// Solid white CTA label — legacy button text.
  static const TextStyle buttonText = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  /// Legacy caption (12 / 500).
  static const TextStyle caption = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: _onSurfaceVariant,
  );

  /// Legacy label (14 / 500).
  static const TextStyle label = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: _onSurface,
  );

  /// Legacy price text — brand-coloured.
  static const TextStyle price = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  /// Legacy tab label (14 / 600, unstyled color so TabBar can colorize).
  static const TextStyle tabLabel = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  // ─── Helper: bundle as Material 3 TextTheme ────────────────────────
  /// Exposes the M3 scale as a ready-made [TextTheme] so [AppTheme] can
  /// wire it into [ThemeData.textTheme] in one line.
  static const TextTheme textTheme = TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
