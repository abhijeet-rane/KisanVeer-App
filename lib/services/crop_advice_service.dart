import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CropAdviceService {
  final SupabaseClient _client = Supabase.instance.client;
  
  // A map of crop types to their preferences for different weather conditions
  static final Map<String, Map<String, dynamic>> _cropPreferences = {
    // Common crops in Maharashtra
    'wheat': {
      'optimalTemperature': {'min': 15, 'max': 25},
      'optimalHumidity': {'min': 40, 'max': 70},
      'waterRequirement': 'moderate',
      'sensitiveToRain': false,
      'sensitiveToFrost': true,
      'sensitiveToHeat': true,
      'growingSeason': ['winter', 'spring'],
      'growthStages': ['germination', 'tillering', 'jointing', 'booting', 'heading', 'ripening'],
      'plantingMonths': ['October', 'November', 'December'],
      'harvestMonths': ['March', 'April'],
      'region': 'Maharashtra',
    },
    'rice': {
      'optimalTemperature': {'min': 20, 'max': 35},
      'optimalHumidity': {'min': 60, 'max': 90},
      'waterRequirement': 'high',
      'sensitiveToRain': false,
      'sensitiveToFrost': true,
      'sensitiveToHeat': false,
      'growingSeason': ['monsoon', 'summer'],
      'growthStages': ['germination', 'seedling', 'tillering', 'panicle initiation', 'flowering', 'maturity'],
      'plantingMonths': ['June', 'July', 'December', 'January'],
      'harvestMonths': ['November', 'December', 'April', 'May'],
      'region': 'Konkan and Eastern Maharashtra',
    },
    'cotton': {
      'optimalTemperature': {'min': 25, 'max': 35},
      'optimalHumidity': {'min': 40, 'max': 70},
      'waterRequirement': 'moderate',
      'sensitiveToRain': true,
      'sensitiveToFrost': true,
      'sensitiveToHeat': false,
      'growingSeason': ['summer', 'monsoon'],
      'growthStages': ['germination', 'seedling', 'squaring', 'flowering', 'boll development', 'maturity'],
      'plantingMonths': ['May', 'June', 'July'],
      'harvestMonths': ['November', 'December', 'January'],
      'region': 'Vidarbha and Marathwada',
    },
    'sugarcane': {
      'optimalTemperature': {'min': 20, 'max': 35},
      'optimalHumidity': {'min': 50, 'max': 85},
      'waterRequirement': 'high',
      'sensitiveToRain': false,
      'sensitiveToFrost': true,
      'sensitiveToHeat': false,
      'growingSeason': ['summer', 'monsoon'],
      'growthStages': ['germination', 'tillering', 'grand growth', 'maturation'],
      'plantingMonths': ['January', 'February', 'October', 'November'],
      'harvestMonths': ['November', 'December', 'January', 'February', 'March'],
      'region': 'Western Maharashtra',
    },
    'maize': {
      'optimalTemperature': {'min': 18, 'max': 32},
      'optimalHumidity': {'min': 40, 'max': 80},
      'waterRequirement': 'moderate',
      'sensitiveToRain': true,
      'sensitiveToFrost': true,
      'sensitiveToHeat': true,
      'growingSeason': ['summer', 'monsoon'],
      'growthStages': ['germination', 'vegetative', 'tasseling', 'silking', 'grain filling', 'maturity'],
      'plantingMonths': ['June', 'July', 'February', 'March'],
      'harvestMonths': ['September', 'October', 'May', 'June'],
      'region': 'Central Maharashtra',
    },
    // Additional Maharashtra-specific crops
    'soybean': {
      'optimalTemperature': {'min': 20, 'max': 30},
      'optimalHumidity': {'min': 40, 'max': 85},
      'waterRequirement': 'moderate',
      'sensitiveToRain': true,
      'sensitiveToFrost': true,
      'sensitiveToHeat': true,
      'growingSeason': ['monsoon'],
      'growthStages': ['germination', 'vegetative', 'flowering', 'pod development', 'maturation'],
      'plantingMonths': ['June', 'July'],
      'harvestMonths': ['October', 'November'],
      'region': 'Vidarbha and Marathwada',
    },
    'tur dal': {
      'optimalTemperature': {'min': 20, 'max': 32},
      'optimalHumidity': {'min': 40, 'max': 70},
      'waterRequirement': 'low',
      'sensitiveToRain': true,
      'sensitiveToFrost': true,
      'sensitiveToHeat': false,
      'growingSeason': ['monsoon'],
      'growthStages': ['germination', 'vegetative', 'flowering', 'pod formation', 'maturation'],
      'plantingMonths': ['June', 'July'],
      'harvestMonths': ['December', 'January', 'February'],
      'region': 'Marathwada and Vidarbha',
    },
    'groundnut': {
      'optimalTemperature': {'min': 25, 'max': 35},
      'optimalHumidity': {'min': 40, 'max': 75},
      'waterRequirement': 'moderate',
      'sensitiveToRain': false,
      'sensitiveToFrost': true,
      'sensitiveToHeat': false,
      'growingSeason': ['monsoon', 'summer'],
      'growthStages': ['germination', 'pegging', 'pod development', 'kernel development', 'maturation'],
      'plantingMonths': ['June', 'July', 'January', 'February'],
      'harvestMonths': ['October', 'November', 'May', 'June'],
      'region': 'Western Maharashtra and Vidarbha',
    },
    'jowar': {
      'optimalTemperature': {'min': 25, 'max': 32},
      'optimalHumidity': {'min': 40, 'max': 70},
      'waterRequirement': 'low',
      'sensitiveToRain': false,
      'sensitiveToFrost': true,
      'sensitiveToHeat': false,
      'growingSeason': ['monsoon', 'winter'],
      'growthStages': ['germination', 'vegetative', 'flowering', 'grain filling', 'maturation'],
      'plantingMonths': ['June', 'July', 'October', 'November'],
      'harvestMonths': ['October', 'November', 'February', 'March'],
      'region': 'Marathwada and Western Maharashtra',
    },
    'bajra': {
      'optimalTemperature': {'min': 25, 'max': 35},
      'optimalHumidity': {'min': 30, 'max': 60},
      'waterRequirement': 'low',
      'sensitiveToRain': false,
      'sensitiveToFrost': true,
      'sensitiveToHeat': false,
      'growingSeason': ['monsoon'],
      'growthStages': ['germination', 'tillering', 'panicle initiation', 'flowering', 'grain filling', 'maturity'],
      'plantingMonths': ['June', 'July'],
      'harvestMonths': ['September', 'October'],
      'region': 'Drought-prone areas of Maharashtra',
    },
    'onion': {
      'optimalTemperature': {'min': 15, 'max': 25},
      'optimalHumidity': {'min': 50, 'max': 70},
      'waterRequirement': 'moderate',
      'sensitiveToRain': true,
      'sensitiveToFrost': false,
      'sensitiveToHeat': true,
      'growingSeason': ['winter', 'summer'],
      'growthStages': ['germination', 'leaf development', 'bulb formation', 'bulb development', 'maturation'],
      'plantingMonths': ['October', 'November', 'January', 'February'],
      'harvestMonths': ['February', 'March', 'April', 'May'],
      'region': 'Nashik and Western Maharashtra',
    },
    'tomato': {
      'optimalTemperature': {'min': 20, 'max': 30},
      'optimalHumidity': {'min': 50, 'max': 75},
      'waterRequirement': 'moderate',
      'sensitiveToRain': true,
      'sensitiveToFrost': true,
      'sensitiveToHeat': true,
      'growingSeason': ['winter', 'summer'],
      'growthStages': ['germination', 'vegetative', 'flowering', 'fruit development', 'ripening'],
      'plantingMonths': ['June', 'July', 'October', 'November'],
      'harvestMonths': ['October', 'November', 'February', 'March', 'April'],
      'region': 'Pune and Western Maharashtra',
    },
    'brinjal': {
      'optimalTemperature': {'min': 20, 'max': 32},
      'optimalHumidity': {'min': 50, 'max': 80},
      'waterRequirement': 'moderate',
      'sensitiveToRain': true,
      'sensitiveToFrost': true,
      'sensitiveToHeat': false,
      'growingSeason': ['summer', 'monsoon'],
      'growthStages': ['germination', 'vegetative', 'flowering', 'fruit development', 'harvesting'],
      'plantingMonths': ['May', 'June', 'September', 'October'],
      'harvestMonths': ['August', 'September', 'January', 'February'],
      'region': 'Throughout Maharashtra',
    },
    'grapes': {
      'optimalTemperature': {'min': 15, 'max': 35},
      'optimalHumidity': {'min': 40, 'max': 70},
      'waterRequirement': 'moderate',
      'sensitiveToRain': true,
      'sensitiveToFrost': true,
      'sensitiveToHeat': false,
      'growingSeason': ['winter', 'summer'],
      'growthStages': ['dormancy', 'bud break', 'flowering', 'fruit set', 'veraison', 'ripening'],
      'plantingMonths': ['January', 'February'],
      'harvestMonths': ['April', 'May', 'June'],
      'region': 'Nashik and Sangli',
    },
    'orange': {
      'optimalTemperature': {'min': 15, 'max': 35},
      'optimalHumidity': {'min': 40, 'max': 70},
      'waterRequirement': 'moderate',
      'sensitiveToRain': false,
      'sensitiveToFrost': true,
      'sensitiveToHeat': false,
      'growingSeason': ['winter', 'summer'],
      'growthStages': ['flowering', 'fruit set', 'fruit development', 'ripening'],
      'plantingMonths': ['July', 'August'],
      'harvestMonths': ['November', 'December', 'January'],
      'region': 'Vidarbha (Nagpur region)',
    },
    'pomegranate': {
      'optimalTemperature': {'min': 20, 'max': 35},
      'optimalHumidity': {'min': 30, 'max': 60},
      'waterRequirement': 'low',
      'sensitiveToRain': true,
      'sensitiveToFrost': true,
      'sensitiveToHeat': false,
      'growingSeason': ['monsoon', 'winter'],
      'growthStages': ['vegetative', 'flowering', 'fruit development', 'maturation'],
      'plantingMonths': ['July', 'August', 'January', 'February'],
      'harvestMonths': ['February', 'March', 'September', 'October'],
      'region': 'Solapur and Sangli',
    },
  };

  // Get user's saved crops from Supabase
  Future<List<String>> getUserCrops({bool forceRefresh = false}) async {
    try {
      // Return cached crops if available and no force refresh is requested
      if (!forceRefresh && _userCropsCache != null) {
        return _userCropsCache!;
      }
      
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        _userCropsCache = _getDefaultCrops();
        return _userCropsCache!;
      }
      
      try {
        final response = await _client
            .from('user_preferences')
            .select('crops')
            .eq('user_id', userId)
            .single();
        
        if (response['crops'] != null) {
          final crops = List<String>.from(response['crops']);
          // Cache the crops for faster access
          _userCropsCache = crops;
          return crops;
        }
      } catch (e) {
        // If no row exists or any other error occurs, create default preferences
        final defaultCrops = _getDefaultCrops();
        await saveUserCrops(defaultCrops);
        _userCropsCache = defaultCrops;
        return defaultCrops;
      }
      
      final defaultCrops = _getDefaultCrops();
      _userCropsCache = defaultCrops;
      return defaultCrops;
    } catch (e) {
      print('Error getting user crops: $e');
      final defaultCrops = _getDefaultCrops();
      _userCropsCache = defaultCrops;
      return defaultCrops;
    }
  }
  
  // Private cache for user crops to improve performance
  List<String>? _userCropsCache;
  
  // Get default crops if user hasn't selected any
  List<String> _getDefaultCrops() {
    return ['wheat', 'rice', 'vegetables'];
  }
  
  // Save user's crop selections to Supabase
  Future<void> saveUserCrops(List<String> crops) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      
      // Update the cache immediately
      _userCropsCache = List<String>.from(crops);
      
      await _client
          .from('user_preferences')
          .upsert({'user_id': userId, 'crops': crops})
          .select();
    } catch (e) {
      print('Error saving user crops: $e');
    }
  }
  
  // Get all available crop types
  List<String> getAllCropTypes() {
    return _cropPreferences.keys.toList();
  }
  
  // Get crop-specific advice based on current weather
  Future<List<Map<String, dynamic>>> getCropSpecificAdvice(
      Map<String, dynamic> currentWeather, 
      {List<String>? specificCrops}) async {
    
    // Get user's crops if not specified
    List<String> userCrops = specificCrops ?? [];
    if (userCrops.isEmpty) {
      try {
        userCrops = await getUserCrops();
      } catch (e) {
        print('Error getting user crops: $e');
        userCrops = ['wheat', 'rice']; // Default crops
      }
    }
    
    if (userCrops.isEmpty) {
      return [];
    }
    
    final String condition = currentWeather['condition'] ?? '';
    final int temperature = currentWeather['temperature'] ?? 25;
    final int humidity = currentWeather['humidity'] ?? 60;
    
    // Get current date for seasonal advice
    final DateTime now = DateTime.now();
    final String currentMonth = DateFormat('MMMM').format(now);
    final String season = _getSeason(now);
    
    List<Map<String, dynamic>> advice = [];
    
    // Try to fetch advice from Supabase database first
    try {
      // Create a query builder for multiple crop types using 'or' conditions
      String cropFilter = userCrops.map((crop) => 'crop_type.eq.$crop').join(',');
      
      // Query the Supabase farming_advice table
      final response = await _client
          .from('farming_advice')
          .select()
          .or(cropFilter)
          .eq('weather_condition', condition)
          .or('season.is.null,season.eq.$season')
          .order('created_at', ascending: false);
      
      if (response.isNotEmpty) {
        // Convert Supabase response to our standard advice format
        for (final item in response) {
          final cropType = item['crop_type'];
          
          // Only add advice for crops the user has selected
          if (userCrops.contains(cropType)) {
            advice.add({
              'crop': cropType[0].toUpperCase() + cropType.substring(1),
              'advice': item['advice_description'],
              'iconName': item['icon_name'] ?? 'grass',
              'color': item['color_hex'] ?? '#4CAF50',
              'region': item['region'] ?? 'Maharashtra',
              'currentStage': item['growth_stage'] ?? _estimateGrowthStage(cropType, currentMonth),
              'title': item['advice_title'],
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching crop advice from database: $e');
      // Continue to fallback generation if database fetch fails
    }
    
    // If we have advice from the database, return it
    if (advice.isNotEmpty) {
      return advice;
    }
    
    // Fallback: Generate advice programmatically if database doesn't have specific advice
    for (final crop in userCrops) {
      if (!_cropPreferences.containsKey(crop)) {
        continue;
      }
      
      final cropData = _cropPreferences[crop]!;
      final Map<String, dynamic> tempRange = cropData['optimalTemperature'];
      final Map<String, dynamic> humidityRange = cropData['optimalHumidity'];
      
      // Check if current month is in planting or harvesting season
      final List<String> plantingMonths = List<String>.from(cropData['plantingMonths'] ?? []);
      final List<String> harvestMonths = List<String>.from(cropData['harvestMonths'] ?? []);
      final List<String> growthStages = List<String>.from(cropData['growthStages'] ?? []);
      final String region = cropData['region'] ?? 'Maharashtra';
      
      // Initialize an advice string
      String adviceText = '';
      
      // Add crop growth stage info
      String currentStage = _estimateGrowthStage(crop, currentMonth);
      if (currentStage.isNotEmpty) {
        adviceText += "Current growth stage: $currentStage. ";
      }
      
      // Check if it's planting month
      if (plantingMonths.contains(currentMonth)) {
        adviceText += "Planting season for $crop in $region! Prepare your fields and ensure proper soil preparation. ";
      }
      
      // Check if it's harvesting month
      if (harvestMonths.contains(currentMonth)) {
        adviceText += "Harvesting season for $crop. Monitor maturity and plan harvest timing based on weather conditions. ";
      }
      
      // Add seasonal advice
      final List<String> growingSeason = List<String>.from(cropData['growingSeason'] ?? []);
      if (growingSeason.contains(season)) {
        adviceText += "Current $season season is suitable for $crop. ";
        
        // Add growth stage specific advice if available
        if (currentStage.isNotEmpty && growthStages.length > 1) {
          if (currentStage == growthStages.first) {
            adviceText += "Focus on proper establishment and early growth management. ";
          } else if (currentStage == growthStages.last) {
            adviceText += "Prepare for upcoming harvest and monitor maturity indicators. ";
          } else if (currentStage.contains('flower')) {
            adviceText += "Critical flowering period - ensure optimal conditions for good yield. ";
          }
        }
      } else if (growingSeason.isNotEmpty) {
        adviceText += "Current $season season is not ideal for $crop growth. Plan accordingly. ";
      }
      
      // Temperature advice
      if (temperature < tempRange['min']) {
        adviceText += "Temperature is below optimal range for $crop. ";
        if (cropData['sensitiveToFrost'] == true) {
          adviceText += "Protect plants from frost damage. Consider using mulch or row covers. ";
        }
      } else if (temperature > tempRange['max']) {
        adviceText += "Temperature is above optimal range for $crop. ";
        if (cropData['sensitiveToHeat'] == true) {
          adviceText += "Provide additional irrigation and avoid midday activities. ";
        }
      } else {
        adviceText += "Temperature is within optimal range for $crop. ";
      }
      
      // Humidity advice
      if (humidity < humidityRange['min']) {
        adviceText += "Humidity is low for $crop. Consider increasing irrigation frequency. ";
      } else if (humidity > humidityRange['max']) {
        adviceText += "Humidity is high for $crop. ";
        if (condition.contains('Rain') || condition.contains('Drizzle')) {
          adviceText += "Watch for increased disease pressure in wet conditions. ";
        }
      }
      
      // Weather condition specific advice
      if (condition.contains('Rain') || condition.contains('Drizzle')) {
        if (cropData['sensitiveToRain'] == true) {
          adviceText += "Current rainy conditions may affect $crop. Ensure proper drainage and monitor for disease. ";
          
          if (plantingMonths.contains(currentMonth)) {
            adviceText += "Delay planting until field conditions improve. ";
          }
          
          if (harvestMonths.contains(currentMonth)) {
            adviceText += "Harvest may be delayed due to rain. Protect harvested produce from moisture. ";
          }
        }
      } else if (condition.contains('Clear') || condition.contains('Sunny')) {
        final String waterRequirement = cropData['waterRequirement'] ?? 'moderate';
        if (waterRequirement == 'high') {
          adviceText += "Ensure adequate irrigation during this sunny period. ";
        }
        
        if (harvestMonths.contains(currentMonth)) {
          adviceText += "Good conditions for harvesting $crop. ";
        }
      }
      
      // Generate a title based on the current situation
      String adviceTitle = "Growing Tips";
      if (plantingMonths.contains(currentMonth)) {
        adviceTitle = "Planting Season";
      } else if (harvestMonths.contains(currentMonth)) {
        adviceTitle = "Harvest Season";
      } else if (temperature > tempRange['max']) {
        adviceTitle = "Heat Management";
      } else if (temperature < tempRange['min']) {
        adviceTitle = "Cold Protection";
      } else if (condition.contains('Rain')) {
        adviceTitle = "Rainy Conditions";
      }
      
      // Select appropriate icon and color based on advice content
      String iconName = 'grass';
      String colorHex = '#4CAF50'; // Green default
      
      if (adviceText.contains("irrigation") || adviceText.contains("water")) {
        iconName = 'water_drop';
        colorHex = '#2196F3'; // Blue
      } else if (adviceText.contains("temperature") || adviceText.contains("heat")) {
        iconName = 'thermostat';
        colorHex = '#FFA500'; // Orange
      } else if (adviceText.contains("disease") || adviceText.contains("pest")) {
        iconName = 'bug_report';
        colorHex = '#F44336'; // Red
      } else if (adviceText.contains("harvesting") || adviceText.contains("harvest")) {
        iconName = 'agriculture';
        colorHex = '#8BC34A'; // Light Green
      } else if (adviceText.contains("planting") || adviceText.contains("sowing")) {
        iconName = 'seed';
        colorHex = '#795548'; // Brown
      }
      
      // Add to advice list
      advice.add({
        'crop': crop[0].toUpperCase() + crop.substring(1),
        'advice': adviceText,
        'iconName': iconName,
        'color': colorHex,
        'region': region,
        'currentStage': currentStage,
        'title': adviceTitle
      });
    }
    
    return advice;
  }
  
  // Helper to estimate growth stage based on planting months and current month
  String _estimateGrowthStage(String crop, String currentMonth) {
    if (!_cropPreferences.containsKey(crop)) {
      return '';
    }
    
    final cropData = _cropPreferences[crop]!;
    final List<String> plantingMonths = List<String>.from(cropData['plantingMonths'] ?? []);
    final List<String> growthStages = List<String>.from(cropData['growthStages'] ?? []);
    
    if (plantingMonths.isEmpty || growthStages.isEmpty) {
      return '';
    }
    
    // Get all months in order
    final List<String> allMonths = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    // Find closest planting month
    int currentMonthIndex = allMonths.indexOf(currentMonth);
    int closestPlantingMonthIndex = -1;
    int minDistance = 12;
    
    for (final month in plantingMonths) {
      int monthIndex = allMonths.indexOf(month);
      int distance = (monthIndex - currentMonthIndex) % 12;
      if (distance < minDistance) {
        minDistance = distance;
        closestPlantingMonthIndex = monthIndex;
      }
    }
    
    if (closestPlantingMonthIndex == -1) {
      return '';
    }
    
    // Calculate months since planting
    int monthsSincePlanting = (currentMonthIndex - closestPlantingMonthIndex) % 12;
    
    // Estimate growth stage based on months since planting
    int totalGrowthPeriod = 6; // Assume 6 months growth cycle by default
    int stageIndex = (monthsSincePlanting * growthStages.length) ~/ totalGrowthPeriod;
    
    // Bound the stage index
    stageIndex = stageIndex.clamp(0, growthStages.length - 1);
    
    return growthStages[stageIndex];
  }
  
  // Helper to determine season from date
  String _getSeason(DateTime date) {
    int month = date.month;
    
    if (month >= 6 && month <= 9) {
      return 'monsoon';
    } else if (month >= 10 && month <= 11) {
      return 'post-monsoon';
    } else if (month >= 12 || month <= 2) {
      return 'winter';
    } else {
      return 'summer';
    }
  }
}
