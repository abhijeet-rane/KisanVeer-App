import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:kisan_veer/utils/result.dart';
import 'package:kisan_veer/utils/app_logger.dart';

/// Enterprise-grade network wrapper with built-in error handling
/// Provides consistent error handling across all API calls
class NetworkClient {
  static const Duration defaultTimeout = Duration(seconds: 30);
  
  final http.Client _client;
  final Duration _timeout;
  
  NetworkClient({
    http.Client? client,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _timeout = timeout ?? defaultTimeout;
  
  /// GET request with Result type
  Future<Result<http.Response>> get(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return _executeRequest(() => _client
        .get(url, headers: headers)
        .timeout(timeout ?? _timeout));
  }
  
  /// POST request with Result type
  Future<Result<http.Response>> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    return _executeRequest(() => _client
        .post(url, headers: headers, body: body)
        .timeout(timeout ?? _timeout));
  }
  
  /// PUT request with Result type
  Future<Result<http.Response>> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    return _executeRequest(() => _client
        .put(url, headers: headers, body: body)
        .timeout(timeout ?? _timeout));
  }
  
  /// DELETE request with Result type
  Future<Result<http.Response>> delete(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return _executeRequest(() => _client
        .delete(url, headers: headers)
        .timeout(timeout ?? _timeout));
  }
  
  /// Execute request with error handling
  Future<Result<http.Response>> _executeRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request();
      
      // Log the request
      AppLogger.network(
        'HTTP ${response.request?.method} ${response.statusCode}',
        data: response.request?.url,
      );
      
      // Handle HTTP status codes
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Result.success(response);
      } else if (response.statusCode == 401) {
        return Result.failure(NetworkError.unauthorized());
      } else if (response.statusCode == 404) {
        return Result.failure(NetworkError.notFound());
      } else if (response.statusCode >= 500) {
        return Result.failure(NetworkError.server(
          statusCode: response.statusCode,
          message: 'Server error: ${response.statusCode}',
        ));
      } else {
        return Result.failure(NetworkError(
          message: 'Request failed with status: ${response.statusCode}',
          statusCode: response.statusCode,
        ));
      }
    } on SocketException {
      AppLogger.e('No internet connection', tag: 'Network');
      return Result.failure(NetworkError.noConnection());
    } on http.ClientException catch (e) {
      AppLogger.e('Client exception', tag: 'Network', error: e);
      return Result.failure(NetworkError(
        message: 'Network request failed',
        originalError: e,
      ));
    } on TimeoutException {
      AppLogger.e('Request timeout', tag: 'Network');
      return Result.failure(NetworkError.timeout());
    } catch (e, stack) {
      AppLogger.e('Unexpected network error', tag: 'Network', error: e, stackTrace: stack);
      return Result.failure(NetworkError(
        message: 'An unexpected error occurred',
        originalError: e,
        stackTrace: stack,
      ));
    }
  }
  
  /// Close the client
  void dispose() {
    _client.close();
  }
}

/// Exception for timeout
class TimeoutException implements Exception {
  final String message;
  const TimeoutException([this.message = 'Request timed out']);
  
  @override
  String toString() => message;
}
