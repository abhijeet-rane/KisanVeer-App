import 'package:flutter/painting.dart';

/// Elevation tokens for KisanVeer.
///
/// Provides both numeric `Material.elevation` values (for widgets that
/// accept an elevation double) and ready-made `BoxShadow` lists (for
/// custom `BoxDecoration`s). The six levels mirror Material 3's depth
/// scale and should cover every raised surface in the app.
///
/// Level semantics:
///   0 — flush with the page (buttons-at-rest, disabled surfaces)
///   1 — subtle lift (cards at rest, list tiles)
///   2 — pressed card, hovered button, top app bar on scroll
///   3 — FAB, snack bar, navigation rail
///   4 — modal bottom sheet, dialog
///   5 — tooltip, dropdown menu, date picker
class AppElevation {
  AppElevation._();

  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 3;
  static const double level3 = 6;
  static const double level4 = 8;
  static const double level5 = 12;

  // Shadow color tuned for light theme. All shadows use the same color;
  // differentiation comes from offset + blur + spread.
  static const Color _shadowColor = Color(0xFF1A1A1A);

  static const List<BoxShadow> shadowNone = [];

  static const List<BoxShadow> shadowLow = [
    BoxShadow(
      color: Color(0x0D1A1A1A), // ~5% opacity
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x141A1A1A), // ~8% opacity
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Color(0x0A1A1A1A), // ~4% opacity
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const List<BoxShadow> shadowHigh = [
    BoxShadow(
      color: Color(0x1F1A1A1A), // ~12% opacity
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
    BoxShadow(
      color: Color(0x0F1A1A1A), // ~6% opacity
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  static const List<BoxShadow> shadowModal = [
    BoxShadow(
      color: Color(0x291A1A1A), // ~16% opacity
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
    BoxShadow(
      color: Color(0x141A1A1A), // ~8% opacity
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
  ];

  static const List<BoxShadow> shadowHeavy = [
    BoxShadow(
      color: Color(0x331A1A1A), // ~20% opacity
      offset: Offset(0, 12),
      blurRadius: 32,
    ),
    BoxShadow(
      color: Color(0x1A1A1A1A), // ~10% opacity
      offset: Offset(0, 6),
      blurRadius: 12,
    ),
  ];

  /// Subtle single-shadow preset for pressable cards that want to *hint*
  /// at depth without attracting attention.
  static const List<BoxShadow> cardResting = shadowLow;

  /// Colored shadow matching a brand accent — useful for CTAs and hero
  /// surfaces. Caller supplies the color + opacity.
  static List<BoxShadow> brandedShadow(Color color, {double opacity = 0.25}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        offset: const Offset(0, 6),
        blurRadius: 20,
      ),
    ];
  }

  // Exposed for niche callers; normal code should use the presets above.
  static Color get rawShadowColor => _shadowColor;
}
