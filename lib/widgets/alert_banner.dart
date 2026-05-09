import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';

/// V2 alert banner used by the weather screen to surface active
/// warnings (storm, heat, heavy rain). Tappable — [onViewAll] opens
/// the full alerts list.
class AlertBanner extends StatelessWidget {
  const AlertBanner({super.key, required this.alerts, required this.onViewAll});

  final List<String> alerts;
  final VoidCallback onViewAll;

  static const Color _bg = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Material(
        color: _bg,
        borderRadius: AppRadii.brLg,
        child: InkWell(
          onTap: onViewAll,
          borderRadius: AppRadii.brLg,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    Text(
                      'Weather alerts',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'View all',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  alerts.first,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (alerts.length > 1) ...[
                  const SizedBox(height: 2),
                  Text(
                    '+${alerts.length - 1} more alert${alerts.length == 2 ? '' : 's'}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
