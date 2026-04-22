import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/widgets/ui/app_button.dart';

/// The "nothing here yet" placeholder shown when a list is empty by
/// design — no orders, no posts, no pinned commodities.
///
/// Prefer this over dropping a stray "No data" `Text` into the middle
/// of a screen. Three knobs cover 90 % of call sites: icon, title,
/// message, plus an optional CTA.
///
/// ```dart
/// AppEmptyState(
///   icon: Icons.receipt_long_outlined,
///   title: 'No orders yet',
///   message: 'Your marketplace purchases will show up here.',
///   actionLabel: 'Browse products',
///   onAction: () => Navigator.pushNamed(context, '/marketplace'),
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconBackground,
    this.dense = false,
  });

  /// Illustrative icon rendered in a soft circle above the title.
  final IconData icon;

  /// One-line heading.
  final String title;

  /// Optional supporting message — keep it to 1-2 short sentences.
  final String? message;

  /// Label of the CTA button. Required when [onAction] is provided.
  final String? actionLabel;

  /// Optional callback. Renders a primary [AppButton] when present.
  final VoidCallback? onAction;

  /// Override the icon color (defaults to muted on-surface).
  final Color? iconColor;

  /// Override the icon's circle background.
  final Color? iconBackground;

  /// When true, renders at a reduced size (smaller icon + tighter
  /// padding) for use inside cards or dialogs.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final double iconDiameter = dense ? 56 : 80;
    final double iconSize = dense ? 28 : 40;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          dense ? AppSpacing.space16 : AppSpacing.space24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconDiameter,
              height: iconDiameter,
              decoration: BoxDecoration(
                color: iconBackground ?? AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor ?? AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: dense
                  ? AppTextStyles.titleMedium
                  : AppTextStyles.titleLarge,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.space8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: AppSpacing.space20),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AppButtonVariant.primary,
                size: dense ? AppButtonSize.sm : AppButtonSize.md,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
