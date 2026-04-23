import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';

/// Visual emphasis of an [AppButton].
enum AppButtonVariant {
  /// High-emphasis filled button — brand primary color. Use for the
  /// single most important action on a screen (`Save`, `Sign in`,
  /// `Pay now`).
  primary,

  /// Medium-emphasis filled button using the tonal secondary container.
  /// Paired with a primary button to offer a secondary action
  /// (`Filter`, `Sort`).
  secondary,

  /// Medium-emphasis outlined button. Use when you need to offer an
  /// action without competing with a primary button.
  tertiary,

  /// Destructive action button — red filled. Use for delete / remove /
  /// cancel-order confirmations.
  danger,

  /// Low-emphasis text button with no container. Use inline
  /// ("See all", "Learn more") or inside dialogs.
  ghost,
}

/// Physical size of an [AppButton].
enum AppButtonSize {
  /// Compact 36dp height. Use inside dense lists, chips, or constrained
  /// card footers.
  sm,

  /// Default 48dp height. Covers most call sites.
  md,

  /// Hero 56dp height. Use for primary screen CTAs (login, checkout,
  /// pay) so they feel generous on thumbs.
  lg,
}

/// A professional, theme-aware button with consistent motion and
/// accessible touch targets across every screen.
///
/// Five variants (`primary / secondary / tertiary / danger / ghost`)
/// cover the Material 3 emphasis hierarchy. Three sizes
/// (`sm / md / lg`) cover density from dense lists up to hero CTAs.
///
/// All variants share:
/// * Consistent corner radius ([AppRadii.md]).
/// * 60 % press-scale micro-animation on tap-down for responsive feel.
/// * Light haptic feedback on tap when enabled.
/// * Built-in loading spinner that preserves the button width so the
///   layout doesn't reflow when the state flips.
/// * Optional leading / trailing icons with correct spacing.
/// * A full-width helper ([isFullWidth]) for screen-wide CTAs.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.enableHaptics = true,
    this.semanticLabel,
  });

  /// Text displayed on the button.
  final String label;

  /// Callback invoked on tap. Pass `null` to disable the button; the
  /// button visually de-emphasizes and ignores taps.
  final VoidCallback? onPressed;

  /// Emphasis / color variant. See [AppButtonVariant].
  final AppButtonVariant variant;

  /// Physical size bracket. See [AppButtonSize].
  final AppButtonSize size;

  /// Optional icon before the label.
  final IconData? leadingIcon;

  /// Optional icon after the label. Prefer for "arrow forward" / "open"
  /// affordances.
  final IconData? trailingIcon;

  /// When true, swaps the label + icons for a spinner but keeps the
  /// button width stable. Tap events are ignored while loading.
  final bool isLoading;

  /// Stretch the button to the full width of its parent. Use for hero
  /// CTAs at the bottom of auth / checkout screens.
  final bool isFullWidth;

  /// Trigger a light [HapticFeedback] on tap. Defaults to `true`.
  final bool enableHaptics;

  /// Optional semantic label for screen readers. Falls back to [label].
  final String? semanticLabel;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null || widget.isLoading;

  void _setPressed(bool pressed) {
    if (_disabled) return;
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  void _handleTap() {
    if (_disabled) return;
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(widget.variant, _disabled);
    final metrics = _metricsFor(widget.size);

    final content = widget.isLoading
        ? _LoadingIndicator(
            color: colors.foreground,
            strokeWidth: metrics.spinnerStroke,
            size: metrics.spinnerSize,
          )
        : _ButtonContent(
            label: widget.label,
            leadingIcon: widget.leadingIcon,
            trailingIcon: widget.trailingIcon,
            iconSize: metrics.iconSize,
            textStyle: metrics.textStyle.copyWith(color: colors.foreground),
            foregroundColor: colors.foreground,
          );

    final button = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      constraints: BoxConstraints(
        minHeight: metrics.minHeight,
        minWidth: widget.isFullWidth ? double.infinity : metrics.minWidth,
      ),
      padding: metrics.padding,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: AppRadii.brMd,
        border: colors.border == null
            ? null
            : Border.all(color: colors.border!, width: 1.25),
      ),
      child: Center(widthFactor: widget.isFullWidth ? null : 1, child: content),
    );

    return Semantics(
      button: true,
      enabled: !_disabled,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true, // avoid double-announcing the inner label
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: AppRadii.brMd,
              onTap: _disabled ? null : _handleTap,
              splashColor: colors.splash,
              highlightColor: colors.highlight,
              child: button,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Internal layout helpers ────────────────────────────────────────────

class _ButtonColors {
  const _ButtonColors({
    required this.background,
    required this.foreground,
    this.border,
    this.splash,
    this.highlight,
  });

  final Color background;
  final Color foreground;
  final Color? border;
  final Color? splash;
  final Color? highlight;
}

_ButtonColors _colorsFor(AppButtonVariant variant, bool disabled) {
  switch (variant) {
    case AppButtonVariant.primary:
      return _ButtonColors(
        background: disabled
            ? AppColors.primary.withValues(alpha: 0.4)
            : AppColors.primary,
        foreground: AppColors.onPrimary,
        splash: AppColors.onPrimary.withValues(alpha: 0.18),
        highlight: AppColors.onPrimary.withValues(alpha: 0.06),
      );
    case AppButtonVariant.secondary:
      return _ButtonColors(
        background: disabled
            ? AppColors.secondaryContainer.withValues(alpha: 0.5)
            : AppColors.secondaryContainer,
        foreground: AppColors.onSecondaryContainer,
        splash: AppColors.onSecondaryContainer.withValues(alpha: 0.14),
        highlight: AppColors.onSecondaryContainer.withValues(alpha: 0.06),
      );
    case AppButtonVariant.tertiary:
      return _ButtonColors(
        background: Colors.transparent,
        foreground: disabled
            ? AppColors.primary.withValues(alpha: 0.4)
            : AppColors.primary,
        border: disabled
            ? AppColors.primary.withValues(alpha: 0.4)
            : AppColors.primary,
        splash: AppColors.primary.withValues(alpha: 0.12),
        highlight: AppColors.primary.withValues(alpha: 0.06),
      );
    case AppButtonVariant.danger:
      return _ButtonColors(
        background: disabled
            ? AppColors.danger.withValues(alpha: 0.4)
            : AppColors.danger,
        foreground: AppColors.onDanger,
        splash: AppColors.onDanger.withValues(alpha: 0.18),
        highlight: AppColors.onDanger.withValues(alpha: 0.08),
      );
    case AppButtonVariant.ghost:
      return _ButtonColors(
        background: Colors.transparent,
        foreground: disabled
            ? AppColors.onSurface.withValues(alpha: 0.38)
            : AppColors.primary,
        splash: AppColors.primary.withValues(alpha: 0.1),
        highlight: AppColors.primary.withValues(alpha: 0.04),
      );
  }
}

class _ButtonMetrics {
  const _ButtonMetrics({
    required this.minHeight,
    required this.minWidth,
    required this.padding,
    required this.textStyle,
    required this.iconSize,
    required this.spinnerSize,
    required this.spinnerStroke,
  });

  final double minHeight;
  final double minWidth;
  final EdgeInsetsGeometry padding;
  final TextStyle textStyle;
  final double iconSize;
  final double spinnerSize;
  final double spinnerStroke;
}

_ButtonMetrics _metricsFor(AppButtonSize size) {
  switch (size) {
    case AppButtonSize.sm:
      // Nudged from 36 → 40 for better thumb hit-area. Still visually
      // compact but closer to the WCAG 2.5.5 / Material 3 40dp guidance
      // for dense controls. Prefer [AppButtonSize.md] (48dp) for any
      // standalone primary action.
      return const _ButtonMetrics(
        minHeight: 40,
        minWidth: 72,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space8,
        ),
        textStyle: AppTextStyles.labelMedium,
        iconSize: 16,
        spinnerSize: 16,
        spinnerStroke: 2,
      );
    case AppButtonSize.md:
      return const _ButtonMetrics(
        minHeight: 48,
        minWidth: 96,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.space20,
          vertical: AppSpacing.space12,
        ),
        textStyle: AppTextStyles.labelLarge,
        iconSize: 18,
        spinnerSize: 20,
        spinnerStroke: 2.2,
      );
    case AppButtonSize.lg:
      return const _ButtonMetrics(
        minHeight: 56,
        minWidth: 120,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.space24,
          vertical: AppSpacing.space16,
        ),
        textStyle: AppTextStyles.titleMedium,
        iconSize: 20,
        spinnerSize: 22,
        spinnerStroke: 2.4,
      );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.leadingIcon,
    required this.trailingIcon,
    required this.iconSize,
    required this.textStyle,
    required this.foregroundColor,
  });

  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double iconSize;
  final TextStyle textStyle;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: iconSize, color: foregroundColor),
          const SizedBox(width: AppSpacing.space8),
        ],
        Flexible(
          child: Text(
            label,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.space8),
          Icon(trailingIcon, size: iconSize, color: foregroundColor),
        ],
      ],
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({
    required this.color,
    required this.size,
    required this.strokeWidth,
  });

  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
