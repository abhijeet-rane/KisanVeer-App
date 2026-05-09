import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';

/// V2 hourly forecast tile used in the weather screen's horizontal
/// hourly strip. Fixed width so tiles line up cleanly in a scroll.
class HourForecast extends StatelessWidget {
  const HourForecast({
    super.key,
    required this.time,
    required this.temperature,
    required this.icon,
  });

  final String time;
  final String temperature;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: AppSpacing.space12),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: AppSpacing.space16,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            time,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          SvgPicture.asset(icon, height: 28, width: 28),
          const SizedBox(height: AppSpacing.space8),
          Text(
            temperature,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
