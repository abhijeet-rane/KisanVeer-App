import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kisan_veer/constants/app_colors.dart';

/// Premium shimmer loading widget with customizable shapes
/// Use for skeleton loading states across the app
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;
  
  const ShimmerLoading({
    Key? key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  }) : super(key: key);

  /// Circle shimmer for avatars
  const ShimmerLoading.circle({
    Key? key,
    required double size,
  }) : width = size,
       height = size,
       borderRadius = 0,
       shape = BoxShape.circle,
       super(key: key);

  /// Card shimmer
  const ShimmerLoading.card({
    Key? key,
    this.height = 120,
  }) : width = double.infinity,
       borderRadius = 16,
       shape = BoxShape.rectangle,
       super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: shape,
          borderRadius: shape == BoxShape.rectangle 
              ? BorderRadius.circular(borderRadius) 
              : null,
        ),
      ),
    );
  }
}

/// Skeleton card for product/item loading
class SkeletonProductCard extends StatelessWidget {
  const SkeletonProductCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          const ShimmerLoading(height: 120, borderRadius: 12),
          const SizedBox(height: 12),
          // Title
          const ShimmerLoading(width: 150, height: 16),
          const SizedBox(height: 8),
          // Subtitle
          const ShimmerLoading(width: 100, height: 12),
          const SizedBox(height: 12),
          // Price row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerLoading(width: 80, height: 20),
              ShimmerLoading.circle(size: 36),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton card for weather/dashboard
class SkeletonDashboardCard extends StatelessWidget {
  const SkeletonDashboardCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerLoading.circle(size: 48),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(width: 120, height: 18),
                    SizedBox(height: 6),
                    ShimmerLoading(width: 80, height: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const ShimmerLoading(height: 60, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Skeleton list tile
class SkeletonListTile extends StatelessWidget {
  final bool hasLeading;
  final bool hasTrailing;
  
  const SkeletonListTile({
    Key? key,
    this.hasLeading = true,
    this.hasTrailing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          if (hasLeading) ...[
            ShimmerLoading.circle(size: 48),
            const SizedBox(width: 12),
          ],
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(width: 150, height: 16),
                SizedBox(height: 6),
                ShimmerLoading(width: 100, height: 12),
              ],
            ),
          ),
          if (hasTrailing)
            const ShimmerLoading(width: 60, height: 32, borderRadius: 16),
        ],
      ),
    );
  }
}

/// Full page skeleton loader
class SkeletonPage extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int)? itemBuilder;
  
  const SkeletonPage({
    Key? key,
    this.itemCount = 5,
    this.itemBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: itemBuilder ?? (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: index == 0 
            ? const SkeletonDashboardCard()
            : const SkeletonProductCard(),
      ),
    );
  }
}
