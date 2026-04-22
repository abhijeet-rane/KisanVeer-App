import 'package:flutter/material.dart';

/// Color tokens for KisanVeer.
///
/// This file has two layers:
///
///  1. **Material 3 tonal palette** (`primary`, `primaryContainer`,
///     `onPrimary`, `secondary`, `tertiary`, `surface*`, `outline*`…).
///     Fed into [ColorScheme] via [AppTheme]. New components and screens
///     should reach for these via `Theme.of(context).colorScheme` rather
///     than hard-coding values.
///
///  2. **Legacy semantic fields** (`background`, `textPrimary`,
///     `cardBackground`, `success`, `greenGradient`…) retained so the
///     v1 codebase keeps compiling unchanged during the v2 UI migration.
///     Prefer the tonal palette in new code; legacy fields will be
///     removed once every screen is on the new design system.
class AppColors {
  AppColors._();

  // ─── Brand seeds ────────────────────────────────────────────────────
  /// Deep green — the KisanVeer primary. Used sparingly for CTAs,
  /// selected states, and brand moments.
  static const Color primary = Color(0xFF0E7C3F);

  /// Warm orange — secondary accent for sales, highlights, market
  /// signals. Reserved for meaningful emphasis.
  static const Color secondary = Color(0xFFFF7A00);

  /// Amber / saffron — tertiary accent for finance, pricing, callouts.
  static const Color tertiary = Color(0xFFFFC107);

  // ─── Material 3 tonal palette ───────────────────────────────────────
  // Primary (green) tonal ramp ────────────────────────────────────────
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFB8EFC9);
  static const Color onPrimaryContainer = Color(0xFF002110);
  static const Color primaryFixed = Color(0xFFB8EFC9);
  static const Color primarySurface = Color(0xFFF1FBF4);

  // Secondary (orange) tonal ramp ─────────────────────────────────────
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFFE3CC);
  static const Color onSecondaryContainer = Color(0xFF2E1500);
  static const Color secondarySurface = Color(0xFFFFF4E9);

  // Tertiary (amber) tonal ramp ───────────────────────────────────────
  static const Color onTertiary = Color(0xFF1F1500);
  static const Color tertiaryContainer = Color(0xFFFFE7A0);
  static const Color onTertiaryContainer = Color(0xFF261A00);
  static const Color tertiarySurface = Color(0xFFFFF8E3);

  // Surface / neutral ramp ────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFEAECE8);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF7F8F5);
  static const Color surfaceContainer = Color(0xFFF1F3EE);
  static const Color surfaceContainerHigh = Color(0xFFEBEDE8);
  static const Color surfaceContainerHighest = Color(0xFFE5E7E1);
  static const Color onSurface = Color(0xFF1A1C18);
  static const Color onSurfaceVariant = Color(0xFF42483E);
  static const Color outline = Color(0xFFCBD0C4);
  static const Color outlineVariant = Color(0xFFE3E7DE);
  static const Color scrim = Color(0xFF1A1C18);

  // Inverse / special ─────────────────────────────────────────────────
  static const Color inverseSurface = Color(0xFF2F312C);
  static const Color onInverseSurface = Color(0xFFF1F3EE);
  static const Color inversePrimary = Color(0xFF8EDDAB);

  // ─── Semantic feedback tokens ───────────────────────────────────────
  // Each semantic role has a solid color + a container pairing so UI
  // can render both "emphasis pill" and "toast surface" variants.

  // Success — matches primary green family for consistency.
  static const Color success = Color(0xFF18A04E);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFB8F0CB);
  static const Color onSuccessContainer = Color(0xFF002110);

  // Warning — warm amber, distinct from brand orange.
  static const Color warning = Color(0xFFE59400);
  static const Color onWarning = Color(0xFF261A00);
  static const Color warningContainer = Color(0xFFFFE2A8);
  static const Color onWarningContainer = Color(0xFF2B1B00);

  // Danger / error — Material 3 error palette tuned for the brand.
  static const Color danger = Color(0xFFBA1A1A);
  static const Color onDanger = Color(0xFFFFFFFF);
  static const Color dangerContainer = Color(0xFFFFDAD6);
  static const Color onDangerContainer = Color(0xFF410002);

  // Info — cool blue for neutral informational surfaces.
  static const Color info = Color(0xFF0061A4);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color infoContainer = Color(0xFFD1E4FF);
  static const Color onInfoContainer = Color(0xFF001D36);

  // ─── Legacy v1 fields (retained for source compatibility) ──────────
  // These are aliases over the new tokens so v1 screens that reference
  // them render identically until they migrate.

  /// Lighter tint of the primary green — legacy alias.
  static const Color primaryLight = Color(0xFF4CAF50);

  /// Legacy alias — prefer `tertiary`.
  static const Color accent = tertiary;

  /// Legacy page background — mapped to the lowest surface container so
  /// it reads as canvas rather than white.
  static const Color background = Color(0xFFF9F9F9);

  /// Legacy card surface — kept as pure white because v1 cards were
  /// stacked on the tinted background above.
  static const Color cardBackground = Color(0xFFFFFFFF);

  /// Legacy primary text color.
  static const Color textPrimary = Color(0xFF212121);

  /// Legacy secondary text color.
  static const Color textSecondary = Color(0xFF757575);

  /// Legacy tertiary / placeholder text color.
  static const Color textLight = Color(0xFFBDBDBD);

  /// Legacy alias — prefer `danger`.
  static const Color error = Color(0xFFE53935);

  // Crop-status palette (domain-specific, carried forward) ────────────
  static const Color cropHealthy = Color(0xFF4CAF50);
  static const Color cropWarning = Color(0xFFFFEB3B);
  static const Color cropDanger = Color(0xFFFF5252);

  // Legacy gradient presets ───────────────────────────────────────────
  static const List<Color> greenGradient = <Color>[
    Color(0xFF0E7C3F),
    Color(0xFF4CAF50),
  ];

  static const List<Color> orangeGradient = <Color>[
    Color(0xFFFF7A00),
    Color(0xFFFFA726),
  ];

  /// New v2 brand gradient — deep-green to fresh-green, used for hero
  /// headers and CTA backgrounds.
  static const List<Color> brandGradient = <Color>[
    Color(0xFF0E7C3F),
    Color(0xFF3FAF62),
  ];

  /// Subtle surface gradient for page backgrounds that want a hint of
  /// depth without shouting.
  static const List<Color> surfaceGradient = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFFF3F7F2),
  ];
}
