import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/widgets/ui/app_button.dart';

/// The error placeholder shown when something blew up — a service call
/// threw, a future rejected, data failed to parse.
///
/// Must surface:
/// * A recognisable error icon.
/// * A short, human title ("Couldn't load orders", not "500 Internal
///   Server Error").
/// * The technical message behind an expandable affordance so devs can
///   still see what happened without polluting the UI.
/// * A retry button if there's something the user can actually do.
///
/// ```dart
/// AppErrorState(
///   title: "Couldn't load orders",
///   message: 'Check your connection and try again.',
///   errorDetails: e.toString(),
///   onRetry: _loadOrders,
/// )
/// ```
class AppErrorState extends StatefulWidget {
  const AppErrorState({
    super.key,
    this.icon = Icons.error_outline_rounded,
    this.title = "Something went wrong",
    this.message,
    this.errorDetails,
    this.retryLabel = 'Try again',
    this.onRetry,
    this.dense = false,
  });

  /// Icon rendered above the title.
  final IconData icon;

  /// One-line heading. Keep it human — users don't read HTTP codes.
  final String title;

  /// Optional supporting message.
  final String? message;

  /// Optional low-level error string. Hidden behind a "Show details"
  /// expander so devs can still see it without scaring users.
  final String? errorDetails;

  /// Label of the retry button. Defaults to "Try again".
  final String retryLabel;

  /// Callback invoked on retry tap. When null, no retry button is shown.
  final VoidCallback? onRetry;

  /// When true, renders at a reduced size for use inside cards.
  final bool dense;

  @override
  State<AppErrorState> createState() => _AppErrorStateState();
}

class _AppErrorStateState extends State<AppErrorState> {
  bool _detailsOpen = false;

  @override
  Widget build(BuildContext context) {
    final double iconDiameter = widget.dense ? 56 : 80;
    final double iconSize = widget.dense ? 28 : 40;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          widget.dense ? AppSpacing.space16 : AppSpacing.space24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconDiameter,
              height: iconDiameter,
              decoration: const BoxDecoration(
                color: AppColors.dangerContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, size: iconSize, color: AppColors.danger),
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: widget.dense
                  ? AppTextStyles.titleMedium
                  : AppTextStyles.titleLarge,
            ),
            if (widget.message != null) ...[
              const SizedBox(height: AppSpacing.space8),
              Text(
                widget.message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
            if (widget.onRetry != null) ...[
              const SizedBox(height: AppSpacing.space20),
              AppButton(
                label: widget.retryLabel,
                onPressed: widget.onRetry,
                variant: AppButtonVariant.primary,
                leadingIcon: Icons.refresh_rounded,
                size: widget.dense ? AppButtonSize.sm : AppButtonSize.md,
              ),
            ],
            if (widget.errorDetails != null && widget.errorDetails!.isNotEmpty)
              _buildDetails(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => _detailsOpen = !_detailsOpen),
            icon: Icon(
              _detailsOpen ? Icons.expand_less : Icons.expand_more,
              size: 18,
            ),
            label: Text(_detailsOpen ? 'Hide details' : 'Show details'),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              margin: const EdgeInsets.only(top: AppSpacing.space8),
              padding: const EdgeInsets.all(AppSpacing.space12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Text(
                widget.errorDetails!,
                textAlign: TextAlign.left,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            crossFadeState: _detailsOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
