import 'dart:async';
import 'package:kisan_veer/services/connectivity_service.dart';
import 'package:kisan_veer/services/offline_storage_service.dart';
import 'package:kisan_veer/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sync manager for handling offline data synchronization
/// Automatically syncs pending actions when connectivity is restored
class SyncManager {
  final ConnectivityService _connectivity = ConnectivityService();
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  bool _isSyncing = false;
  
  // Callbacks
  void Function(int pending, int synced)? onSyncProgress;
  void Function()? onSyncComplete;
  void Function(String error)? onSyncError;
  
  // Singleton pattern
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();
  
  /// Initialize sync manager and start monitoring
  Future<void> initialize() async {
    await _offlineStorage.initialize();
    await _connectivity.initialize();
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.statusStream.listen((status) {
      if (status == ConnectivityStatus.online) {
        AppLogger.i('Connection restored, starting sync', tag: 'SyncManager');
        syncPendingActions();
      }
    });
    
    // Initial sync if online
    if (_connectivity.isOnline) {
      await syncPendingActions();
    }
    
    AppLogger.d('Sync manager initialized', tag: 'SyncManager');
  }
  
  /// Sync all pending actions
  Future<SyncResult> syncPendingActions() async {
    if (_isSyncing) {
      return SyncResult(total: 0, synced: 0, failed: 0);
    }
    
    if (!_connectivity.isOnline) {
      return SyncResult(total: 0, synced: 0, failed: 0, error: 'No internet connection');
    }
    
    _isSyncing = true;
    
    try {
      final pendingActions = _offlineStorage.getPendingActions();
      
      if (pendingActions.isEmpty) {
        _isSyncing = false;
        return SyncResult(total: 0, synced: 0, failed: 0);
      }
      
      AppLogger.i('Syncing ${pendingActions.length} pending actions', tag: 'SyncManager');
      
      int synced = 0;
      int failed = 0;
      
      for (final action in pendingActions) {
        try {
          final success = await _processPendingAction(action);
          
          if (success) {
            await _offlineStorage.removePendingAction(action.id);
            synced++;
          } else {
            action.retryCount++;
            if (action.retryCount >= 3) {
              await _offlineStorage.removePendingAction(action.id);
              AppLogger.w('Action ${action.id} failed after 3 retries', tag: 'SyncManager');
            }
            failed++;
          }
          
          onSyncProgress?.call(pendingActions.length - synced, synced);
        } catch (e) {
          AppLogger.e('Error syncing action ${action.id}', tag: 'SyncManager', error: e);
          failed++;
        }
      }
      
      final result = SyncResult(
        total: pendingActions.length,
        synced: synced,
        failed: failed,
      );
      
      AppLogger.success('Sync complete: $synced/${pendingActions.length}', tag: 'SyncManager');
      onSyncComplete?.call();
      
      return result;
    } catch (e) {
      AppLogger.e('Sync failed', tag: 'SyncManager', error: e);
      onSyncError?.call(e.toString());
      return SyncResult(total: 0, synced: 0, failed: 0, error: e.toString());
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Process individual pending action
  Future<bool> _processPendingAction(PendingAction action) async {
    switch (action.type) {
      case ActionTypes.createOrder:
        return _syncCreateOrder(action.data);
      case ActionTypes.updateProfile:
        return _syncUpdateProfile(action.data);
      case ActionTypes.addToCart:
        return _syncAddToCart(action.data);
      case ActionTypes.createPost:
        return _syncCreatePost(action.data);
      case ActionTypes.addPriceAlert:
        return _syncAddPriceAlert(action.data);
      default:
        AppLogger.w('Unknown action type: ${action.type}', tag: 'SyncManager');
        return false;
    }
  }
  
  // Sync implementations
  Future<bool> _syncCreateOrder(Map<String, dynamic> data) async {
    try {
      await _supabase.from('orders').insert(data);
      return true;
    } catch (e) {
      AppLogger.e('Failed to sync order', tag: 'SyncManager', error: e);
      return false;
    }
  }
  
  Future<bool> _syncUpdateProfile(Map<String, dynamic> data) async {
    try {
      final userId = data['user_id'];
      await _supabase.from('user_profiles').update(data).eq('id', userId);
      return true;
    } catch (e) {
      AppLogger.e('Failed to sync profile update', tag: 'SyncManager', error: e);
      return false;
    }
  }
  
  Future<bool> _syncAddToCart(Map<String, dynamic> data) async {
    try {
      await _supabase.from('cart_items').insert(data);
      return true;
    } catch (e) {
      AppLogger.e('Failed to sync cart item', tag: 'SyncManager', error: e);
      return false;
    }
  }
  
  Future<bool> _syncCreatePost(Map<String, dynamic> data) async {
    try {
      await _supabase.from('community_posts').insert(data);
      return true;
    } catch (e) {
      AppLogger.e('Failed to sync post', tag: 'SyncManager', error: e);
      return false;
    }
  }
  
  Future<bool> _syncAddPriceAlert(Map<String, dynamic> data) async {
    try {
      await _supabase.from('price_alerts').insert(data);
      return true;
    } catch (e) {
      AppLogger.e('Failed to sync price alert', tag: 'SyncManager', error: e);
      return false;
    }
  }
  
  /// Get pending actions count
  int get pendingCount => _offlineStorage.pendingActionsCount;
  
  /// Check if currently syncing
  bool get isSyncing => _isSyncing;
  
  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

/// Sync operation result
class SyncResult {
  final int total;
  final int synced;
  final int failed;
  final String? error;
  
  SyncResult({
    required this.total,
    required this.synced,
    required this.failed,
    this.error,
  });
  
  bool get isSuccess => error == null && failed == 0;
  bool get hasFailures => failed > 0;
}
