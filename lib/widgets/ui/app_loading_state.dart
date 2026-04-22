import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';

/// The standard "loading" indicator centered in its parent.
///
/// Use [AppLoadingState] when you need a full-screen loading block
/// (e.g. before the first data frame is available). For inline
/// skeletons of specific content types, use the [AppSkeleton] helpers.
///
/// ```dart
/// body: _isLoading
///     ? const AppLoadingState(message: 'Loading orders')
///     : _buildList(),
/// ```
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    this.message,
    this.dense = false,
    this.color,
  });

  /// Optional message rendered below the spinner.
  final String? message;

  /// When true, uses a smaller spinner appropriate for cards.
  final bool dense;

  /// Override the spinner color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final double spinnerSize = dense ? 22 : 32;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: spinnerSize,
              height: spinnerSize,
              child: CircularProgressIndicator(
                strokeWidth: dense ? 2.4 : 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? AppColors.primary,
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.space12),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
