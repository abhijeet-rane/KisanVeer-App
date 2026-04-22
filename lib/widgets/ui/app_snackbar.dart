import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';

/// Severity of an [AppSnackBar] message. Drives icon + tint.
enum AppSnackBarVariant { success, error, warning, info }

/// Unified snackbar helper for v2 toasts.
///
/// Use the static methods instead of constructing [SnackBar]s by hand
/// everywhere — it keeps tint, icon, and shape consistent across the
/// whole app.
///
/// ```dart
/// AppSnackBar.success(context, 'Profile saved');
/// AppSnackBar.error(context, 'Could not save profile');
/// AppSnackBar.info(context, 'Check your inbox for a reset link');
/// AppSnackBar.warning(context, 'Low storage — clear some cache');
/// ```
///
/// Pass an optional [actionLabel] + [onAction] to add a trailing
/// button; pass [duration] to override the default 3s.
class AppSnackBar {
  AppSnackBar._();

  /// Generic entry point — prefer the named helpers below for clarity.
  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarVariant variant = AppSnackBarVariant.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final palette = _paletteFor(variant);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.space16),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space12,
          ),
          backgroundColor: palette.bg,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.brMd),
          duration: duration,
          content: Row(
            children: [
              Icon(palette.icon, color: palette.fg, size: 20),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: palette.fg,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          action: (actionLabel != null && onAction != null)
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: palette.fg,
                  onPressed: onAction,
                )
              : null,
        ),
      );
  }

  /// Green "everything worked" toast. Use after saves, sends,
  /// confirms, and other positive completions.
  static void success(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) => show(
    context,
    message: message,
    variant: AppSnackBarVariant.success,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );

  /// Red "something went wrong" toast. Use for failed API calls,
  /// validation errors that can't be shown inline, caught exceptions.
  static void error(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) => show(
    context,
    message: message,
    variant: AppSnackBarVariant.error,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );

  /// Amber "heads up" toast. Use when something the user should know
  /// about happened but it's not a hard failure.
  static void warning(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) => show(
    context,
    message: message,
    variant: AppSnackBarVariant.warning,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );

  /// Neutral informational toast. Use for "link copied", "saved for
  /// later", and other non-critical confirmations.
  static void info(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) => show(
    context,
    message: message,
    variant: AppSnackBarVariant.info,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );
}

class _SnackPalette {
  const _SnackPalette({required this.bg, required this.fg, required this.icon});
  final Color bg;
  final Color fg;
  final IconData icon;
}

_SnackPalette _paletteFor(AppSnackBarVariant variant) {
  switch (variant) {
    case AppSnackBarVariant.success:
      return const _SnackPalette(
        bg: AppColors.success,
        fg: Colors.white,
        icon: Icons.check_circle_rounded,
      );
    case AppSnackBarVariant.error:
      return const _SnackPalette(
        bg: AppColors.danger,
        fg: Colors.white,
        icon: Icons.error_outline_rounded,
      );
    case AppSnackBarVariant.warning:
      return const _SnackPalette(
        bg: Color(0xFFF9A825), // warm amber
        fg: Colors.white,
        icon: Icons.warning_amber_rounded,
      );
    case AppSnackBarVariant.info:
      return _SnackPalette(
        bg: AppColors.onSurface,
        fg: AppColors.surface,
        icon: Icons.info_outline_rounded,
      );
  }
}
