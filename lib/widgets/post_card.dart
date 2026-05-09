import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/community_models.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';
import 'package:timeago/timeago.dart' as timeago;

/// V2 post card for the community feed.
///
/// Author header with avatar + timestamp, optional pin action, title +
/// preview, paged images strip, and a compact interaction row
/// (like + comment). Uses [AppCard] for consistent lift + press.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onPin,
  });

  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onPin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space12),
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (post.content.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      post.content,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (post.imageUrls.isNotEmpty) _buildImages(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space8,
        AppSpacing.space12,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage: post.author.avatarUrl != null
                ? NetworkImage(post.author.avatarUrl!)
                : null,
            child: post.author.avatarUrl == null
                ? Text(
                    post.author.displayName.isNotEmpty
                        ? post.author.displayName[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.author.displayName,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  timeago.format(post.createdAt),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onPin != null)
            IconButton(
              onPressed: onPin,
              tooltip: post.isPinned ? 'Unpin post' : 'Pin post',
              visualDensity: VisualDensity.compact,
              icon: Icon(
                post.isPinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                color: post.isPinned
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
                size: 20,
              ),
            ),
          if (post.category.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: AppSpacing.space4),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.6),
                borderRadius: AppRadii.brFull,
              ),
              child: Text(
                post.category,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImages() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space8),
      child: SizedBox(
        height: 220,
        // Post title already conveys what this post is about, so the
        // image is decorative as far as screen readers are concerned.
        child: ExcludeSemantics(
          child: PageView.builder(
            itemCount: post.imageUrls.length,
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: post.imageUrls[index],
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: AppColors.surfaceContainerLow,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                errorWidget: (_, _, _) => Container(
                  color: AppColors.surfaceContainerLow,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space8,
        AppSpacing.space8,
        AppSpacing.space8,
        AppSpacing.space8,
      ),
      child: Row(
        children: [
          _InteractionButton(
            icon: post.isLikedByUser
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            iconColor: post.isLikedByUser
                ? AppColors.danger
                : AppColors.onSurfaceVariant,
            label: '${post.likesCount}',
            onTap: onLike,
          ),
          const SizedBox(width: AppSpacing.space4),
          _InteractionButton(
            icon: Icons.mode_comment_outlined,
            iconColor: AppColors.onSurfaceVariant,
            label: '${post.commentsCount}',
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _InteractionButton extends StatelessWidget {
  const _InteractionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadii.brFull,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.brFull,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
            vertical: AppSpacing.space8,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: AppSpacing.space6),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
