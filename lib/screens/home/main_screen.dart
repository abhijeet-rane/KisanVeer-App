import 'package:flutter/material.dart';
import 'package:kisan_veer/screens/community/community_screen.dart';
import 'package:kisan_veer/screens/home/dashboard_screen.dart';
import 'package:kisan_veer/screens/marketplace/marketplace_screen_fixed.dart';
import 'package:kisan_veer/screens/profile/profile_screen.dart';
import 'package:kisan_veer/screens/weather/weather_screen.dart';
import 'package:kisan_veer/services/notification_service.dart';
import 'package:kisan_veer/utils/weather_notification_manager.dart';
import 'package:kisan_veer/widgets/ui/app_navigation_bar.dart';

/// Root shell of the signed-in experience.
///
/// Hosts the five top-level tabs behind an [AppNavigationBar]. Keeps
/// the v1 lazy-loading + AutomaticKeepAlive behaviour so screens stay
/// mounted once visited, preserving scroll state and in-flight futures.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final NotificationService _notificationService = NotificationService();
  int _unreadNotificationsCount = 0;

  /// Tracks which tabs the user has opened at least once, so we can
  /// keep the IndexedStack cheap on cold start.
  final Set<int> _visitedScreens = {0};

  static const int _profileTabIndex = 4;
  static const int _weatherTabIndex = 2;

  @override
  void initState() {
    super.initState();
    _updateUnreadNotificationsCount();
    WeatherNotificationManager.showWeatherNotificationIfNeeded();
  }

  Future<void> _updateUnreadNotificationsCount() async {
    final count = await _notificationService.getUnreadCount();
    if (!mounted) return;
    setState(() => _unreadNotificationsCount = count);
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
      _visitedScreens.add(index);
    });

    if (index == _weatherTabIndex) {
      WeatherNotificationManager.forceShowWeatherNotification();
    }
    if (index == _profileTabIndex) {
      // Refresh the badge count when the user lands on the Profile tab.
      _updateUnreadNotificationsCount();
    }
  }

  Widget _buildScreen(int index) {
    if (!_visitedScreens.contains(index)) {
      return const SizedBox.shrink();
    }
    switch (index) {
      case 0:
        return const _KeepAliveWrapper(child: DashboardScreen());
      case 1:
        return const _KeepAliveWrapper(child: MarketplaceScreen());
      case 2:
        return const _KeepAliveWrapper(child: WeatherScreen());
      case 3:
        return const _KeepAliveWrapper(child: CommunityScreen());
      case 4:
        return const _KeepAliveWrapper(child: ProfileScreen());
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(5, _buildScreen),
      ),
      bottomNavigationBar: AppNavigationBar(
        currentIndex: _selectedIndex,
        onChanged: _onTabChanged,
        items: [
          const AppNavigationBarItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'Home',
          ),
          const AppNavigationBarItem(
            icon: Icons.storefront_outlined,
            selectedIcon: Icons.storefront_rounded,
            label: 'Market',
          ),
          const AppNavigationBarItem(
            icon: Icons.cloud_outlined,
            selectedIcon: Icons.cloud_rounded,
            label: 'Weather',
          ),
          const AppNavigationBarItem(
            icon: Icons.forum_outlined,
            selectedIcon: Icons.forum_rounded,
            label: 'Community',
          ),
          AppNavigationBarItem(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: 'Profile',
            badgeCount: _unreadNotificationsCount > 0
                ? _unreadNotificationsCount
                : null,
          ),
        ],
      ),
    );
  }
}

/// Keeps an offstage tab alive inside an `IndexedStack` so its state
/// and scroll position survive tab switches.
class _KeepAliveWrapper extends StatefulWidget {
  const _KeepAliveWrapper({required this.child});

  final Widget child;

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
