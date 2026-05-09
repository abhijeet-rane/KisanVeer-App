import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';

/// Rendered size of an [AppAvatar].
enum AppAvatarSize {
  /// 24dp. Use in dense list rows or comment threads.
  xs,

  /// 32dp. Default for list tiles.
  sm,

  /// 40dp. Default for app bar / chip-style avatars.
  md,

  /// 56dp. Profile cards, member list headers.
  lg,

  /// 80dp. Profile screen hero.
  xl,

  /// 120dp. Full-screen avatar editor.
  xxl,
}

/// A profile avatar that falls back gracefully:
///
/// 1. If [imageUrl] loads, show the image.
/// 2. Else if [name] is provided, show the first letter(s) in a
///    brand-tinted circle.
/// 3. Else show the person icon in a neutral circle.
///
/// ```dart
/// AppAvatar(imageUrl: user.photoUrl, name: user.name, size: AppAvatarSize.md)
/// ```
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AppAvatarSize.md,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.onTap,
  });

  final String? imageUrl;
  final String? name;
  final AppAvatarSize size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  double get _diameter {
    switch (size) {
      case AppAvatarSize.xs:
        return 24;
      case AppAvatarSize.sm:
        return 32;
      case AppAvatarSize.md:
        return 40;
      case AppAvatarSize.lg:
        return 56;
      case AppAvatarSize.xl:
        return 80;
      case AppAvatarSize.xxl:
        return 120;
    }
  }

  double get _fontSize {
    // Roughly 42% of diameter so initials sit comfortably.
    return _diameter * 0.42;
  }

  String _initialsOf(String source) {
    final parts = source.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final first = parts.first;
      return first.isEmpty ? '?' : first[0].toUpperCase();
    }
    final a = parts.first;
    final b = parts[1];
    return '${a.isEmpty ? '' : a[0]}${b.isEmpty ? '' : b[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primaryContainer;
    final fg = foregroundColor ?? AppColors.onPrimaryContainer;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    Widget avatar = ClipOval(
      child: Container(
        width: _diameter,
        height: _diameter,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: borderColor == null
              ? null
              : Border.all(color: borderColor!, width: 2),
        ),
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                width: _diameter,
                height: _diameter,
                fit: BoxFit.cover,
                placeholder: (_, __) => _buildFallback(fg, bg),
                errorWidget: (_, __, ___) => _buildFallback(fg, bg),
              )
            : _buildFallback(fg, bg),
      ),
    );

    if (onTap != null) {
      avatar = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: avatar,
        ),
      );
    }

    return avatar;
  }

  Widget _buildFallback(Color fg, Color bg) {
    if (name != null && name!.trim().isNotEmpty) {
      return Text(
        _initialsOf(name!),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: _fontSize,
          color: fg,
          height: 1,
        ),
      );
    }
    return Icon(
      Icons.person_outline_rounded,
      color: fg,
      size: _diameter * 0.55,
    );
  }
}
