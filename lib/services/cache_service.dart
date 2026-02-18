import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kisan_veer/utils/app_logger.dart';

class CacheService {
  static const String _weatherCacheKey = 'weather_cache';
  static const String _weatherTimestampKey = 'weather_timestamp';
  static const int _cacheValidityInMinutes = 30; // Cache valid for 30 minutes

  // Save weather data to cache
  Future<void> cacheWeatherData(Map<String, dynamic> weatherData) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save the data
    await prefs.setString(_weatherCacheKey, json.encode(weatherData));
    
    // Save the timestamp
    await prefs.setInt(_weatherTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Get cached weather data if it's still valid
  Future<Map<String, dynamic>?> getCachedWeatherData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we have cached data
    if (!prefs.containsKey(_weatherCacheKey) || !prefs.containsKey(_weatherTimestampKey)) {
      return null;
    }
    
    // Check if the cache is still valid
    final timestamp = prefs.getInt(_weatherTimestampKey)!;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diffInMinutes = (now - timestamp) ~/ (1000 * 60);
    
    if (diffInMinutes > _cacheValidityInMinutes) {
      // Cache expired
      return null;
    }
    
    // Get and return the cached data
    final cachedData = prefs.getString(_weatherCacheKey);
    if (cachedData != null) {
      // First decode the JSON string to a Map
      Map<String, dynamic> decodedData = json.decode(cachedData) as Map<String, dynamic>;
      
      // Safely convert any List<dynamic> to List<Map<String, dynamic>> for certain keys
      if (decodedData.containsKey('forecast') && decodedData['forecast'] is List) {
        try {
          decodedData['forecast'] = List<Map<String, dynamic>>.from(
            (decodedData['forecast'] as List).map((item) => 
              Map<String, dynamic>.from(item as Map<String, dynamic>)
            )
          );
        } catch (e) {
          AppLogger.w('Error converting forecast data', tag: 'Cache', error: e);
          // If conversion fails, provide an empty list
          decodedData['forecast'] = <Map<String, dynamic>>[];
        }
      }
      
      // Do the same for hourlyForecast
      if (decodedData.containsKey('hourlyForecast') && decodedData['hourlyForecast'] is List) {
        try {
          decodedData['hourlyForecast'] = List<Map<String, dynamic>>.from(
            (decodedData['hourlyForecast'] as List).map((item) => 
              Map<String, dynamic>.from(item as Map<String, dynamic>)
            )
          );
        } catch (e) {
          AppLogger.w('Error converting hourlyForecast data', tag: 'Cache', error: e);
          decodedData['hourlyForecast'] = <Map<String, dynamic>>[];
        }
      }
      
      // And for farmingAdvice
      if (decodedData.containsKey('farmingAdvice') && decodedData['farmingAdvice'] is List) {
        try {
          decodedData['farmingAdvice'] = List<Map<String, dynamic>>.from(
            (decodedData['farmingAdvice'] as List).map((item) => 
              Map<String, dynamic>.from(item as Map<String, dynamic>)
            )
          );
        } catch (e) {
          AppLogger.w('Error converting farmingAdvice data', tag: 'Cache', error: e);
          decodedData['farmingAdvice'] = <Map<String, dynamic>>[];
        }
      }
      
      return decodedData;
    }
    
    return null;
  }

  // Clear the cache
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_weatherCacheKey);
    await prefs.remove(_weatherTimestampKey);
  }

  // Location-specific cache
  Future<void> cacheLocationWeatherData(String location, Map<String, dynamic> weatherData) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Create a location-specific key
    final locationKey = 'weather_cache_$location';
    final timestampKey = 'weather_timestamp_$location';
    
    // Save the data
    await prefs.setString(locationKey, json.encode(weatherData));
    
    // Save the timestamp
    await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
    
    // Save to recently searched locations list
    await _saveRecentLocation(location);
  }

  Future<Map<String, dynamic>?> getCachedLocationWeatherData(String location) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Create a location-specific key
    final locationKey = 'weather_cache_$location';
    final timestampKey = 'weather_timestamp_$location';
    
    // Check if we have cached data
    if (!prefs.containsKey(locationKey) || !prefs.containsKey(timestampKey)) {
      return null;
    }
    
    // Check if the cache is still valid
    final timestamp = prefs.getInt(timestampKey)!;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diffInMinutes = (now - timestamp) ~/ (1000 * 60);
    
    if (diffInMinutes > _cacheValidityInMinutes) {
      // Cache expired
      return null;
    }
    
    // Get and return the cached data
    final cachedData = prefs.getString(locationKey);
    if (cachedData != null) {
      // First decode the JSON string to a Map
      Map<String, dynamic> decodedData = json.decode(cachedData) as Map<String, dynamic>;
      
      // Safely convert any List<dynamic> to List<Map<String, dynamic>> for certain keys
      if (decodedData.containsKey('forecast') && decodedData['forecast'] is List) {
        try {
          decodedData['forecast'] = List<Map<String, dynamic>>.from(
            (decodedData['forecast'] as List).map((item) => 
              Map<String, dynamic>.from(item as Map<String, dynamic>)
            )
          );
        } catch (e) {
          AppLogger.w('Error converting forecast data', tag: 'Cache', error: e);
          // If conversion fails, provide an empty list
          decodedData['forecast'] = <Map<String, dynamic>>[];
        }
      }
      
      // Do the same for hourlyForecast
      if (decodedData.containsKey('hourlyForecast') && decodedData['hourlyForecast'] is List) {
        try {
          decodedData['hourlyForecast'] = List<Map<String, dynamic>>.from(
            (decodedData['hourlyForecast'] as List).map((item) => 
              Map<String, dynamic>.from(item as Map<String, dynamic>)
            )
          );
        } catch (e) {
          AppLogger.w('Error converting hourlyForecast data', tag: 'Cache', error: e);
          decodedData['hourlyForecast'] = <Map<String, dynamic>>[];
        }
      }
      
      // And for farmingAdvice
      if (decodedData.containsKey('farmingAdvice') && decodedData['farmingAdvice'] is List) {
        try {
          decodedData['farmingAdvice'] = List<Map<String, dynamic>>.from(
            (decodedData['farmingAdvice'] as List).map((item) => 
              Map<String, dynamic>.from(item as Map<String, dynamic>)
            )
          );
        } catch (e) {
          AppLogger.w('Error converting farmingAdvice data', tag: 'Cache', error: e);
          decodedData['farmingAdvice'] = <Map<String, dynamic>>[];
        }
      }
      
      return decodedData;
    }
    
    return null;
  }

  // Save to recent locations list
  Future<void> _saveRecentLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get the existing list
    List<String> recentLocations = [];
    if (prefs.containsKey('recent_locations')) {
      recentLocations = prefs.getStringList('recent_locations') ?? [];
    }
    
    // Remove if already exists (to move it to the top)
    recentLocations.remove(location);
    
    // Add to the beginning
    recentLocations.insert(0, location);
    
    // Keep only the latest 5 locations
    if (recentLocations.length > 5) {
      recentLocations = recentLocations.sublist(0, 5);
    }
    
    // Save back
    await prefs.setStringList('recent_locations', recentLocations);
  }

  // Get recent locations
  Future<List<String>> getRecentLocations() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('recent_locations') ?? [];
  }
}
