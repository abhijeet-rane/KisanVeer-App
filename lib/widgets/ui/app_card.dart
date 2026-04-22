import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_elevation.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';

/// Visual treatment of an [AppCard].
enum AppCardVariant {
  /// White surface that lifts off the page with a subtle shadow.
  /// The most common choice for list items, dashboard cards, etc.
  elevated,

  /// Tinted surface that reads as "grouped" rather than "lifted".
  /// Best for nested cards inside an already-elevated container, or
  /// for secondary-importance cards in a grid.
  filled,

  /// Transparent surface with a hairline border. Lightest visual
  /// weight — use for list rows where depth would feel noisy.
  outlined,
}

/// A consistent, theme-aware container for grouped content.
///
/// All cards share:
/// * Rounded corners from [AppRadii.lg].
/// * Internal padding of [AppSpacing.cardPadding] by default, overridable.
/// * A press-scale micro-animation when [onTap] is provided.
/// * Ink splash on tap for Material-standard feedback.
///
/// For a card with a header / title + trailing action, compose it
/// manually with [AppSectionHeader] as the first child — the card
/// stays layout-agnostic.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.elevated,
    this.onTap,
    this.padding = AppSpacing.cardInsets,
    this.margin,
    this.borderRadius = AppRadii.brLg,
    this.backgroundColor,
    this.borderColor,
    this.shadow,
    this.width,
    this.height,
    this.semanticLabel,
  });

  /// Content rendered inside the card.
  final Widget child;

  /// Visual treatment. See [AppCardVariant].
  final AppCardVariant variant;

  /// When non-null, the card becomes tappable with ripple + press-scale.
  final VoidCallback? onTap;

  /// Internal padding around [child]. Defaults to
  /// [AppSpacing.cardInsets] (16dp all sides).
  final EdgeInsetsGeometry padding;

  /// External margin. Defaults to `null` (no margin — callers control
  /// spacing from outside).
  final EdgeInsetsGeometry? margin;

  /// Corner radius. Defaults to [AppRadii.brLg].
  final BorderRadius borderRadius;

  /// Override the variant's default background color.
  final Color? backgroundColor;

  /// Override the outlined variant's border color.
  final Color? borderColor;

  /// Override the elevated variant's shadow. Usually unnecessary —
  /// prefer the variant default.
  final List<BoxShadow>? shadow;

  final double? width;
  final double? height;

  /// Optional semantic label for screen readers when the card is
  /// tappable. Falls back to the first text found in [child].
  final String? semanticLabel;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  bool get _interactive => widget.onTap != null;

  void _setPressed(bool pressed) {
    if (!_interactive) return;
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final decoration = _decorationFor(
      widget.variant,
      widget.backgroundColor,
      widget.borderColor,
      widget.shadow,
      widget.borderRadius,
      _pressed,
    );

    Widget card = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      width: widget.width,
      height: widget.height,
      padding: widget.padding,
      decoration: decoration,
      child: widget.child,
    );

    if (_interactive) {
      card = Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: card,
        ),
      );

      card = AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: Semantics(
          button: true,
          label: widget.semanticLabel,
          child: card,
        ),
      );
    }

    if (widget.margin != null) {
      card = Padding(padding: widget.margin!, child: card);
    }

    return card;
  }
}

BoxDecoration _decorationFor(
  AppCardVariant variant,
  Color? backgroundOverride,
  Color? borderOverride,
  List<BoxShadow>? shadowOverride,
  BorderRadius borderRadius,
  bool pressed,
) {
  switch (variant) {
    case AppCardVariant.elevated:
      return BoxDecoration(
        color: backgroundOverride ?? AppColors.cardBackground,
        borderRadius: borderRadius,
        boxShadow: pressed
            ? AppElevation.shadowLow
            : (shadowOverride ?? AppElevation.shadowMedium),
      );
    case AppCardVariant.filled:
      return BoxDecoration(
        color: backgroundOverride ?? AppColors.surfaceContainerLow,
        borderRadius: borderRadius,
      );
    case AppCardVariant.outlined:
      return BoxDecoration(
        color: backgroundOverride ?? AppColors.surface,
        borderRadius: borderRadius,
        border: Border.all(
          color: borderOverride ?? AppColors.outlineVariant,
          width: 1,
        ),
      );
  }
}
