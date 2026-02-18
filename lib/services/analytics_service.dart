import 'package:flutter/foundation.dart';
import 'package:kisan_veer/utils/app_logger.dart';

/// Analytics service for tracking user events and behavior
/// Works without Firebase - stores locally and syncs with Supabase
class AnalyticsService {
  // Event queue for batch sending
  final List<AnalyticsEvent> _eventQueue = [];
  
  // Max batch size before auto-flush
  static const int _maxQueueSize = 50;
  
  // User properties
  String? _userId;
  Map<String, dynamic> _userProperties = {};
  
  // Singleton pattern
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();
  
  /// Initialize analytics with user info
  void initialize({String? userId}) {
    _userId = userId;
    AppLogger.d('Analytics initialized for user: $userId', tag: 'Analytics');
  }
  
  /// Set user ID (call after login)
  void setUserId(String userId) {
    _userId = userId;
    _logEvent('user_identified', {'user_id': userId});
  }
  
  /// Set user properties
  void setUserProperties(Map<String, dynamic> properties) {
    _userProperties.addAll(properties);
  }
  
  /// Log screen view
  void logScreenView(String screenName, {Map<String, dynamic>? parameters}) {
    _logEvent('screen_view', {
      'screen_name': screenName,
      ...?parameters,
    });
  }
  
  /// Log button click
  void logButtonClick(String buttonName, {String? screenName, Map<String, dynamic>? parameters}) {
    _logEvent('button_click', {
      'button_name': buttonName,
      if (screenName != null) 'screen_name': screenName,
      ...?parameters,
    });
  }
  
  /// Log search
  void logSearch(String searchTerm, {int resultCount = 0}) {
    _logEvent('search', {
      'search_term': searchTerm,
      'result_count': resultCount,
    });
  }
  
  /// Log add to cart
  void logAddToCart(String productId, double price, {int quantity = 1}) {
    _logEvent('add_to_cart', {
      'product_id': productId,
      'price': price,
      'quantity': quantity,
      'value': price * quantity,
    });
  }
  
  /// Log purchase
  void logPurchase(String orderId, double totalAmount, {List<String>? productIds}) {
    _logEvent('purchase', {
      'order_id': orderId,
      'total_amount': totalAmount,
      'product_ids': productIds,
      'currency': 'INR',
    });
  }
  
  /// Log sign up
  void logSignUp(String method) {
    _logEvent('sign_up', {'method': method});
  }
  
  /// Log login
  void logLogin(String method) {
    _logEvent('login', {'method': method});
  }
  
  /// Log feature usage
  void logFeatureUsage(String featureName, {Map<String, dynamic>? parameters}) {
    _logEvent('feature_usage', {
      'feature_name': featureName,
      ...?parameters,
    });
  }
  
  /// Log error
  void logError(String errorType, String message, {StackTrace? stackTrace}) {
    _logEvent('error', {
      'error_type': errorType,
      'message': message,
      if (stackTrace != null) 'stack_trace': stackTrace.toString().substring(0, 500),
    });
  }
  
  /// Core event logging
  void _logEvent(String eventName, Map<String, dynamic> parameters) {
    final event = AnalyticsEvent(
      name: eventName,
      parameters: {
        ...parameters,
        'timestamp': DateTime.now().toIso8601String(),
        if (_userId != null) 'user_id': _userId,
      },
      timestamp: DateTime.now(),
    );
    
    _eventQueue.add(event);
    
    // Debug logging
    if (kDebugMode) {
      AppLogger.d('Event: $eventName', tag: 'Analytics');
    }
    
    // Auto-flush if queue is full
    if (_eventQueue.length >= _maxQueueSize) {
      flushEvents();
    }
  }
  
  /// Flush events to Supabase
  Future<void> flushEvents() async {
    if (_eventQueue.isEmpty) return;
    
    final eventsToSend = List<AnalyticsEvent>.from(_eventQueue);
    _eventQueue.clear();
    
    try {
      // In production, send to Supabase analytics table
      // For now, just log in debug mode
      if (kDebugMode) {
        AppLogger.d('Flushing ${eventsToSend.length} events', tag: 'Analytics');
      }
      
      // TODO: Implement Supabase batch insert
      // await _supabase.from('analytics_events').insert(
      //   eventsToSend.map((e) => e.toMap()).toList()
      // );
    } catch (e) {
      // Re-add failed events to queue
      _eventQueue.insertAll(0, eventsToSend);
      AppLogger.e('Failed to flush analytics', tag: 'Analytics', error: e);
    }
  }
  
  /// Get event count in queue
  int get pendingEventCount => _eventQueue.length;
  
  /// Clear all queued events
  void clearEvents() {
    _eventQueue.clear();
  }
}

/// Analytics event model
class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  
  AnalyticsEvent({
    required this.name,
    required this.parameters,
    required this.timestamp,
  });
  
  Map<String, dynamic> toMap() => {
    'event_name': name,
    'parameters': parameters,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Common event names
class AnalyticsEvents {
  static const String screenView = 'screen_view';
  static const String buttonClick = 'button_click';
  static const String search = 'search';
  static const String addToCart = 'add_to_cart';
  static const String purchase = 'purchase';
  static const String signUp = 'sign_up';
  static const String login = 'login';
  static const String featureUsage = 'feature_usage';
  static const String error = 'error';
}
