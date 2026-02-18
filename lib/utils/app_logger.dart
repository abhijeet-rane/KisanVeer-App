import 'package:flutter/foundation.dart';

/// Enterprise-grade logging service for Kisan Veer app
/// Replaces debug print() statements with structured logging
/// that is stripped in release builds
class AppLogger {
  static const String _appTag = 'KisanVeer';
  
  // Log levels
  static const int _levelDebug = 0;
  static const int _levelInfo = 1;
  static const int _levelWarning = 2;
  static const int _levelError = 3;
  
  /// Current minimum log level (debug in dev, warning in release)
  static int _minLevel = kDebugMode ? _levelDebug : _levelWarning;
  
  /// Set minimum log level at runtime
  static void setLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        _minLevel = _levelDebug;
        break;
      case LogLevel.info:
        _minLevel = _levelInfo;
        break;
      case LogLevel.warning:
        _minLevel = _levelWarning;
        break;
      case LogLevel.error:
        _minLevel = _levelError;
        break;
    }
  }

  /// Debug log - only in debug mode
  static void d(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(_levelDebug, '🔍', message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Info log
  static void i(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(_levelInfo, 'ℹ️', message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Warning log
  static void w(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(_levelWarning, '⚠️', message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Error log
  static void e(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(_levelError, '❌', message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Success log (uses info level)
  static void success(String message, {String? tag}) {
    _log(_levelInfo, '✅', message, tag: tag);
  }

  /// Network log (uses debug level)
  static void network(String message, {String? tag, Object? data}) {
    if (kDebugMode && _minLevel <= _levelDebug) {
      final dataStr = data != null ? '\n  Data: $data' : '';
      _log(_levelDebug, '🌐', '$message$dataStr', tag: tag ?? 'Network');
    }
  }

  /// Performance log (uses debug level)
  static void performance(String message, {Duration? duration, String? tag}) {
    if (kDebugMode && _minLevel <= _levelDebug) {
      final durationStr = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
      _log(_levelDebug, '⚡', '$message$durationStr', tag: tag ?? 'Perf');
    }
  }

  /// Internal log method
  static void _log(
    int level,
    String emoji,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Skip if below minimum level
    if (level < _minLevel) return;
    
    // Skip all logging in release mode except errors
    if (!kDebugMode && level < _levelError) return;
    
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final tagStr = tag ?? _appTag;
    final logMessage = '[$timestamp] $emoji [$tagStr] $message';
    
    // Use debugPrint for better handling of long messages
    debugPrint(logMessage);
    
    if (error != null) {
      debugPrint('  Error: $error');
    }
    
    if (stackTrace != null && level >= _levelError) {
      debugPrint('  StackTrace:\n$stackTrace');
    }
  }
}

/// Log levels enum for external configuration
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Extension for easy try-catch logging
extension LoggerExtension on Object {
  void logError(String message, {StackTrace? stackTrace}) {
    AppLogger.e(message, error: this, stackTrace: stackTrace);
  }
}

/// Mixin for classes that need logging
mixin Loggable {
  String get logTag => runtimeType.toString();
  
  void logDebug(String message) => AppLogger.d(message, tag: logTag);
  void logInfo(String message) => AppLogger.i(message, tag: logTag);
  void logWarning(String message) => AppLogger.w(message, tag: logTag);
  void logError(String message, {Object? error, StackTrace? stackTrace}) => 
      AppLogger.e(message, tag: logTag, error: error, stackTrace: stackTrace);
}
