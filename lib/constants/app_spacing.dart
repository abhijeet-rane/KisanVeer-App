import 'package:flutter/widgets.dart';

/// Spacing scale for KisanVeer, built on a 4dp base unit.
///
/// Use these values instead of raw `const EdgeInsets.all(16)` so spacing
/// stays consistent across every screen. The scale is geometric enough
/// to produce visible rhythm without bloating the API.
///
/// See also: [Gap], [SizedBox], `Padding`.
class AppSpacing {
  AppSpacing._();

  // Raw scale ──────────────────────────────────────────────────────────
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space28 = 28;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;
  static const double space56 = 56;
  static const double space64 = 64;
  static const double space80 = 80;
  static const double space96 = 96;

  // Semantic aliases — prefer these in screen / component code ────────
  /// Inside a chip, between an icon and its label, etc.
  static const double gapXs = space4;

  /// Most common inline gap between related elements.
  static const double gapSm = space8;

  /// Default gap between two items in a vertical list.
  static const double gapMd = space12;

  /// Comfortable separation between distinct blocks in a section.
  static const double gapLg = space16;

  /// Section-to-section break inside a screen.
  static const double gapXl = space24;

  /// End-of-screen or top-level page section break.
  static const double gapXxl = space32;

  // Page / section padding ────────────────────────────────────────────
  /// Horizontal page margin. Most Android screens: 16dp; Tablets: 24dp.
  static const double pageHorizontal = space16;

  /// Standard vertical padding for page content.
  static const double pageVertical = space16;

  /// Inner padding for card-like surfaces.
  static const double cardPadding = space16;

  /// Tight inner padding for compact list tiles.
  static const double listTilePadding = space12;

  // Ready-made EdgeInsets for the common cases ────────────────────────
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
    vertical: pageVertical,
  );
  static const EdgeInsets pageHorizontalPadding = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
  );
  static const EdgeInsets cardInsets = EdgeInsets.all(cardPadding);
  static const EdgeInsets listTileInsets = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
    vertical: listTilePadding,
  );

  // Vertical gap widgets — terse, const-constructible ─────────────────
  static const Widget vGapXs = SizedBox(height: gapXs);
  static const Widget vGapSm = SizedBox(height: gapSm);
  static const Widget vGapMd = SizedBox(height: gapMd);
  static const Widget vGapLg = SizedBox(height: gapLg);
  static const Widget vGapXl = SizedBox(height: gapXl);
  static const Widget vGapXxl = SizedBox(height: gapXxl);

  // Horizontal gap widgets ────────────────────────────────────────────
  static const Widget hGapXs = SizedBox(width: gapXs);
  static const Widget hGapSm = SizedBox(width: gapSm);
  static const Widget hGapMd = SizedBox(width: gapMd);
  static const Widget hGapLg = SizedBox(width: gapLg);
  static const Widget hGapXl = SizedBox(width: gapXl);
}
