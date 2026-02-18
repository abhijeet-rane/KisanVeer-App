import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:kisan_veer/utils/app_logger.dart';

/// Connectivity service for monitoring network status
/// Provides real-time network state and offline detection
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  StreamController<ConnectivityStatus>? _statusController;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  
  // Singleton pattern
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();
  
  /// Get current connectivity status
  ConnectivityStatus get currentStatus => _currentStatus;
  
  /// Check if currently online
  bool get isOnline => _currentStatus == ConnectivityStatus.online;
  
  /// Check if currently offline
  bool get isOffline => _currentStatus == ConnectivityStatus.offline;
  
  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get statusStream {
    _statusController ??= StreamController<ConnectivityStatus>.broadcast();
    return _statusController!.stream;
  }
  
  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      // Get initial status
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
      
      // Start listening for changes
      _subscription = _connectivity.onConnectivityChanged.listen(
        _updateStatus,
        onError: (error) {
          AppLogger.e('Connectivity error', tag: 'Connectivity', error: error);
          _currentStatus = ConnectivityStatus.unknown;
          _statusController?.add(_currentStatus);
        },
      );
      
      AppLogger.d('Connectivity service initialized: $_currentStatus', tag: 'Connectivity');
    } catch (e) {
      AppLogger.e('Failed to initialize connectivity', tag: 'Connectivity', error: e);
    }
  }
  
  void _updateStatus(List<ConnectivityResult> results) {
    final newStatus = _mapResultsToStatus(results);
    
    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _statusController?.add(_currentStatus);
      
      AppLogger.i(
        'Connectivity changed: $_currentStatus',
        tag: 'Connectivity',
      );
    }
  }
  
  ConnectivityStatus _mapResultsToStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    }
    
    if (results.contains(ConnectivityResult.wifi)) {
      return ConnectivityStatus.online;
    }
    
    if (results.contains(ConnectivityResult.mobile)) {
      return ConnectivityStatus.online;
    }
    
    if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectivityStatus.online;
    }
    
    return ConnectivityStatus.unknown;
  }
  
  /// Check connectivity once (useful for on-demand checks)
  Future<ConnectivityStatus> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _mapResultsToStatus(results);
    } catch (e) {
      AppLogger.e('Failed to check connectivity', tag: 'Connectivity', error: e);
      return ConnectivityStatus.unknown;
    }
  }
  
  /// Wait for connectivity to be restored
  Future<void> waitForConnectivity({Duration timeout = const Duration(seconds: 30)}) async {
    if (isOnline) return;
    
    final completer = Completer<void>();
    
    final subscription = statusStream.listen((status) {
      if (status == ConnectivityStatus.online) {
        completer.complete();
      }
    });
    
    try {
      await completer.future.timeout(timeout);
    } finally {
      await subscription.cancel();
    }
  }
  
  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _statusController?.close();
    _statusController = null;
  }
}

/// Connectivity status enum
enum ConnectivityStatus {
  online,
  offline,
  unknown,
}

/// Extension for user-friendly messages
extension ConnectivityStatusMessage on ConnectivityStatus {
  String get message => switch (this) {
    ConnectivityStatus.online => 'Connected',
    ConnectivityStatus.offline => 'No internet connection',
    ConnectivityStatus.unknown => 'Checking connection...',
  };
  
  bool get isConnected => this == ConnectivityStatus.online;
}
