/// Enterprise-grade Result type for functional error handling
/// Replaces try-catch with explicit success/failure types
sealed class Result<T> {
  const Result();
  
  /// Create a success result
  factory Result.success(T data) => Success(data);
  
  /// Create a failure result
  factory Result.failure(AppError error) => Failure(error);
  
  /// Check if result is success
  bool get isSuccess => this is Success<T>;
  
  /// Check if result is failure
  bool get isFailure => this is Failure<T>;
  
  /// Get data if success, otherwise null
  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Failure() => null,
  };
  
  /// Get error if failure, otherwise null
  AppError? get errorOrNull => switch (this) {
    Success() => null,
    Failure(:final error) => error,
  };
  
  /// Map the success value
  Result<R> map<R>(R Function(T data) mapper) => switch (this) {
    Success(:final data) => Result.success(mapper(data)),
    Failure(:final error) => Result.failure(error),
  };
  
  /// Handle both cases
  R when<R>({
    required R Function(T data) success,
    required R Function(AppError error) failure,
  }) => switch (this) {
    Success(:final data) => success(data),
    Failure(:final error) => failure(error),
  };
  
  /// Get data or throw
  T getOrThrow() => switch (this) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
  
  /// Get data or default
  T getOrDefault(T defaultValue) => switch (this) {
    Success(:final data) => data,
    Failure() => defaultValue,
  };
}

/// Success variant
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Failure variant  
final class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}

/// Base class for all application errors
class AppError implements Exception {
  final String message;
  final String? code;
  final Object? originalError;
  final StackTrace? stackTrace;
  
  const AppError({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });
  
  @override
  String toString() => 'AppError: $message${code != null ? ' (code: $code)' : ''}';
}

/// Network-specific errors
class NetworkError extends AppError {
  final int? statusCode;
  
  const NetworkError({
    required super.message,
    super.code,
    this.statusCode,
    super.originalError,
    super.stackTrace,
  });
  
  factory NetworkError.noConnection() => const NetworkError(
    message: 'No internet connection. Please check your network settings.',
    code: 'NO_CONNECTION',
  );
  
  factory NetworkError.timeout() => const NetworkError(
    message: 'Request timed out. Please try again.',
    code: 'TIMEOUT',
  );
  
  factory NetworkError.server({int? statusCode, String? message}) => NetworkError(
    message: message ?? 'Server error occurred. Please try again later.',
    code: 'SERVER_ERROR',
    statusCode: statusCode,
  );
  
  factory NetworkError.unauthorized() => const NetworkError(
    message: 'Session expired. Please log in again.',
    code: 'UNAUTHORIZED',
    statusCode: 401,
  );
  
  factory NetworkError.notFound({String? resource}) => NetworkError(
    message: resource != null ? '$resource not found.' : 'Resource not found.',
    code: 'NOT_FOUND',
    statusCode: 404,
  );
}

/// Validation errors
class ValidationError extends AppError {
  final String field;
  
  const ValidationError({
    required this.field,
    required super.message,
    super.code = 'VALIDATION_ERROR',
  });
}

/// Authentication errors
class AuthError extends AppError {
  const AuthError({
    required super.message,
    super.code,
    super.originalError,
  });
  
  factory AuthError.invalidCredentials() => const AuthError(
    message: 'Invalid email or password. Please check your credentials.',
    code: 'INVALID_CREDENTIALS',
  );
  
  factory AuthError.userNotFound() => const AuthError(
    message: 'No account found with this email. Please register first.',
    code: 'USER_NOT_FOUND',
  );
  
  factory AuthError.emailInUse() => const AuthError(
    message: 'An account with this email already exists.',
    code: 'EMAIL_IN_USE',
  );
  
  factory AuthError.weakPassword() => const AuthError(
    message: 'Password is too weak. Please use a stronger password.',
    code: 'WEAK_PASSWORD',
  );
  
  factory AuthError.emailNotVerified() => const AuthError(
    message: 'Please verify your email before logging in.',
    code: 'EMAIL_NOT_VERIFIED',
  );
}

/// Storage/Cache errors
class StorageError extends AppError {
  const StorageError({
    required super.message,
    super.code = 'STORAGE_ERROR',
    super.originalError,
  });
}

/// Extension for easy Result creation from async operations
extension FutureResultExtension<T> on Future<T> {
  /// Convert a Future to a Result, catching any exceptions
  Future<Result<T>> toResult() async {
    try {
      final data = await this;
      return Result.success(data);
    } catch (e, stack) {
      if (e is AppError) {
        return Result.failure(e);
      }
      return Result.failure(AppError(
        message: e.toString(),
        originalError: e,
        stackTrace: stack,
      ));
    }
  }
}
