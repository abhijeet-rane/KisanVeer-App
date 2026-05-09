import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';

/// V2 forecast card used in the weather daily forecast list.
///
/// One row per day with the day name on the left, weather icon +
/// condition in the middle, and max / min temps on the right.
class ForecastCard extends StatelessWidget {
  const ForecastCard({
    super.key,
    required this.day,
    required this.condition,
    required this.minTemp,
    required this.maxTemp,
    required this.icon,
  });

  final String day;
  final String condition;
  final String minTemp;
  final String maxTemp;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space12,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Text(
                day,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(icon, height: 24, width: 24),
                  const SizedBox(width: AppSpacing.space8),
                  Flexible(
                    child: Text(
                      condition,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              maxTemp,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            Text(
              minTemp,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
