import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';

/// A compact, rounded label that can act as a filter, tag, or status
/// pill.
///
/// Two common usages:
///
/// 1. **Filter** — selectable. Pass [selected] and [onSelected]:
///    ```dart
///    AppChip(
///      label: 'Organic',
///      selected: isOrganic,
///      onSelected: (next) => setState(() => isOrganic = next),
///    )
///    ```
///
/// 2. **Tag / status** — read-only or tap-to-dismiss. Pass [onTap] or
///    [onDeleted]:
///    ```dart
///    AppChip(label: 'Delivered', leading: Icon(Icons.check, size: 14))
///    AppChip(label: 'Cotton', onDeleted: () => remove('Cotton'))
///    ```
///
/// Selection transitions use [AppMotion.fast] so they feel alive but
/// don't draw attention away from real content.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.leading,
    this.selected = false,
    this.onSelected,
    this.onTap,
    this.onDeleted,
    this.backgroundColor,
    this.selectedColor,
    this.enableHaptics = true,
  });

  /// Displayed text.
  final String label;

  /// Optional widget (icon or dot) rendered before the label.
  final Widget? leading;

  /// Whether the chip is currently selected (filter usage).
  final bool selected;

  /// Called with the new selection value when the user taps.
  /// When provided alongside [onTap], [onSelected] takes precedence.
  final ValueChanged<bool>? onSelected;

  /// Generic tap handler for non-selection chips.
  final VoidCallback? onTap;

  /// When non-null, renders a trailing `×` that calls this on tap.
  final VoidCallback? onDeleted;

  final Color? backgroundColor;
  final Color? selectedColor;
  final bool enableHaptics;

  void _handleTap() {
    if (enableHaptics) HapticFeedback.selectionClick();
    if (onSelected != null) {
      onSelected!(!selected);
    } else if (onTap != null) {
      onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool interactive = onSelected != null || onTap != null;

    final Color bg = selected
        ? (selectedColor ?? AppColors.primaryContainer)
        : (backgroundColor ?? AppColors.surfaceContainerLow);

    final Color fg = selected
        ? AppColors.onPrimaryContainer
        : AppColors.onSurfaceVariant;

    final Color borderColor = selected
        ? AppColors.primary.withValues(alpha: 0.3)
        : AppColors.outlineVariant;

    final chip = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space12,
        vertical: AppSpacing.space8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.brFull,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            IconTheme(
              data: IconThemeData(size: 14, color: fg),
              child: DefaultTextStyle(
                style: AppTextStyles.labelSmall.copyWith(color: fg),
                child: leading!,
              ),
            ),
            const SizedBox(width: AppSpacing.space6),
          ],
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: fg,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: AppSpacing.space6),
            InkWell(
              onTap: onDeleted,
              borderRadius: AppRadii.brFull,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.close, size: 14, color: fg),
              ),
            ),
          ],
        ],
      ),
    );

    if (!interactive) return chip;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: AppRadii.brFull,
        splashColor: AppColors.primary.withValues(alpha: 0.1),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: chip,
      ),
    );
  }
}
