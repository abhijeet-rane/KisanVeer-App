import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/services/weather_service.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({Key? key}) : super(key: key);

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final WeatherService _weatherService = WeatherService();
  List<String> _recentSearches = [];
  List<String> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recentLocations = await _weatherService.getRecentLocations();
      setState(() {
        _recentSearches = recentLocations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recent searches: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      List<String> suggestions = await _getSuggestions(query);
      setState(() {
        _searchResults = suggestions;
        _isSearching = false;
      });
    } catch (e) {
      print('Error performing search: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<List<String>> _getSuggestions(String query) async {
    if (query.length < 3) return [];
    
    try {
      List<Location> locations = await locationFromAddress(query);
      
      if (locations.isEmpty) return [];
      
      // Get locations and format them
      List<String> suggestions = [];
      for (var location in locations.take(5)) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude, 
          location.longitude
        );
        
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          String formattedAddress = '';
          
          if (place.locality != null && place.locality!.isNotEmpty) {
            formattedAddress += place.locality!;
          }
          
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            if (formattedAddress.isNotEmpty) formattedAddress += ', ';
            formattedAddress += place.administrativeArea!;
          }
          
          if (place.country != null && place.country!.isNotEmpty) {
            if (formattedAddress.isNotEmpty) formattedAddress += ', ';
            formattedAddress += place.country!;
          }
          
          if (formattedAddress.isNotEmpty) {
            suggestions.add(formattedAddress);
          }
        }
      }
      
      return suggestions;
    } catch (e) {
      print('Error getting suggestions: $e');
      return [];
    }
  }

  void _onLocationSelected(String location) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      final weatherData = await _weatherService.searchLocationWeather(location);
      // Pop the loading dialog
      Navigator.pop(context);
      // Return the weather data to the calling screen
      Navigator.pop(context, weatherData);
    } catch (e) {
      // Pop the loading dialog
      Navigator.pop(context);
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching weather data: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Try Again',
            onPressed: () => _onLocationSelected(location),
            textColor: Colors.white,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Location'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a location',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
              ),
              style: AppTextStyles.bodyMedium,
              onChanged: (value) {
                _performSearch(value);
              },
            ),
          ),
          
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            
          if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(_searchResults[index]),
                    onTap: () => _onLocationSelected(_searchResults[index]),
                  );
                },
              ),
            )
          else if (!_isSearching && _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No locations found. Try a different search term.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else if (_recentSearches.isNotEmpty && _searchController.text.isEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Recent Searches',
                      style: AppTextStyles.h3,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _recentSearches.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(_recentSearches[index]),
                          onTap: () => _onLocationSelected(_recentSearches[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          else if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: Center(
                child: Text(
                  'No recent searches',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
