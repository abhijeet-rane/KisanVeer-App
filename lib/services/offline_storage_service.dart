import 'package:hive_flutter/hive_flutter.dart';
import 'package:kisan_veer/utils/app_logger.dart';

/// Offline storage service using Hive for fast local data persistence
/// Implements offline-first architecture with sync support
class OfflineStorageService {
  // Box names
  static const String _marketPricesBox = 'market_prices';
  static const String _productsBox = 'products';
  static const String _userDataBox = 'user_data';
  static const String _pendingActionsBox = 'pending_actions';
  static const String _cacheMetadataBox = 'cache_metadata';
  
  // Singleton pattern
  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();
  
  bool _isInitialized = false;
  
  /// Initialize Hive and open boxes
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await Hive.initFlutter();
      
      // Open all boxes
      await Future.wait([
        Hive.openBox<Map>(_marketPricesBox),
        Hive.openBox<Map>(_productsBox),
        Hive.openBox<Map>(_userDataBox),
        Hive.openBox<Map>(_pendingActionsBox),
        Hive.openBox<Map>(_cacheMetadataBox),
      ]);
      
      _isInitialized = true;
      AppLogger.d('Offline storage initialized', tag: 'OfflineStorage');
    } catch (e) {
      AppLogger.e('Failed to initialize offline storage', tag: 'OfflineStorage', error: e);
      rethrow;
    }
  }
  
  // ============ Market Prices Cache ============
  
  /// Save market prices locally
  Future<void> cacheMarketPrices(String commodityId, Map<String, dynamic> priceData) async {
    final box = Hive.box<Map>(_marketPricesBox);
    await box.put(commodityId, priceData);
    await _updateCacheTimestamp(_marketPricesBox, commodityId);
  }
  
  /// Get cached market prices
  Map<String, dynamic>? getMarketPrices(String commodityId) {
    final box = Hive.box<Map>(_marketPricesBox);
    final data = box.get(commodityId);
    return data?.cast<String, dynamic>();
  }
  
  /// Get all cached market prices
  Map<String, Map<String, dynamic>> getAllMarketPrices() {
    final box = Hive.box<Map>(_marketPricesBox);
    final result = <String, Map<String, dynamic>>{};
    
    for (final key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        result[key.toString()] = data.cast<String, dynamic>();
      }
    }
    
    return result;
  }
  
  // ============ Products Cache ============
  
  /// Save product locally
  Future<void> cacheProduct(String productId, Map<String, dynamic> productData) async {
    final box = Hive.box<Map>(_productsBox);
    await box.put(productId, productData);
    await _updateCacheTimestamp(_productsBox, productId);
  }
  
  /// Get cached product
  Map<String, dynamic>? getProduct(String productId) {
    final box = Hive.box<Map>(_productsBox);
    final data = box.get(productId);
    return data?.cast<String, dynamic>();
  }
  
  /// Get all cached products
  List<Map<String, dynamic>> getAllProducts() {
    final box = Hive.box<Map>(_productsBox);
    return box.values.map((e) => e.cast<String, dynamic>()).toList();
  }
  
  // ============ User Data Cache ============
  
  /// Save user profile locally
  Future<void> cacheUserProfile(String userId, Map<String, dynamic> profileData) async {
    final box = Hive.box<Map>(_userDataBox);
    await box.put('profile_$userId', profileData);
  }
  
  /// Get cached user profile
  Map<String, dynamic>? getUserProfile(String userId) {
    final box = Hive.box<Map>(_userDataBox);
    final data = box.get('profile_$userId');
    return data?.cast<String, dynamic>();
  }
  
  // ============ Pending Actions (Sync Queue) ============
  
  /// Queue an action for later sync
  Future<void> queuePendingAction(PendingAction action) async {
    final box = Hive.box<Map>(_pendingActionsBox);
    await box.put(action.id, action.toMap());
    AppLogger.d('Action queued for sync: ${action.type}', tag: 'OfflineStorage');
  }
  
  /// Get all pending actions
  List<PendingAction> getPendingActions() {
    final box = Hive.box<Map>(_pendingActionsBox);
    return box.values
        .map((e) => PendingAction.fromMap(e.cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
  
  /// Remove pending action after successful sync
  Future<void> removePendingAction(String actionId) async {
    final box = Hive.box<Map>(_pendingActionsBox);
    await box.delete(actionId);
  }
  
  /// Get pending actions count
  int get pendingActionsCount {
    final box = Hive.box<Map>(_pendingActionsBox);
    return box.length;
  }
  
  // ============ Cache Metadata ============
  
  Future<void> _updateCacheTimestamp(String boxName, String key) async {
    final metaBox = Hive.box<Map>(_cacheMetadataBox);
    await metaBox.put('${boxName}_$key', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  /// Check if cache is still valid
  bool isCacheValid(String boxName, String key, {Duration maxAge = const Duration(minutes: 30)}) {
    final metaBox = Hive.box<Map>(_cacheMetadataBox);
    final meta = metaBox.get('${boxName}_$key');
    
    if (meta == null) return false;
    
    final timestamp = meta['timestamp'] as int?;
    if (timestamp == null) return false;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime) < maxAge;
  }
  
  /// Get cache age
  Duration? getCacheAge(String boxName, String key) {
    final metaBox = Hive.box<Map>(_cacheMetadataBox);
    final meta = metaBox.get('${boxName}_$key');
    
    if (meta == null) return null;
    
    final timestamp = meta['timestamp'] as int?;
    if (timestamp == null) return null;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime);
  }
  
  // ============ Clear Methods ============
  
  /// Clear all caches
  Future<void> clearAll() async {
    await Future.wait([
      Hive.box<Map>(_marketPricesBox).clear(),
      Hive.box<Map>(_productsBox).clear(),
      Hive.box<Map>(_userDataBox).clear(),
      Hive.box<Map>(_cacheMetadataBox).clear(),
    ]);
    AppLogger.d('All caches cleared', tag: 'OfflineStorage');
  }
  
  /// Clear only stale cache (older than specified duration)
  Future<void> clearStaleCache(Duration maxAge) async {
    final metaBox = Hive.box<Map>(_cacheMetadataBox);
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    for (final key in metaBox.keys) {
      final meta = metaBox.get(key);
      final timestamp = meta?['timestamp'] as int?;
      
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (now.difference(cacheTime) > maxAge) {
          keysToRemove.add(key.toString());
        }
      }
    }
    
    for (final key in keysToRemove) {
      // Parse box name and item key
      final parts = key.split('_');
      if (parts.length >= 2) {
        final boxName = parts[0];
        final itemKey = parts.sublist(1).join('_');
        
        try {
          final box = Hive.box<Map>(boxName);
          await box.delete(itemKey);
        } catch (_) {}
      }
      await metaBox.delete(key);
    }
    
    AppLogger.d('Cleared ${keysToRemove.length} stale cache entries', tag: 'OfflineStorage');
  }
}

/// Pending action for sync queue
class PendingAction {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;
  
  PendingAction({
    required this.id,
    required this.type,
    required this.data,
    DateTime? createdAt,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'data': data,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'retryCount': retryCount,
  };
  
  factory PendingAction.fromMap(Map<String, dynamic> map) => PendingAction(
    id: map['id'] as String,
    type: map['type'] as String,
    data: Map<String, dynamic>.from(map['data'] as Map),
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    retryCount: map['retryCount'] as int? ?? 0,
  );
}

/// Action types for sync queue
class ActionTypes {
  static const String createOrder = 'create_order';
  static const String updateProfile = 'update_profile';
  static const String addToCart = 'add_to_cart';
  static const String createPost = 'create_post';
  static const String addPriceAlert = 'add_price_alert';
}
