import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/constants/svg_images.dart';
import 'package:kisan_veer/widgets/forecast_card.dart';
import 'package:kisan_veer/widgets/hour_forecast.dart';
import 'package:kisan_veer/services/weather_service.dart';
import 'package:kisan_veer/screens/weather/location_search_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/notifications_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  bool _isLoading = false;
  Map<String, dynamic>? _weatherData;
  List<String> _alerts = [];
  List<String> _userCrops = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
    NotificationsService.showWelcomeNotification();
  }

  Future<void> _loadUserCrops() async {
    try {
      final crops = await _weatherService.getUserCrops();
      setState(() {
        _userCrops = crops;
      });
    } catch (e) {
      print('Error loading user crops: $e');
    }
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final weatherData = await _weatherService.getAllWeatherData();
      setState(() {
        _weatherData = weatherData;
        _isLoading = false;
        _errorMessage = null;

        // Check for any alerts in the weather data
        _loadAlerts();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;

        // Set appropriate error message based on the error type
        if (e.toString().contains('Location services are disabled')) {
          _errorMessage = 'locationDisabled';
        } else if (e.toString().contains('Location permissions are denied')) {
          _errorMessage = 'permissionDenied';
        } else if (e.toString().contains('permanently denied')) {
          _errorMessage = 'permissionPermanentlyDenied';
        } else {
          _errorMessage = 'other';
        }
      });
      print('Error fetching weather data: $e');
    }
  }

  Future<void> _loadAlerts() async {
    try {
      final alerts = await _weatherService.getWeatherAlerts();
      // Get just the messages from alerts
      final alertMessages = alerts.map((a) => a['message'] as String).toList();
      setState(() {
        _alerts = alertMessages;
      });
    } catch (e) {
      print('Error loading alerts: $e');
    }
  }

  Future<void> _searchLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationSearchScreen(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _weatherData = result;

        // Also load alerts for the new location
        _loadAlerts();
      });
    }
  }

  Future<void> _refreshWeatherData() async {
    // Clear cache and reload fresh data
    await _weatherService.clearCache();
    await _loadWeatherData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Weather data refreshed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showCropSelectionDialog() async {
    final availableCrops = _weatherService.getAllCropTypes();
    final selectedCrops = List<String>.from(_userCrops);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Your Crops'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: availableCrops.length,
            itemBuilder: (context, index) {
              final crop = availableCrops[index];
              return CheckboxListTile(
                title: Text(crop[0].toUpperCase() + crop.substring(1)),
                value: selectedCrops.contains(crop),
                onChanged: (bool? value) {
                  if (value == true) {
                    selectedCrops.add(crop);
                  } else {
                    selectedCrops.remove(crop);
                  }
                  // Rebuild the dialog
                  (context as Element).markNeedsBuild();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Save the selected crops
              await _weatherService.saveUserCrops(selectedCrops);
              setState(() {
                _userCrops = selectedCrops;
                _isLoading = true; // Show loading indicator while refreshing
              });

              // Completely reload weather data and force a refresh of crop advice
              await _weatherService
                  .clearWeatherCache(); // Add this method to WeatherService
              await _loadWeatherData();

              // Show confirmation to the user
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Crop selections updated'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationHeader() {
    final location = _weatherData?['location'] ?? 'Unknown Location';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on,
                  size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                location,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _searchLocation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.lightBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Change',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    if (_alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        // Show all alerts in a dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Weather Alerts'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: _alerts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading:
                        const Icon(Icons.warning_amber, color: Colors.orange),
                    title: Text(_alerts[index]),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16.0),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                const Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _alerts.first, // Show first alert in the banner
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            if (_alerts.length > 1)
              Text(
                '+${_alerts.length - 1} more alerts',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
          backgroundColor: Colors.white,
          body: const Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage == 'locationDisabled'
                    ? 'Location services are disabled. Please enable location services to view weather data.'
                    : _errorMessage == 'permissionDenied'
                        ? 'Location permission denied. Please grant location permission to view weather data.'
                        : _errorMessage == 'permissionPermanentlyDenied'
                            ? 'Location permission permanently denied. Please enable it in settings.'
                            : 'Failed to load weather data. Please try again.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_errorMessage == 'locationDisabled') {
                    await Geolocator.openLocationSettings();
                  } else if (_errorMessage == 'permissionDenied') {
                    await Geolocator.requestPermission();
                  } else if (_errorMessage == 'permissionPermanentlyDenied') {
                    await Geolocator.openAppSettings();
                  }
                  _loadWeatherData();
                },
                child: Text(
                  _errorMessage == 'locationDisabled'
                      ? 'Open Settings'
                      : _errorMessage == 'permissionDenied'
                          ? 'Grant Permission'
                          : _errorMessage == 'permissionPermanentlyDenied'
                              ? 'Open App Settings'
                              : 'Try Again',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_weatherData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: Text('No weather data available'),
        ),
      );
    }

    final currentWeather = _weatherData!['currentWeather'];
    final hourlyForecast = _weatherData!['hourlyForecast'];
    final forecast = _weatherData!['forecast'];

    return Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          onRefresh: _refreshWeatherData,
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildLocationHeader(),

                  if (_alerts.isNotEmpty) _buildAlertBanner(),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade400,
                          Colors.blue.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade300.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date and Location
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('EEEE, MMM d').format(DateTime.now()),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Temperature and Condition
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${currentWeather['temperature']}°',
                                  style: AppTextStyles.h1.copyWith(
                                    color: Colors.white,
                                    fontSize: 54,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  currentWeather['condition'],
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Feels Like
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    'Feels like ${currentWeather['feelsLike']}°',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),

                            // Weather Icon
                            SvgPicture.asset(
                              _getWeatherIcon(currentWeather['condition']),
                              height: 90,
                              width: 90,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Weather Details with Icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildWeatherDetail('💨 Wind', '${currentWeather['windSpeed']} km/h'),
                            _buildWeatherDetail('💧 Humidity', '${currentWeather['humidity']}%'),
                            _buildWeatherDetail('🔆 UV Index', _getUVIndexDescription(currentWeather['uvIndex'])),
                          ],
                        ),
                      ],
                    ),
                  ),


                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Hourly Forecast',
                      style: AppTextStyles.h3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: hourlyForecast.length,
                      itemBuilder: (context, index) {
                        final hour = hourlyForecast[index];
                        return HourForecast(
                          time: hour['hour'],
                          temperature: '${hour['temperature']}°',
                          icon: hour['icon'],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '5-Day Forecast',
                      style: AppTextStyles.h3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: forecast.length,
                    itemBuilder: (context, index) {
                      final day = forecast[index];
                      return ForecastCard(
                        day: '${day['day']}, ${day['date']}',
                        condition: day['condition'],
                        minTemp: '${day['tempMin']}°',
                        maxTemp: '${day['tempMax']}°',
                        icon: day['icon'],
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildWeatherDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getUVIndexDescription(int uvIndex) {
    if (uvIndex <= 2) {
      return 'Low';
    } else if (uvIndex <= 5) {
      return 'Moderate';
    } else if (uvIndex <= 7) {
      return 'High';
    } else if (uvIndex <= 10) {
      return 'Very High';
    } else {
      return 'Extreme';
    }
  }

  String _getWeatherIcon(String condition) {
    // Convert condition to lowercase for easier matching
    final lowerCondition = condition.toLowerCase();

    if (lowerCondition.contains('rain') ||
        lowerCondition.contains('drizzle') ||
        lowerCondition.contains('shower')) {
      return SvgImages.rain;
    } else if (lowerCondition.contains('thunderstorm')) {
      return SvgImages.thunderstorm;
    } else if (lowerCondition.contains('snow')) {
      return SvgImages.snow;
    } else if (lowerCondition.contains('mist') ||
        lowerCondition.contains('fog')) {
      return SvgImages.mist;
    } else if (lowerCondition.contains('clear') ||
        lowerCondition.contains('sunny')) {
      return SvgImages.clearDay;
    } else if (lowerCondition.contains('cloud')) {
      if (lowerCondition.contains('broken') ||
          lowerCondition.contains('scattered')) {
        return SvgImages.partlyCloudyDay;
      } else {
        return SvgImages.cloudy;
      }
    }

    // Default to cloudy if no condition matches
    return SvgImages.cloudy;
  }

  // Handle location permission requests
  Future<void> _handleLocationRequest() async {
    if (_errorMessage == 'locationDisabled') {
      // Open location settings
      await Geolocator.openLocationSettings();
      // Check if location is enabled after returning from settings
      await _loadWeatherData();
    } else if (_errorMessage == 'permissionDenied') {
      // Request permission again
      final permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.denied) {
        await _loadWeatherData();
      }
    } else if (_errorMessage == 'permissionPermanentlyDenied') {
      // Open app settings to allow user to enable permissions
      await Geolocator.openAppSettings();
      // Check if permission granted after returning from settings
      await _loadWeatherData();
    } else {
      // General retry
      await _loadWeatherData();
    }
  }
}
