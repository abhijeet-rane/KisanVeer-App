import 'package:flutter/foundation.dart';
import 'package:kisan_veer/utils/app_logger.dart';

/// Performance monitoring service for tracking app performance
/// Tracks screen load times, API response times, and frame rates
class PerformanceMonitor {
  // Active traces
  final Map<String, _PerformanceTrace> _activeTraces = {};
  
  // Completed metrics
  final List<PerformanceMetric> _metrics = [];
  
  // Thresholds for warnings
  static const int _slowScreenLoadMs = 1000;  // 1 second
  static const int _slowApiCallMs = 3000;     // 3 seconds
  
  // Max metrics to store
  static const int _maxMetrics = 100;
  
  // Singleton pattern
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();
  
  // ============ Screen Load Tracking ============
  
  /// Start tracking screen load time
  void startScreenLoad(String screenName) {
    final traceId = 'screen_$screenName';
    _activeTraces[traceId] = _PerformanceTrace(
      type: TraceType.screenLoad,
      name: screenName,
      startTime: DateTime.now(),
    );
  }
  
  /// End screen load tracking
  Duration? endScreenLoad(String screenName) {
    final traceId = 'screen_$screenName';
    final trace = _activeTraces.remove(traceId);
    
    if (trace == null) return null;
    
    final duration = DateTime.now().difference(trace.startTime);
    
    _recordMetric(PerformanceMetric(
      type: TraceType.screenLoad,
      name: screenName,
      durationMs: duration.inMilliseconds,
      timestamp: DateTime.now(),
    ));
    
    // Warn if slow
    if (duration.inMilliseconds > _slowScreenLoadMs) {
      AppLogger.w('Slow screen load: $screenName (${duration.inMilliseconds}ms)', 
          tag: 'Performance');
    } else if (kDebugMode) {
      AppLogger.performance('Screen load: $screenName', duration: duration);
    }
    
    return duration;
  }
  
  // ============ API Call Tracking ============
  
  /// Start tracking API call
  String startApiCall(String endpoint) {
    final traceId = 'api_${endpoint}_${DateTime.now().millisecondsSinceEpoch}';
    _activeTraces[traceId] = _PerformanceTrace(
      type: TraceType.apiCall,
      name: endpoint,
      startTime: DateTime.now(),
    );
    return traceId;
  }
  
  /// End API call tracking
  Duration? endApiCall(String traceId, {int? statusCode, bool? success}) {
    final trace = _activeTraces.remove(traceId);
    
    if (trace == null) return null;
    
    final duration = DateTime.now().difference(trace.startTime);
    
    _recordMetric(PerformanceMetric(
      type: TraceType.apiCall,
      name: trace.name,
      durationMs: duration.inMilliseconds,
      timestamp: DateTime.now(),
      metadata: {
        if (statusCode != null) 'status_code': statusCode,
        if (success != null) 'success': success,
      },
    ));
    
    // Warn if slow
    if (duration.inMilliseconds > _slowApiCallMs) {
      AppLogger.w('Slow API call: ${trace.name} (${duration.inMilliseconds}ms)', 
          tag: 'Performance');
    } else if (kDebugMode) {
      AppLogger.performance('API call: ${trace.name}', duration: duration);
    }
    
    return duration;
  }
  
  // ============ Custom Trace ============
  
  /// Start custom trace
  String startTrace(String name) {
    final traceId = 'custom_${name}_${DateTime.now().millisecondsSinceEpoch}';
    _activeTraces[traceId] = _PerformanceTrace(
      type: TraceType.custom,
      name: name,
      startTime: DateTime.now(),
    );
    return traceId;
  }
  
  /// End custom trace
  Duration? endTrace(String traceId, {Map<String, dynamic>? metadata}) {
    final trace = _activeTraces.remove(traceId);
    
    if (trace == null) return null;
    
    final duration = DateTime.now().difference(trace.startTime);
    
    _recordMetric(PerformanceMetric(
      type: TraceType.custom,
      name: trace.name,
      durationMs: duration.inMilliseconds,
      timestamp: DateTime.now(),
      metadata: metadata,
    ));
    
    if (kDebugMode) {
      AppLogger.performance('Trace: ${trace.name}', duration: duration);
    }
    
    return duration;
  }
  
  // ============ Metrics ============
  
  void _recordMetric(PerformanceMetric metric) {
    _metrics.add(metric);
    
    // Keep only recent metrics
    if (_metrics.length > _maxMetrics) {
      _metrics.removeAt(0);
    }
  }
  
  /// Get average duration for a metric type and name
  double? getAverageDuration(TraceType type, String name) {
    final matching = _metrics.where((m) => m.type == type && m.name == name);
    if (matching.isEmpty) return null;
    
    final total = matching.fold<int>(0, (sum, m) => sum + m.durationMs);
    return total / matching.length;
  }
  
  /// Get all metrics of a type
  List<PerformanceMetric> getMetrics(TraceType type) {
    return _metrics.where((m) => m.type == type).toList();
  }
  
  /// Get performance summary
  Map<String, dynamic> getSummary() {
    final screenLoads = getMetrics(TraceType.screenLoad);
    final apiCalls = getMetrics(TraceType.apiCall);
    
    return {
      'screen_load': {
        'count': screenLoads.length,
        'avg_ms': screenLoads.isEmpty ? 0 : 
            screenLoads.fold<int>(0, (s, m) => s + m.durationMs) ~/ screenLoads.length,
        'slow_count': screenLoads.where((m) => m.durationMs > _slowScreenLoadMs).length,
      },
      'api_calls': {
        'count': apiCalls.length,
        'avg_ms': apiCalls.isEmpty ? 0 :
            apiCalls.fold<int>(0, (s, m) => s + m.durationMs) ~/ apiCalls.length,
        'slow_count': apiCalls.where((m) => m.durationMs > _slowApiCallMs).length,
      },
    };
  }
  
  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _activeTraces.clear();
  }
}

/// Trace types
enum TraceType {
  screenLoad,
  apiCall,
  custom,
}

/// Internal trace model
class _PerformanceTrace {
  final TraceType type;
  final String name;
  final DateTime startTime;
  
  _PerformanceTrace({
    required this.type,
    required this.name,
    required this.startTime,
  });
}

/// Performance metric model
class PerformanceMetric {
  final TraceType type;
  final String name;
  final int durationMs;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  
  PerformanceMetric({
    required this.type,
    required this.name,
    required this.durationMs,
    required this.timestamp,
    this.metadata,
  });
  
  Map<String, dynamic> toMap() => {
    'type': type.name,
    'name': name,
    'duration_ms': durationMs,
    'timestamp': timestamp.toIso8601String(),
    if (metadata != null) 'metadata': metadata,
  };
}

/// Mixin for easy screen performance tracking
mixin ScreenPerformanceMixin<T extends StatefulWidget> on State<T> {
  final PerformanceMonitor _perfMonitor = PerformanceMonitor();
  
  @override
  void initState() {
    super.initState();
    _perfMonitor.startScreenLoad(widget.runtimeType.toString());
  }
  
  /// Call this after the first frame is rendered
  void markScreenLoaded() {
    _perfMonitor.endScreenLoad(widget.runtimeType.toString());
  }
}
