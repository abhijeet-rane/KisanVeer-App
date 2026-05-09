import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:shimmer/shimmer.dart';

/// A shimmering box that stands in for real content while it loads.
///
/// Use the primitive [AppSkeleton] for custom shapes, or pick one of
/// the higher-level presets ([AppSkeleton.line], [.listTile], [.card],
/// [.productCard], [.postCard]) for common layouts.
///
/// All skeletons share a single `Shimmer` animation so multiple
/// skeletons on the same screen animate in phase.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadii.brSm,
    this.child,
  });

  /// Single-line shimmering bar. Use for text placeholders.
  const AppSkeleton.line({
    super.key,
    this.width = double.infinity,
    this.height = 14,
  }) : borderRadius = AppRadii.brSm,
       child = null;

  /// Circular shimmering disc — avatar placeholder.
  const AppSkeleton.circle({super.key, required double size})
    : width = size,
      height = size,
      borderRadius = AppRadii.brFull,
      child = null;

  /// Rounded-rectangle placeholder for an image or thumbnail.
  const AppSkeleton.image({
    super.key,
    this.width = double.infinity,
    this.height = 180,
  }) : borderRadius = AppRadii.brMd,
       child = null;

  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceContainer,
      highlightColor: AppColors.surfaceContainerLow,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    );
  }
}

/// Layout presets — render several skeleton primitives in the shape of
/// a common content type so callers don't need to compose them manually.
class AppSkeletons {
  AppSkeletons._();

  /// Renders [count] list tiles, each with a 40dp avatar on the left,
  /// two stacked lines on the right.
  static Widget listTiles({int count = 6}) {
    return Column(
      children: List.generate(
        count,
        (i) => Padding(
          padding: EdgeInsets.only(
            bottom: i == count - 1 ? 0 : AppSpacing.space12,
          ),
          child: Row(
            children: const [
              AppSkeleton.circle(size: 40),
              SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton.line(width: 160, height: 14),
                    SizedBox(height: AppSpacing.space6),
                    AppSkeleton.line(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card with a hero image, 2 title lines, and 1 metadata line.
  static Widget cardWithImage() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AppSkeleton.image(height: 140),
          SizedBox(height: AppSpacing.space12),
          AppSkeleton.line(width: 200),
          SizedBox(height: AppSpacing.space6),
          AppSkeleton.line(width: 140),
          SizedBox(height: AppSpacing.space12),
          AppSkeleton.line(width: 80, height: 12),
        ],
      ),
    );
  }

  /// A grid of product-card skeletons (image + title + price).
  static Widget productGrid({int count = 4, int crossAxisCount = 2}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.space12,
        mainAxisSpacing: AppSpacing.space12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (_, __) => cardWithImage(),
    );
  }

  /// Renders [count] community-post skeletons.
  static Widget postFeed({int count = 4}) {
    return Column(
      children: List.generate(
        count,
        (i) => Padding(
          padding: EdgeInsets.only(
            bottom: i == count - 1 ? 0 : AppSpacing.space16,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.space16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.brLg,
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    AppSkeleton.circle(size: 36),
                    SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSkeleton.line(width: 120, height: 14),
                          SizedBox(height: AppSpacing.space4),
                          AppSkeleton.line(width: 80, height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.space12),
                AppSkeleton.line(),
                SizedBox(height: AppSpacing.space6),
                AppSkeleton.line(width: 240),
                SizedBox(height: AppSpacing.space6),
                AppSkeleton.line(width: 180),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Dashboard hero skeleton — big header bar + KPI row.
  static Widget dashboardHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        AppSkeleton(width: 200, height: 28, borderRadius: AppRadii.brSm),
        SizedBox(height: AppSpacing.space12),
        AppSkeleton(
          width: double.infinity,
          height: 160,
          borderRadius: AppRadii.brLg,
        ),
      ],
    );
  }
}
