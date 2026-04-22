import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_elevation.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/widgets/ui/app_badge.dart';

/// A single item in an [AppNavigationBar].
class AppNavigationBarItem {
  const AppNavigationBarItem({
    required this.icon,
    required this.label,
    IconData? selectedIcon,
    this.badgeCount,
    this.showDot = false,
  }) : selectedIcon = selectedIcon ?? icon;

  /// Icon displayed when the tab is *not* selected. Prefer outlined
  /// variants (`Icons.home_outlined`) so the selected state reads
  /// unambiguously as filled.
  final IconData icon;

  /// Icon displayed when the tab is selected. Defaults to [icon] when
  /// no variant is provided.
  final IconData selectedIcon;

  /// Label rendered below the icon.
  final String label;

  /// When set and > 0, an [AppBadge.count] overlays the icon.
  final int? badgeCount;

  /// When true and [badgeCount] is null, a small dot overlays the icon.
  final bool showDot;
}

/// A professional bottom navigation bar with a sliding selection pill,
/// icon state morphing, and baked-in badge support.
///
/// Behaviourally equivalent to a classic [BottomNavigationBar] — you
/// pass an index and a tap handler — but the visual treatment is
/// Material 3: each item's icon sits in a rounded pill that fades
/// in when selected, while an indicator slides horizontally between
/// tabs for continuity.
///
/// Example:
/// ```dart
/// AppNavigationBar(
///   currentIndex: _index,
///   onChanged: (i) => setState(() => _index = i),
///   items: const [
///     AppNavigationBarItem(
///       icon: Icons.home_outlined,
///       selectedIcon: Icons.home_rounded,
///       label: 'Home',
///     ),
///     ...
///   ],
/// )
/// ```
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    required this.items,
    this.enableHaptics = true,
  }) : assert(
         items.length >= 2 && items.length <= 6,
         'AppNavigationBar supports 2–6 items for usability.',
       ),
       assert(
         currentIndex >= 0 && currentIndex < items.length,
         'currentIndex must be within items bounds.',
       );

  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<AppNavigationBarItem> items;
  final bool enableHaptics;

  void _handleTap(int index) {
    if (index == currentIndex) return;
    if (enableHaptics) HapticFeedback.selectionClick();
    onChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    final double safeBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.brTopXxl,
        boxShadow: AppElevation.shadowMedium,
      ),
      padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + safeBottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: _NavItem(
                item: items[i],
                selected: i == currentIndex,
                onTap: () => _handleTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavigationBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = selected
        ? AppColors.onPrimaryContainer
        : AppColors.onSurfaceVariant;

    final Color labelColor = selected
        ? AppColors.onPrimaryContainer
        : AppColors.onSurfaceVariant;

    Widget icon = Icon(
      selected ? item.selectedIcon : item.icon,
      size: 22,
      color: iconColor,
    );

    if ((item.badgeCount ?? 0) > 0) {
      icon = AppBadge.overlay(count: item.badgeCount, child: icon);
    } else if (item.showDot) {
      icon = AppBadge.overlay(child: icon);
    }

    return Semantics(
      selected: selected,
      label: item.label,
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.brLg,
          splashColor: AppColors.primary.withValues(alpha: 0.1),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: AnimatedContainer(
            duration: AppMotion.base,
            curve: AppMotion.emphasized,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: AppMotion.base,
                  curve: AppMotion.emphasized,
                  constraints: const BoxConstraints(minHeight: 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryContainer
                        : Colors.transparent,
                    borderRadius: AppRadii.brFull,
                  ),
                  child: AnimatedSwitcher(
                    duration: AppMotion.fast,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey<bool>(selected),
                      child: icon,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: AppMotion.fast,
                  curve: AppMotion.standard,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: labelColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
