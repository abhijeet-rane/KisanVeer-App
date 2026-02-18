import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherAlertService {
  // No dependency on NotificationService for now
  
  // Check weather conditions against thresholds
  Future<void> checkForAlerts(Map<String, dynamic> weatherData) async {
    if (!await _areAlertsEnabled()) {
      return;
    }
    
    // We still need location for the alerts we store
    String location = weatherData['location'] ?? 'your location';
    Map<String, dynamic> currentWeather = weatherData['currentWeather'] ?? {};
    
    // Properly cast the forecast data from List<dynamic> to List<Map<String, dynamic>>
    List<Map<String, dynamic>>? forecast;
    if (weatherData['forecast'] != null) {
      try {
        forecast = List<Map<String, dynamic>>.from(
          (weatherData['forecast'] as List).map((item) => 
            Map<String, dynamic>.from(item as Map<String, dynamic>)
          )
        );
      } catch (e) {
        print('Error casting forecast data: $e');
        forecast = null;
      }
    }
    
    // Check current conditions for extreme weather
    final List<String> alerts = [];
    
    // Temperature alerts
    int temperature = currentWeather['temperature'] ?? 0;
    if (temperature > 40) {
      alerts.add('Extreme heat alert (${temperature}°C)! Take precautions to protect crops and livestock.');
    } else if (temperature > 35) {
      alerts.add('Heat alert (${temperature}°C)! Consider additional irrigation for crops.');
    } else if (temperature < 5) {
      alerts.add('Frost alert (${temperature}°C)! Protect sensitive crops from freezing.');
    }
    
    // Condition-based alerts
    String condition = currentWeather['condition'] ?? '';
    if (condition == 'Thunderstorm') {
      alerts.add('Thunderstorm alert! Secure outdoor equipment and livestock.');
    } else if (condition == 'Rain' && currentWeather['precipitation'] > 70) {
      alerts.add('Heavy rain alert! Potential flooding risk for low-lying fields.');
    } else if (condition == 'Snow') {
      alerts.add('Snow alert! Protect crops and ensure livestock have shelter.');
    }
    
    // Wind alerts
    int windSpeed = currentWeather['windSpeed'] ?? 0;
    if (windSpeed > 30) {
      alerts.add('Strong wind alert (${windSpeed} km/h)! Potential damage to crops and structures.');
    }
    
    // Check for incoming severe weather in forecast
    if (forecast != null && forecast.isNotEmpty) {
      // Define a default empty forecast day
      final Map<String, dynamic> defaultDay = {'condition': '', 'day': 'Unknown'};
      
      // Check the next day's weather
      Map<String, dynamic> tomorrowWeather;
      try {
        tomorrowWeather = forecast.firstWhere((day) => day['day'] == 'Tomorrow');
      } catch (e) {
        // Fallback in case of any errors
        print('Error accessing forecast data: $e');
        tomorrowWeather = defaultDay;
      }
      
      String tomorrowCondition = tomorrowWeather['condition'] ?? '';
      if (['Thunderstorm', 'Tornado', 'Hurricane'].contains(tomorrowCondition)) {
        alerts.add('Severe weather warning for tomorrow: $tomorrowCondition expected!');
      }
    }
    
    // We'll just store alerts for now instead of showing notifications
    // This avoids dependencies on notification services which may vary
    if (alerts.isNotEmpty) {
      _saveAlerts(alerts, location);
    }
  }
  
  // Save alerts to display in the app
  Future<void> _saveAlerts(List<String> alerts, String location) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save alerts with timestamp
    final alertsWithTimestamp = alerts.map((alert) {
      return {
        'message': alert,
        'location': location,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }).toList();
    
    // Convert to string list for storage
    final alertsJson = alertsWithTimestamp.map((a) => a.toString()).toList();
    
    // Get existing alerts and merge
    final existingAlertsJson = prefs.getStringList('weather_alerts') ?? [];
    
    // Combine alerts, limited to 10 most recent
    final combinedAlerts = [...alertsJson, ...existingAlertsJson];
    if (combinedAlerts.length > 10) {
      combinedAlerts.removeRange(10, combinedAlerts.length);
    }
    
    await prefs.setStringList('weather_alerts', combinedAlerts);
  }
  
  // Get saved alerts
  Future<List<Map<String, dynamic>>> getSavedAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final alertsJson = prefs.getStringList('weather_alerts') ?? [];
    
    return alertsJson.map((alertStr) {
      // Parse the string representation back to a map
      // This is a simple parsing approach - in production you'd want to use json.encode/decode
      final parts = alertStr.replaceAll('{', '').replaceAll('}', '').split(', ');
      final map = <String, dynamic>{};
      
      for (var part in parts) {
        final keyValue = part.split(': ');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim();
          final value = keyValue[1].trim();
          
          if (key == 'timestamp') {
            map[key] = int.tryParse(value) ?? DateTime.now().millisecondsSinceEpoch;
          } else {
            map[key] = value;
          }
        }
      }
      
      return map;
    }).toList();
  }
  
  // Clear all alerts
  Future<void> clearAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('weather_alerts');
  }
  
  // Check if alerts are enabled in preferences
  Future<bool> _areAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to enabled if not set
    return prefs.getBool('weather_alerts_enabled') ?? true;
  }
  
  // Update alert settings
  Future<void> setAlertsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('weather_alerts_enabled', enabled);
  }
  
  // Display an alert banner in the app
  Widget getAlertBanner(BuildContext context, List<String> alerts) {
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.orange.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Weather Alerts',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // Open full alert screen or expand alerts
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            alerts.first, // Show first alert in the banner
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          if (alerts.length > 1)
            Text(
              '+${alerts.length - 1} more alerts',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
