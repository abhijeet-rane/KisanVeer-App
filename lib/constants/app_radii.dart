import 'package:flutter/widgets.dart';

/// Corner-radius scale for KisanVeer.
///
/// Use these named values instead of raw pixel numbers so every card,
/// button, chip and sheet shares the same visual rhythm. The scale is
/// tuned for Material 3 — slightly rounder than classic Material.
class AppRadii {
  AppRadii._();

  // Scalar values — use when you need a single number ─────────────────
  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Sentinel used for fully rounded shapes (pill buttons, avatars).
  /// Any large value works with `BorderRadius.circular`; 999 is plenty.
  static const double full = 999;

  // BorderRadius presets — covers >95% of call sites ──────────────────
  static const BorderRadius brNone = BorderRadius.zero;
  static const BorderRadius brXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius brFull = BorderRadius.all(Radius.circular(full));

  /// Top-only radius for bottom sheets and modal handles.
  static const BorderRadius brTopXxl = BorderRadius.vertical(
    top: Radius.circular(xxl),
  );
  static const BorderRadius brTopLg = BorderRadius.vertical(
    top: Radius.circular(lg),
  );
}
