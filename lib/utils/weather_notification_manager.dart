import 'package:kisan_veer/services/auth_service.dart';
import 'package:kisan_veer/services/notifications_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A utility class to manage weather notifications for logged-in users
class WeatherNotificationManager {
  static const String _lastNotificationTimeKey = 'last_weather_notification_time';
  static final AuthService _authService = AuthService();

  /// Shows a weather notification if the user is logged in
  /// and sufficient time has passed since the last notification
  static Future<void> showWeatherNotificationIfNeeded() async {
    // Only proceed if user is logged in
    if (!_authService.isLoggedIn) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastNotificationTime = prefs.getInt(_lastNotificationTimeKey) ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    // Check if at least 1 hour has passed since the last notification
    // (3,600,000 milliseconds = 1 hour)
    if (currentTime - lastNotificationTime >= 3600000) {
      await NotificationsService.showWeatherNotification();
      
      // Update the last notification time
      await prefs.setInt(_lastNotificationTimeKey, currentTime);
    }
  }

  /// Force shows a weather notification regardless of timing
  /// but only if the user is logged in
  static Future<void> forceShowWeatherNotification() async {
    // Only proceed if user is logged in
    if (!_authService.isLoggedIn) {
      return;
    }

    await NotificationsService.showWeatherNotification();
    
    // Update the last notification time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastNotificationTimeKey, 
      DateTime.now().millisecondsSinceEpoch
    );
  }
}
