import 'package:flutter/animation.dart';

/// Motion tokens for KisanVeer — durations + curves consistent with
/// Material 3's motion spec.
///
/// Guidance:
///   * Use [instant] for state flips that need to feel immediate
///     (toggles, ripples).
///   * [fast] for small UI element changes (icon swaps, chip selects).
///   * [base] for most transitions users consciously perceive
///     (page fades, modal opens).
///   * [slow] for large surface transitions (bottom sheet, expansion).
///   * [slower] for hero animations and orchestrated sequences.
///
/// Pair durations with curves: `emphasized` for attention-grabbing
/// motion, `standard` for neutral, `decelerate` for entries,
/// `accelerate` for exits.
class AppMotion {
  AppMotion._();

  // Durations ─────────────────────────────────────────────────────────
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 600);

  // Curves — Material 3 motion spec ───────────────────────────────────

  /// Default curve for most transitions. Balanced, unobtrusive.
  static const Curve standard = Curves.easeInOut;

  /// Strong attention-grabbing curve with a soft landing. Use for hero
  /// transitions, shared-element moves, primary CTA interactions.
  static const Cubic emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Deceleration curve — ease-out. Use when a surface enters the
  /// screen (dialog appearing, FAB dropping in).
  static const Cubic decelerate = Cubic(0.0, 0.0, 0.2, 1.0);

  /// Acceleration curve — ease-in. Use when a surface leaves the
  /// screen (dialog dismissing, FAB hiding on scroll).
  static const Cubic accelerate = Cubic(0.3, 0.0, 1.0, 1.0);

  /// Emphasized-decelerate: entrances that deserve presence.
  static const Cubic emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Emphasized-accelerate: exits that deserve finality.
  static const Cubic emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);
}
