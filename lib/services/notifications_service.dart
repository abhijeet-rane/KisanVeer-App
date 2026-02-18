// lib/services/notifications_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kisan_veer/services/weather_service.dart';
import 'package:kisan_veer/services/auth_service.dart';
import 'package:flutter/material.dart' show Color;
import 'package:geolocator/geolocator.dart';

class NotificationsService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final WeatherService _weatherService = WeatherService();
  static final AuthService _authService = AuthService();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(
            '@mipmap/ic_launcher'); // Your launcher icon

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
  }

  static Future<void> showWelcomeNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'weather_channel',
      'Weather Notifications',
      channelDescription: 'Notification shown when weather tab is opened',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      0,
      '🌤️ Welcome!',
      'Welcome to the Weather tab!',
      notificationDetails,
    );
  }

  /// Shows a weather notification with current weather data for logged-in users
  static Future<void> showWeatherNotification() async {
    // Check if user is logged in
    if (!_authService.isLoggedIn) {
      return; // Don't show weather notification for non-logged in users
    }

    try {
      // Get current location - using Geolocator directly since _getCurrentLocation is private
      final position = await Geolocator.getCurrentPosition();

      // Get current weather data
      final weatherData = await _weatherService.getCurrentWeather(
        position.latitude,
        position.longitude,
      );

      // Get city name
      final cityName = await _weatherService.getCityName(
        position.latitude,
        position.longitude,
      );

      // Get hourly forecast for the next few hours
      final hourlyForecast = await _weatherService.getHourlyForecast(
        position.latitude,
        position.longitude,
      );

      // Create a styled notification content
      final String notificationTitle =
          '${weatherData['temperature']}° $cityName';

      // Build notification content with HTML styling
      final String notificationContent = _buildWeatherNotificationContent(
          weatherData, cityName, hourlyForecast);

      // Configure the notification channel for rich content with custom styling
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'weather_channel',
        'Weather Notifications',
        channelDescription: 'Shows current weather information',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          notificationContent,
          htmlFormatBigText: true,
          contentTitle: notificationTitle,
          htmlFormatContentTitle: true,
          summaryText:
              '${weatherData['description'] ?? weatherData['condition']}',
          htmlFormatSummaryText: true,
        ),
        color: Color(_getWeatherColor(weatherData['condition'])),
        colorized: true,
        ongoing: true, // Make it persistent
        playSound: false, // No sound for weather updates
        enableLights: true,
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      // Show the notification
      await _notificationsPlugin.show(
        1, // Use a different ID from welcome notification
        notificationTitle,
        notificationContent,
        notificationDetails,
      );
    } catch (e) {
      print('Error showing weather notification: $e');
    }
  }

  /// Builds a rich HTML content for the weather notification with a compact design similar to the reference image
  static String _buildWeatherNotificationContent(
    Map<String, dynamic> weatherData,
    String cityName,
    List<Map<String, dynamic>> hourlyForecast,
  ) {
    final String condition =
        weatherData['description'] ?? weatherData['condition'];

    // Format the hourly forecast (7 segments like modern weather UIs)
    final StringBuffer forecastBuffer = StringBuffer();
    for (int i = 0; i < 7 && i < hourlyForecast.length; i++) {
      final forecast = hourlyForecast[i];
      final String hourIcon = _getWeatherIconForForecast(forecast['condition']);
      final String hour = forecast['hour'].toString().split(':')[0] +
          (forecast['hour'].toString().contains('AM') ? ' AM' : ' PM');

      forecastBuffer.write('''
      <div style="display:inline-block; width:13.5%; padding:6px; margin:1px; background-color:rgba(255,255,255,0.1); border-radius:10px; text-align:center;">
        <div style="font-size:11px; color:#ffffff;">$hour</div>
        <div style="margin:4px 0;">$hourIcon</div>
        <div style="font-size:13px; color:#ffffff;">${forecast['temperature']}°</div>
      </div>
    ''');
    }

    return '''
<div style="background: linear-gradient(to right, #1e3c72, #2a5298); padding:14px; border-radius:12px; font-family:Arial, sans-serif;">
  <div style="display:flex; align-items:center; margin-bottom:10px;">
    <div style="font-size:44px; margin-right:12px;">${_getWeatherIconForMain(weatherData['condition'])}</div>
    <div style="flex-grow:1;">
      <div style="font-size:36px; font-weight:bold; color:white; line-height:1;">${weatherData['temperature']}°</div>
      <div style="font-size:15px; color:#eeeeee; margin-top:2px;">$cityName • $condition</div>
    </div>
    <div style="text-align:right; font-size:13px; color:#dddddd;">
      <div>H: ${weatherData['tempMax'] ?? (weatherData['temperature'] + 2)}° / L: ${weatherData['tempMin'] ?? (weatherData['temperature'] - 2)}°</div>
      <div>💧 ${weatherData['precipitation'] ?? '0.0'}mm</div>
    </div>
  </div>
  <hr style="border-color:rgba(255,255,255,0.2); margin:10px 0;">
  <div style="display:flex; justify-content:space-between;">
    $forecastBuffer
  </div>
</div>
''';
  }

  /// Returns an emoji based on weather condition
  static String _getWeatherEmoji(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return '☀️';
      case 'clouds':
      case 'partly cloudy':
        return '⛅';
      case 'cloudy':
      case 'overcast':
        return '☁️';
      case 'rain':
      case 'drizzle':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  /// Returns HTML for weather icons in the main display
  static String _getWeatherIconForMain(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return '<span style="font-size:42px;">☀️</span>';
      case 'clouds':
      case 'partly cloudy':
        return '<span style="font-size:42px;">⛅</span>';
      case 'cloudy':
      case 'overcast':
        return '<span style="font-size:42px;">☁️</span>';
      case 'rain':
      case 'drizzle':
        return '<span style="font-size:42px;">🌧️</span>';
      case 'thunderstorm':
        return '<span style="font-size:42px;">⛈️</span>';
      case 'snow':
        return '<span style="font-size:42px;">❄️</span>';
      case 'mist':
      case 'fog':
        return '<span style="font-size:42px;">🌫️</span>';
      default:
        return '<span style="font-size:42px;">🌤️</span>';
    }
  }

  /// Returns HTML for weather icons in the forecast
  static String _getWeatherIconForForecast(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return '<span style="font-size:18px; color:white;">☀️</span>';
      case 'clouds':
      case 'partly cloudy':
        return '<span style="font-size:18px; color:white;">⛅</span>';
      case 'cloudy':
      case 'overcast':
        return '<span style="font-size:18px; color:white;">☁️</span>';
      case 'rain':
      case 'drizzle':
        return '<span style="font-size:18px; color:white;">🌧️</span>';
      case 'thunderstorm':
        return '<span style="font-size:18px; color:white;">⛈️</span>';
      case 'snow':
        return '<span style="font-size:18px; color:white;">❄️</span>';
      case 'mist':
      case 'fog':
        return '<span style="font-size:18px; color:white;">🌫️</span>';
      default:
        return '<span style="font-size:18px; color:white;">🌤️</span>';
    }
  }

  /// Returns a color based on weather condition
  static int _getWeatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return 0xFFFFA726; // Orange
      case 'clouds':
      case 'partly cloudy':
      case 'cloudy':
      case 'overcast':
        return 0xFF78909C; // Blue Grey
      case 'rain':
      case 'drizzle':
        return 0xFF42A5F5; // Blue
      case 'thunderstorm':
        return 0xFF5C6BC0; // Indigo
      case 'snow':
        return 0xFFE0E0E0; // Light Grey
      case 'mist':
      case 'fog':
        return 0xFFB0BEC5; // Blue Grey Light
      default:
        return 0xFF03A9F4; // Light Blue
    }
  }
}
