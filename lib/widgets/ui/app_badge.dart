import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_radii.dart';

/// Semantic tone of an [AppBadge].
enum AppBadgeTone { neutral, brand, success, warning, danger, info }

/// A small status indicator with three common forms:
///
/// * **Dot** — `AppBadge()` — a tiny coloured circle for "something
///   changed" signals (notification indicator, unread dot).
/// * **Count** — `AppBadge(count: 3)` — number in a pill, capped by
///   [maxCount] (shows "9+" past the cap).
/// * **Label** — `AppBadge.label('New')` — short text pill for status
///   tags ("NEW", "SALE", "DELIVERED").
///
/// Wrap any widget to anchor a dot or count to its corner:
///
/// ```dart
/// AppBadge.overlay(
///   count: unread,
///   child: Icon(Icons.notifications_outlined),
/// )
/// ```
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    this.count,
    this.tone = AppBadgeTone.brand,
    this.maxCount = 9,
  }) : _label = null,
       _dot = true,
       _child = null;

  /// Count variant — shows a pill with the number.
  const AppBadge.count({
    super.key,
    required int this.count,
    this.tone = AppBadgeTone.brand,
    this.maxCount = 9,
  }) : _label = null,
       _dot = false,
       _child = null;

  /// Label variant — short text in a pill (e.g. "NEW", "SALE").
  const AppBadge.label(
    String label, {
    super.key,
    this.tone = AppBadgeTone.brand,
  }) : count = null,
       _label = label,
       _dot = false,
       maxCount = 0,
       _child = null;

  /// Positions a dot or count badge at the top-right of [child].
  const AppBadge.overlay({
    super.key,
    required Widget child,
    this.count,
    this.tone = AppBadgeTone.danger,
    this.maxCount = 9,
  }) : _label = null,
       _dot = count == null,
       _child = child;

  final int? count;
  final AppBadgeTone tone;
  final int maxCount;

  final String? _label;
  final bool _dot;
  final Widget? _child;

  @override
  Widget build(BuildContext context) {
    if (_child != null) {
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topRight,
        children: [
          _child,
          Positioned(top: -4, right: -4, child: _renderBadge()),
        ],
      );
    }
    return _renderBadge();
  }

  Widget _renderBadge() {
    final palette = _paletteFor(tone);

    if (_dot) {
      return AnimatedContainer(
        duration: AppMotion.fast,
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: palette.background,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surface, width: 1.5),
        ),
      );
    }

    final String text;
    if (_label != null) {
      text = _label;
    } else {
      final int c = count ?? 0;
      text = c > maxCount ? '$maxCount+' : '$c';
    }

    return AnimatedContainer(
      duration: AppMotion.fast,
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: AppRadii.brFull,
        border: Border.all(color: AppColors.surface, width: 1.5),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            height: 1,
            fontWeight: FontWeight.w700,
            color: palette.foreground,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _BadgePalette {
  const _BadgePalette(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

_BadgePalette _paletteFor(AppBadgeTone tone) {
  switch (tone) {
    case AppBadgeTone.neutral:
      return const _BadgePalette(
        AppColors.surfaceContainerHigh,
        AppColors.onSurface,
      );
    case AppBadgeTone.brand:
      return const _BadgePalette(AppColors.primary, AppColors.onPrimary);
    case AppBadgeTone.success:
      return const _BadgePalette(AppColors.success, AppColors.onSuccess);
    case AppBadgeTone.warning:
      return const _BadgePalette(AppColors.warning, AppColors.onWarning);
    case AppBadgeTone.danger:
      return const _BadgePalette(AppColors.danger, AppColors.onDanger);
    case AppBadgeTone.info:
      return const _BadgePalette(AppColors.info, AppColors.onInfo);
  }
}
