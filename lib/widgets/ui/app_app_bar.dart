import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';

/// A consistent app-bar style matching the v2 design language.
///
/// [AppAppBar] is a drop-in for [AppBar] with sensible defaults:
/// flat, transparent, single-line title, optional back button, action
/// slots, and a subtle hairline divider that shows only when content
/// scrolls underneath it.
///
/// For screens that need a large, collapsing header, use
/// [AppSliverAppBar] inside a [CustomScrollView] instead.
///
/// ```dart
/// Scaffold(
///   appBar: AppAppBar(
///     title: 'Orders',
///     actions: [IconButton(icon: Icon(Icons.filter_list), onPressed: ...)],
///   ),
///   body: ...,
/// )
/// ```
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.centerTitle = false,
    this.showBack = true,
    this.onBack,
    this.backgroundColor,
    this.foregroundColor,
    this.bottom,
    this.height = kToolbarHeight,
  }) : assert(
         title == null || titleWidget == null,
         'Provide either title or titleWidget, not both.',
       );

  /// Plain-string title. Use for the 99% case.
  final String? title;

  /// Custom title widget when you need more than plain text
  /// (search field, branded logo, animated label).
  final Widget? titleWidget;

  /// Optional leading widget. When null and [showBack] is true,
  /// a Material back button is auto-inserted.
  final Widget? leading;

  /// Trailing action widgets (icons, text buttons).
  final List<Widget>? actions;

  /// Centers the title horizontally. Prefer `false` for long titles.
  final bool centerTitle;

  /// When true (default), a back button is auto-inserted if there's
  /// no [leading] and the route can pop.
  final bool showBack;

  /// Tap handler for the auto-inserted back button. Defaults to
  /// `Navigator.of(context).maybePop()`.
  final VoidCallback? onBack;

  /// Override the app bar background color. Defaults to transparent
  /// so it inherits the scaffold background.
  final Color? backgroundColor;

  /// Override the icon / title color.
  final Color? foregroundColor;

  /// Optional widget pinned to the bottom of the app bar
  /// (e.g. `TabBar`).
  final PreferredSizeWidget? bottom;

  final double height;

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? AppColors.onSurface;

    return AppBar(
      backgroundColor: backgroundColor ?? Colors.transparent,
      foregroundColor: fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: centerTitle,
      toolbarHeight: height,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      leading: _buildLeading(context, fg),
      automaticallyImplyLeading: false,
      title:
          titleWidget ??
          (title == null
              ? null
              : Text(
                  title!,
                  style: AppTextStyles.titleLarge.copyWith(color: fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )),
      actions: actions,
      bottom: bottom,
    );
  }

  Widget? _buildLeading(BuildContext context, Color fg) {
    if (leading != null) return leading;
    if (!showBack) return null;
    if (!Navigator.of(context).canPop()) return null;
    return IconButton(
      icon: Icon(Icons.arrow_back_rounded, color: fg),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onBack ?? () => Navigator.of(context).maybePop(),
    );
  }
}

/// A large collapsing app bar for hero screens (Dashboard, Profile,
/// detail screens with imagery). Sits inside a [CustomScrollView].
///
/// ```dart
/// CustomScrollView(
///   slivers: [
///     AppSliverAppBar(
///       title: 'Dashboard',
///       expandedTitle: 'Good morning, Abhijeet',
///       background: const _DashboardHero(),
///     ),
///     SliverPadding(padding: ..., sliver: SliverList(...)),
///   ],
/// )
/// ```
class AppSliverAppBar extends StatelessWidget {
  const AppSliverAppBar({
    super.key,
    required this.title,
    this.expandedTitle,
    this.background,
    this.actions,
    this.leading,
    this.showBack = true,
    this.onBack,
    this.expandedHeight = 220,
    this.pinned = true,
    this.floating = false,
    this.foregroundColor,
    this.backgroundColor,
    this.bottom,
  });

  /// Title shown in the collapsed state (top bar).
  final String title;

  /// Richer title shown in the expanded state (full hero). Falls back
  /// to [title] when null.
  final String? expandedTitle;

  /// Widget rendered behind the title in the expanded state. A gradient,
  /// image, or composed header.
  final Widget? background;

  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final VoidCallback? onBack;

  final double expandedHeight;
  final bool pinned;
  final bool floating;

  final Color? foregroundColor;
  final Color? backgroundColor;

  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? AppColors.onSurface;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: pinned,
      floating: floating,
      stretch: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: backgroundColor ?? AppColors.surface,
      foregroundColor: fg,
      automaticallyImplyLeading: false,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      leading: _buildLeading(context, fg),
      actions: actions,
      bottom: bottom,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double minExtent =
              MediaQuery.of(context).padding.top + kToolbarHeight;
          final double maxExtent = expandedHeight;
          final double current = constraints.biggest.height;
          final double t = ((current - minExtent) / (maxExtent - minExtent))
              .clamp(0.0, 1.0);
          return _FlexibleHeader(
            title: title,
            expandedTitle: expandedTitle ?? title,
            background: background,
            fg: fg,
            t: t,
          );
        },
      ),
    );
  }

  Widget? _buildLeading(BuildContext context, Color fg) {
    if (leading != null) return leading;
    if (!showBack) return null;
    if (!Navigator.of(context).canPop()) return null;
    return IconButton(
      icon: Icon(Icons.arrow_back_rounded, color: fg),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onBack ?? () => Navigator.of(context).maybePop(),
    );
  }
}

class _FlexibleHeader extends StatelessWidget {
  const _FlexibleHeader({
    required this.title,
    required this.expandedTitle,
    required this.background,
    required this.fg,
    required this.t,
  });

  final String title;
  final String expandedTitle;
  final Widget? background;
  final Color fg;
  final double t; // 0 = collapsed, 1 = fully expanded

  @override
  Widget build(BuildContext context) {
    return FlexibleSpaceBar(
      collapseMode: CollapseMode.parallax,
      titlePadding: EdgeInsetsDirectional.only(
        start: t < 0.5 ? 56 : AppSpacing.space16,
        bottom: 16,
        end: AppSpacing.space16,
      ),
      title: AnimatedSwitcher(
        duration: AppMotion.fast,
        child: Text(
          t < 0.5 ? title : expandedTitle,
          key: ValueKey<bool>(t < 0.5),
          style:
              (t < 0.5 ? AppTextStyles.titleLarge : AppTextStyles.headlineSmall)
                  .copyWith(color: fg),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      background:
          background ??
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryContainer, AppColors.surface],
              ),
            ),
          ),
    );
  }
}
