import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';

/// A consistent "Title + trailing action" row used above almost every
/// content section in the app — dashboard blocks, market lists,
/// community feed categories, profile settings groups.
///
/// ```dart
/// AppSectionHeader(
///   title: 'Market Insights',
///   actionLabel: 'See all',
///   onActionTap: () => Navigator.push(...),
/// )
/// ```
///
/// Variants:
/// * **Standard** — 18dp semi-bold title, optional subtitle underneath.
/// * **Compact** — smaller, appropriate for cards or nested sections.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
    this.leading,
    this.compact = false,
    this.padding,
  });

  /// Section title — typically 1-3 words ("Your orders", "This month").
  final String title;

  /// Optional one-line subtitle rendered below the title.
  final String? subtitle;

  /// Text of the trailing action. Ignored if [onActionTap] is null.
  final String? actionLabel;

  /// Callback for the trailing action. Renders an "→" affordance when
  /// [actionLabel] is not provided.
  final VoidCallback? onActionTap;

  /// Optional leading widget (icon, dot, avatar).
  final Widget? leading;

  /// When true, renders at a smaller size for use inside cards.
  final bool compact;

  /// Horizontal / vertical inset. Defaults to `EdgeInsets.zero` so
  /// callers have full control.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final titleStyle = compact
        ? AppTextStyles.titleMedium
        : AppTextStyles.titleLarge;

    final subtitleStyle = AppTextStyles.bodySmall.copyWith(
      color: AppColors.onSurfaceVariant,
    );

    final Widget? trailing = onActionTap == null
        ? null
        : _SectionAction(label: actionLabel, onTap: onActionTap!);

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.space12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: titleStyle),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: subtitleStyle),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.space8),
            trailing,
          ],
        ],
      ),
    );
  }
}

class _SectionAction extends StatelessWidget {
  const _SectionAction({required this.label, required this.onTap});

  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space8,
            vertical: AppSpacing.space4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != null) ...[
                Text(
                  label!,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 2),
              ],
              const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
