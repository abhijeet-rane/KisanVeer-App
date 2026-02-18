import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:kisan_veer/services/cache_service.dart';
import 'package:kisan_veer/services/weather_alert_service.dart';
import 'package:kisan_veer/services/crop_advice_service.dart';

class WeatherService {
  final SupabaseClient _client = Supabase.instance.client;
  final CacheService _cacheService = CacheService();
  final WeatherAlertService _alertService = WeatherAlertService();
  final CropAdviceService _cropAdviceService = CropAdviceService();

  /// Get current location permission and coordinates
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Get OpenWeatherMap API key from Supabase
  Future<String> _getApiKey() async {
    try {
      final response = await _client
          .from('secrets')
          .select('key_value')
          .eq('key_name', 'openweather_api_key')
          .single();  // Ensures only one row is fetched

      if (response == null || response['key_value'] == null) {
        throw Exception('API key not found in Supabase.');
      }

      return response['key_value'];
    } catch (e) {
      print('Error getting API key: $e');
      throw Exception('Failed to get API key');
    }
  }

  /// Get current weather data by coordinates
  Future<Map<String, dynamic>> getCurrentWeather(
      double latitude, double longitude) async {
    final apiKey = await _getApiKey();
    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&units=metric&appid=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Save to Supabase
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        await _client.from('weather_data').upsert({
          'user_id': userId,
          'location': data['name'],
          'latitude': latitude,
          'longitude': longitude,
          'current_weather': data,
        });
      }

      return {
        'temperature': data['main']['temp'].round(),
        'feelsLike': data['main']['feels_like']?.round() ?? data['main']['temp'].round(), 
        'condition': data['weather'][0]['main'],
        'description': data['weather'][0]['description'],
        'humidity': data['main']['humidity'],
        'windSpeed': data['wind']['speed'].round(),
        'precipitation': 0, // OpenWeatherMap doesn't provide this directly
        'pressure': data['main']['pressure'],
        'visibility':
            (data['visibility'] / 1000).round(), // Convert meters to kilometers
        'uvIndex': 0, // Not available in basic API
        'icon': _getWeatherIcon(data['weather'][0]['icon']),
      };
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  /// Get hourly forecast (using free 5-day/3-hour forecast API)
  Future<List<Map<String, dynamic>>> getHourlyForecast(
      double latitude, double longitude) async {
    final apiKey = await _getApiKey();
    final url =
        'https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&units=metric&appid=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> forecastList = data['list'];
      
      // Extract hourly forecast for the next 24 hours (8 intervals at 3 hours each)
      return forecastList.take(8).map<Map<String, dynamic>>((item) {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
        return {
          'hour': DateFormat('HH:mm').format(dateTime),
          'temperature': item['main']['temp'].round(),
          'condition': item['weather'][0]['main'],
          'icon': _getWeatherIcon(item['weather'][0]['icon']),
        };
      }).toList();
    } else {
      throw Exception('Failed to load forecast data');
    }
  }

  /// Get 5-day forecast using free forecast API
  Future<List<Map<String, dynamic>>> getDailyForecast(
      double latitude, double longitude) async {
    final apiKey = await _getApiKey();
    final url =
        'https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&units=metric&appid=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> forecastList = data['list'];
      
      // Extract daily forecast by grouping 3-hour forecasts by day
      final Map<String, List<dynamic>> dailyForecastMap = {};
      for (final forecast in forecastList) {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
        final day = DateFormat('yyyy-MM-dd').format(dateTime);
        
        if (!dailyForecastMap.containsKey(day)) {
          dailyForecastMap[day] = [];
        }
        dailyForecastMap[day]!.add(forecast);
      }
      
      // Consolidate daily forecasts (average of 3-hour forecasts for each day)
      final List<Map<String, dynamic>> dailyForecast = [];
      dailyForecastMap.forEach((day, forecasts) {
        double tempSum = 0;
        double tempMinSum = 0;
        double tempMaxSum = 0;
        String commonCondition = '';
        Map<String, int> conditionCount = {};
        
        for (final forecast in forecasts) {
          tempSum += forecast['main']['temp'];
          tempMinSum += forecast['main']['temp_min'];
          tempMaxSum += forecast['main']['temp_max'];
          
          final condition = forecast['weather'][0]['main'];
          conditionCount[condition] = (conditionCount[condition] ?? 0) + 1;
        }
        
        // Find most common weather condition
        int maxCount = 0;
        conditionCount.forEach((condition, count) {
          if (count > maxCount) {
            maxCount = count;
            commonCondition = condition;
          }
        });
        
        final count = forecasts.length;
        final dateTime = DateTime.fromMillisecondsSinceEpoch(forecasts[0]['dt'] * 1000);
        
        dailyForecast.add({
          'day': DateFormat('EEE').format(dateTime),
          'date': DateFormat('MMM d').format(dateTime),
          'temperature': (tempSum / count).round(),
          'tempMin': (tempMinSum / count).round(),
          'tempMax': (tempMaxSum / count).round(),
          'condition': commonCondition,
          'icon': _getWeatherIcon(forecasts[0]['weather'][0]['icon']),
        });
      });
      
      // Only return first 5 days
      return dailyForecast.take(5).toList();
    } else {
      throw Exception('Failed to load daily forecast data');
    }
  }

  /// Get city name from coordinates
  Future<String> getCityName(double latitude, double longitude) async {
    final apiKey = await _getApiKey();
    final response = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['name'];
    } else {
      return 'Unknown Location';
    }
  }

  /// Get farming advice from Supabase or generate based on weather
  Future<List<Map<String, dynamic>>> getFarmingAdvice(
      Map<String, dynamic> currentWeather) async {
    try {
      final String condition = currentWeather['condition'] ?? '';
      final List<Map<String, dynamic>> allAdvice = [];
      
      // Get current season for more specific advice
      final now = DateTime.now();
      final String season;
      if (now.month >= 6 && now.month <= 9) {
        season = 'monsoon';
      } else if (now.month >= 10 && now.month <= 11) {
        season = 'post-monsoon';
      } else if (now.month >= 12 || now.month <= 2) {
        season = 'winter';
      } else {
        season = 'summer';
      }
      
      // Query Supabase for general advice based on current conditions
      final generalResponse = await _client
          .from('farming_advice')
          .select()
          .eq('crop_type', 'general')
          .eq('weather_condition', condition)
          .or('season.is.null,season.eq.$season')
          .order('created_at', ascending: false)
          .limit(2);
      
      // Convert general advice to our format
      if (generalResponse.isNotEmpty) {
        allAdvice.addAll(List<Map<String, dynamic>>.from(generalResponse.map((item) {
          return {
            'crop': 'General',
            'advice': item['advice_description'],
            'iconName': item['icon_name'],
            'color': item['color_hex'],
            'region': item['region'] ?? 'Maharashtra',
            'currentStage': item['growth_stage'] ?? '',
            'title': item['advice_title'],
          };
        })));
      }
      
      // Get user's selected crops for crop-specific advice
      // Force refresh to get latest crop selections
      final userCrops = await _cropAdviceService.getUserCrops(forceRefresh: true);
      
      // Get crop-specific advice using cropAdviceService
      // This will handle fetching from database and fallback to generated advice
      final cropSpecificAdvice = await _cropAdviceService.getCropSpecificAdvice(
        currentWeather,
        specificCrops: userCrops
      );
      
      // Add crop-specific advice to our list
      if (cropSpecificAdvice.isNotEmpty) {
        allAdvice.addAll(cropSpecificAdvice);
      }
      
      // If we have no advice at all, generate fallback advice
      if (allAdvice.isEmpty) {
        return _generateAdvice(currentWeather);
      }
      
      return allAdvice;
    } catch (e) {
      print('Error getting farming advice: $e');
      return _generateAdvice(currentWeather);
    }
  }

  /// Generate advice based on weather conditions (fallback when no database advice is found)
  List<Map<String, dynamic>> _generateAdvice(Map<String, dynamic> currentWeather) {
    final List<Map<String, dynamic>> advice = [];
    final String condition = currentWeather['condition'] ?? '';
    final int temp = currentWeather['temperature'] ?? 25;
    final int humidity = currentWeather['humidity'] ?? 60;

    // Add advice based on current conditions
    if (condition == 'Clear' || condition == 'Sunny') {
      advice.add({
        'crop': 'General',
        'title': 'Good for Field Work',
        'advice':
            'Current sunny conditions are ideal for field work and harvesting. Take advantage of clear weather for agricultural operations that require dry conditions.',
        'iconName': 'wb_sunny',
        'color': '#FFA500', // Orange
        'region': 'Maharashtra',
      });

      if (temp > 30) {
        advice.add({
          'crop': 'General',
          'title': 'Water Conservation',
          'advice':
              'High temperatures can cause moisture stress in crops. Ensure adequate irrigation, preferably in early morning or evening. Consider mulching to retain soil moisture and reduce evaporation.',
          'iconName': 'water_drop',
          'color': '#2196F3', // Blue
          'region': 'Maharashtra',
        });
      }
    } else if (condition.contains('Rain') || condition.contains('Drizzle')) {
      advice.add({
        'crop': 'General',
        'title': 'Postpone Field Activities',
        'advice':
            'Rain expected. Postpone fertilizer application and harvesting. Ensure proper drainage in low-lying areas to prevent waterlogging which can damage crop roots.',
        'iconName': 'grain',
        'color': '#2196F3', // Blue
        'region': 'Maharashtra',
      });
    } else if (condition.contains('Thunderstorm')) {
      advice.add({
        'crop': 'General',
        'title': 'Weather Alert',
        'advice':
            'Thunderstorms expected. Secure livestock and equipment, avoid field work. Check for crop damage after storms and provide support to damaged plants if possible.',
        'iconName': 'warning_amber',
        'color': '#FFA500', // Orange
        'region': 'Maharashtra',
      });
    }

    // Check humidity levels
    if (humidity > 80) {
      advice.add({
        'crop': 'General',
        'title': 'Disease Alert',
        'advice':
            'High humidity. Monitor crops for fungal diseases and consider preventative spraying. Improve air circulation around plants where possible to reduce disease pressure.',
        'iconName': 'bug_report',
        'color': '#F44336', // Red
        'region': 'Maharashtra',
      });
    } else if (humidity < 30) {
      advice.add({
        'crop': 'General',
        'title': 'Low Humidity Alert',
        'advice':
            'Very dry conditions. Increase irrigation frequency and consider evening watering to reduce evaporation. Monitor for signs of water stress in crops.',
        'iconName': 'water',
        'color': '#2196F3', // Blue
        'region': 'Maharashtra',
      });
    }

    return advice;
  }

  /// Convert weather icon code to SVG icon path
  String _getWeatherIcon(String iconCode) {
    // Map OpenWeatherMap icon codes to our SVG assets
    switch (iconCode) {
      case '01d':
        return 'assets/icons/weather/clear_day.svg';
      case '01n':
        return 'assets/icons/weather/clear_night.png';
      case '02d':
        return 'assets/icons/weather/partly_cloudy_day.svg';
      case '02n':
        return 'assets/icons/weather/cloudy.svg';
      case '03d':
      case '03n':
      case '04d':
      case '04n':
        return 'assets/icons/weather/cloudy.svg';
      case '09d':
      case '09n':
        return 'assets/icons/weather/rain.svg';
      case '10d':
      case '10n':
        return 'assets/icons/weather/rain.svg';
      case '11d':
      case '11n':
        return 'assets/icons/weather/thunderstorm.svg';
      case '13d':
      case '13n':
        return 'assets/icons/weather/snow.svg';
      case '50d':
      case '50n':
        return 'assets/icons/weather/mist.svg';
      default:
        return 'assets/icons/weather/clear_day.svg';
    }
  }

  /// Get all weather data in one call
  Future<Map<String, dynamic>> getAllWeatherData() async {
    try {
      // Try to get cached data first
      final cachedData = await _cacheService.getCachedWeatherData();
      if (cachedData != null) {
        // Check for alerts in cached data
        await _alertService.checkForAlerts(cachedData);
        
        // Always get fresh farming advice even with cached weather data
        final currentWeather = cachedData['currentWeather'];
        final genericAdvice = await getFarmingAdvice(currentWeather);
        final cropSpecificAdvice = await _cropAdviceService.getCropSpecificAdvice(currentWeather);
        
        // Update advice in cached data
        cachedData['farmingAdvice'] = [...genericAdvice, ...cropSpecificAdvice];
        
        return cachedData;
      }

      // If no cached data, fetch fresh data
      final position = await _getCurrentLocation();
      final weatherData = await _getWeatherDataByCoordinates(
          position.latitude, position.longitude);

      // Cache the new data
      await _cacheService.cacheWeatherData(weatherData);

      // Check for weather alerts
      await _alertService.checkForAlerts(weatherData);

      return weatherData;
    } catch (e) {
      print('Error fetching weather data: $e');
      throw Exception('Failed to fetch weather data: $e');
    }
  }

  /// Get weather data by coordinates - internal method
  Future<Map<String, dynamic>> _getWeatherDataByCoordinates(
      double latitude, double longitude) async {
    final city = await getCityName(latitude, longitude);
    final currentWeather = await getCurrentWeather(latitude, longitude);
    final hourlyForecast = await getHourlyForecast(latitude, longitude);
    final dailyForecast = await getDailyForecast(latitude, longitude);

    // Get farming advice - now with crop-specific advice
    final genericAdvice = await getFarmingAdvice(currentWeather);
    final cropSpecificAdvice =
        await _cropAdviceService.getCropSpecificAdvice(currentWeather);

    // Combine both types of advice
    final List<Map<String, dynamic>> combinedAdvice = [
      ...genericAdvice,
      ...cropSpecificAdvice,
    ];

    return {
      'location': city,
      'coordinates': {'latitude': latitude, 'longitude': longitude},
      'currentWeather': currentWeather,
      'hourlyForecast': hourlyForecast,
      'forecast': dailyForecast,
      'farmingAdvice': combinedAdvice,
    };
  }

  /// Search for a location and get weather data
  Future<Map<String, dynamic>> searchLocationWeather(String query) async {
    try {
      // Check if we have cached data for this location
      final cachedData =
          await _cacheService.getCachedLocationWeatherData(query);
      if (cachedData != null) {
        return cachedData;
      }

      // If no cached data, geocode the location
      final locations = await locationFromAddress(query);

      if (locations.isEmpty) {
        throw Exception('Location not found');
      }

      // Use the first result
      final location = locations.first;

      // Get weather data for this location
      final weatherData = await _getWeatherDataByCoordinates(
        location.latitude,
        location.longitude,
      );

      // Cache the data with location name
      await _cacheService.cacheLocationWeatherData(query, weatherData);

      return weatherData;
    } catch (e) {
      print('Error searching location: $e');
      throw Exception('Failed to find weather for location: $e');
    }
  }

  /// Get recently searched locations
  Future<List<String>> getRecentLocations() async {
    return await _cacheService.getRecentLocations();
  }

  /// Clear weather cache to force a fresh data fetch
  Future<void> clearWeatherCache() async {
    // Use the existing clearCache method from CacheService 
    await _cacheService.clearCache();
  }

  /// Clear weather cache
  Future<void> clearCache() async {
    await _cacheService.clearCache();
  }

  /// Get weather alerts
  Future<List<Map<String, dynamic>>> getWeatherAlerts() async {
    return await _alertService.getSavedAlerts();
  }

  /// Enable or disable weather alerts
  Future<void> setWeatherAlertsEnabled(bool enabled) async {
    await _alertService.setAlertsEnabled(enabled);
  }

  /// Get a list of all available crop types
  List<String> getAllCropTypes() {
    return _cropAdviceService.getAllCropTypes();
  }

  /// Get user's saved crops
  Future<List<String>> getUserCrops() async {
    return await _cropAdviceService.getUserCrops();
  }

  /// Save user's crop selections
  Future<void> saveUserCrops(List<String> crops) async {
    await _cropAdviceService.saveUserCrops(crops);
  }

  /// Get crop-specific advice only
  Future<List<Map<String, dynamic>>> getCropAdvice(
      Map<String, dynamic> currentWeather) async {
    return await _cropAdviceService.getCropSpecificAdvice(currentWeather);
  }
}
