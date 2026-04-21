import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kisan_veer/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Analytics service for tracking user events and behavior.
/// Events are queued in memory and batch-inserted into the Supabase
/// `analytics_events` table.
class AnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// In-memory queue that is drained by [flushEvents].
  final List<AnalyticsEvent> _eventQueue = [];

  /// Auto-flush when the queue hits this size.
  static const int _maxQueueSize = 50;

  /// Periodic flush cadence so small event batches still reach the backend.
  static const Duration _flushInterval = Duration(minutes: 2);

  Timer? _flushTimer;
  String? _userId;
  final Map<String, dynamic> _userProperties = {};

  // Singleton
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  /// Wire the service at app startup. Safe to call multiple times.
  void initialize({String? userId}) {
    _userId = userId;
    _flushTimer ??= Timer.periodic(_flushInterval, (_) => flushEvents());
    AppLogger.d('Analytics initialized for user: $userId', tag: 'Analytics');
  }

  /// Release the periodic flush timer (e.g. on app teardown / logout).
  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  /// Call after login.
  void setUserId(String userId) {
    _userId = userId;
    _logEvent('user_identified', {'user_id': userId});
  }

  /// Call after logout.
  void clearUser() {
    _userId = null;
    _userProperties.clear();
  }

  void setUserProperties(Map<String, dynamic> properties) {
    _userProperties.addAll(properties);
  }

  void logScreenView(String screenName, {Map<String, dynamic>? parameters}) {
    _logEvent('screen_view', {
      'screen_name': screenName,
      ...?parameters,
    });
  }

  void logButtonClick(String buttonName,
      {String? screenName, Map<String, dynamic>? parameters}) {
    _logEvent('button_click', {
      'button_name': buttonName,
      if (screenName != null) 'screen_name': screenName,
      ...?parameters,
    });
  }

  void logSearch(String searchTerm, {int resultCount = 0}) {
    _logEvent('search', {
      'search_term': searchTerm,
      'result_count': resultCount,
    });
  }

  void logAddToCart(String productId, double price, {int quantity = 1}) {
    _logEvent('add_to_cart', {
      'product_id': productId,
      'price': price,
      'quantity': quantity,
      'value': price * quantity,
    });
  }

  void logPurchase(String orderId, double totalAmount,
      {List<String>? productIds}) {
    _logEvent('purchase', {
      'order_id': orderId,
      'total_amount': totalAmount,
      'product_ids': productIds,
      'currency': 'INR',
    });
  }

  void logSignUp(String method) {
    _logEvent('sign_up', {'method': method});
  }

  void logLogin(String method) {
    _logEvent('login', {'method': method});
  }

  void logFeatureUsage(String featureName,
      {Map<String, dynamic>? parameters}) {
    _logEvent('feature_usage', {
      'feature_name': featureName,
      ...?parameters,
    });
  }

  void logError(String errorType, String message, {StackTrace? stackTrace}) {
    _logEvent('error', {
      'error_type': errorType,
      'message': message,
      if (stackTrace != null)
        'stack_trace': stackTrace.toString().substring(
              0,
              stackTrace.toString().length > 500
                  ? 500
                  : stackTrace.toString().length,
            ),
    });
  }

  void _logEvent(String eventName, Map<String, dynamic> parameters) {
    final event = AnalyticsEvent(
      name: eventName,
      parameters: {
        ...parameters,
        if (_userProperties.isNotEmpty) 'user_properties': _userProperties,
      },
      userId: _userId,
      timestamp: DateTime.now(),
    );

    _eventQueue.add(event);

    if (kDebugMode) {
      AppLogger.d('Event queued: $eventName', tag: 'Analytics');
    }

    if (_eventQueue.length >= _maxQueueSize) {
      flushEvents();
    }
  }

  /// Drain the queue into Supabase. Failed sends are re-queued.
  Future<void> flushEvents() async {
    if (_eventQueue.isEmpty) return;

    final eventsToSend = List<AnalyticsEvent>.from(_eventQueue);
    _eventQueue.clear();

    try {
      await _supabase
          .from('analytics_events')
          .insert(eventsToSend.map((e) => e.toRow()).toList());

      if (kDebugMode) {
        AppLogger.d('Flushed ${eventsToSend.length} events',
            tag: 'Analytics');
      }
    } catch (e, s) {
      // Re-queue so the next flush retries them.
      _eventQueue.insertAll(0, eventsToSend);
      AppLogger.e('Failed to flush analytics',
          tag: 'Analytics', error: e, stackTrace: s);
    }
  }

  int get pendingEventCount => _eventQueue.length;

  void clearEvents() => _eventQueue.clear();
}

class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> parameters;
  final String? userId;
  final DateTime timestamp;

  AnalyticsEvent({
    required this.name,
    required this.parameters,
    required this.timestamp,
    this.userId,
  });

  /// Shape matches the `analytics_events` Supabase table.
  Map<String, dynamic> toRow() => {
        'event_name': name,
        'parameters': parameters,
        'user_id': userId,
        'occurred_at': timestamp.toUtc().toIso8601String(),
      };
}

/// Common event-name constants so callers stay consistent.
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
