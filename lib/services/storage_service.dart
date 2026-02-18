import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();
  
  late SharedPreferences _prefs;
  
  /// Initialize the service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  /// Save a string value
  Future<bool> saveString(String key, String value) async {
    return await _prefs.setString(key, value);
  }
  
  /// Get a string value
  String? getString(String key) {
    return _prefs.getString(key);
  }
  
  /// Save an integer value
  Future<bool> saveInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }
  
  /// Get an integer value
  int? getInt(String key) {
    return _prefs.getInt(key);
  }
  
  /// Save a double value
  Future<bool> saveDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }
  
  /// Get a double value
  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }
  
  /// Save a boolean value
  Future<bool> saveBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }
  
  /// Get a boolean value
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }
  
  /// Save a list of strings
  Future<bool> saveStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }
  
  /// Get a list of strings
  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }
  
  /// Check if a key exists
  bool hasKey(String key) {
    return _prefs.containsKey(key);
  }
  
  /// Remove a key
  Future<bool> removeKey(String key) async {
    return await _prefs.remove(key);
  }
  
  /// Clear all data
  Future<bool> clear() async {
    return await _prefs.clear();
  }
  
  /// Get all keys
  Set<String> getKeys() {
    return _prefs.getKeys();
  }
}
