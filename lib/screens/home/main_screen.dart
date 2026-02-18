import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/screens/home/dashboard_screen.dart';
import 'package:kisan_veer/screens/marketplace/marketplace_screen_fixed.dart';
import 'package:kisan_veer/screens/finance/finance_screen.dart';
import 'package:kisan_veer/screens/weather/weather_screen.dart';
import 'package:kisan_veer/screens/community/community_screen.dart';
import 'package:kisan_veer/screens/profile/profile_screen.dart';
import 'package:kisan_veer/services/notification_service.dart';
import 'package:kisan_veer/utils/weather_notification_manager.dart';

/// Main screen with bottom navigation implementing lazy loading
/// for enterprise-grade memory efficiency
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final NotificationService _notificationService = NotificationService();
  int _unreadNotificationsCount = 0;
  
  // Track which screens have been visited for lazy loading
  final Set<int> _visitedScreens = {0}; // Dashboard is always loaded first

  @override
  void initState() {
    super.initState();
    _updateUnreadNotificationsCount();
    WeatherNotificationManager.showWeatherNotificationIfNeeded();
  }

  Future<void> _updateUnreadNotificationsCount() async {
    final count = await _notificationService.getUnreadCount();
    if (mounted) {
      setState(() => _unreadNotificationsCount = count);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _visitedScreens.add(index); // Mark as visited for lazy loading
    });
    
    // Show weather notification when navigating to Weather tab
    if (index == 2) {
      WeatherNotificationManager.forceShowWeatherNotification();
    }
  }

  /// Build screen with lazy loading - only create when first visited
  Widget _buildScreen(int index) {
    if (!_visitedScreens.contains(index)) {
      return const SizedBox.shrink(); // Not visited yet, return empty
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
      // Use IndexedStack but with lazy-loaded children
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(5, _buildScreen),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.caption,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store),
              label: 'Market',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.cloud_outlined),
              activeIcon: Icon(Icons.cloud),
              label: 'Weather',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people_outlined),
              activeIcon: Icon(Icons.people),
              label: 'Community',
            ),
            _buildProfileNavItem(),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildProfileNavItem() {
    return BottomNavigationBarItem(
      icon: _buildNotificationBadge(Icons.person_outlined),
      activeIcon: _buildNotificationBadge(Icons.person),
      label: 'Profile',
    );
  }

  Widget _buildNotificationBadge(IconData icon) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (_unreadNotificationsCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Text(
                _unreadNotificationsCount > 9 ? '9+' : '$_unreadNotificationsCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

/// Wrapper widget that keeps child alive when switching tabs
/// Uses AutomaticKeepAliveClientMixin for enterprise-grade performance
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  
  const _KeepAliveWrapper({required this.child});

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

