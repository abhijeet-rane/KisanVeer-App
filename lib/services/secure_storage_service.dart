import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kisan_veer/utils/app_logger.dart';

/// Secure storage service for encrypted credential and token storage
/// Uses AES-256 encryption on Android and Keychain on iOS
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  // Storage keys
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyLastActivity = 'last_activity';
  static const String _keySessionExpiry = 'session_expiry';
  
  // Singleton pattern
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();
  
  // ============ Token Management ============
  
  /// Save authentication tokens securely
  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    String? email,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _keyAccessToken, value: accessToken),
        _storage.write(key: _keyRefreshToken, value: refreshToken),
        _storage.write(key: _keyUserId, value: userId),
        if (email != null) _storage.write(key: _keyUserEmail, value: email),
        _updateLastActivity(),
      ]);
      AppLogger.d('Auth tokens saved securely', tag: 'SecureStorage');
    } catch (e) {
      AppLogger.e('Failed to save auth tokens', tag: 'SecureStorage', error: e);
      rethrow;
    }
  }
  
  /// Get access token
  Future<String?> getAccessToken() async {
    return _storage.read(key: _keyAccessToken);
  }
  
  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _keyRefreshToken);
  }
  
  /// Get stored user ID
  Future<String?> getUserId() async {
    return _storage.read(key: _keyUserId);
  }
  
  /// Get stored user email
  Future<String?> getUserEmail() async {
    return _storage.read(key: _keyUserEmail);
  }
  
  /// Check if user has stored credentials
  Future<bool> hasStoredCredentials() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
  
  /// Clear all auth tokens (logout)
  Future<void> clearAuthTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: _keyAccessToken),
        _storage.delete(key: _keyRefreshToken),
        _storage.delete(key: _keyUserId),
        _storage.delete(key: _keyUserEmail),
        _storage.delete(key: _keyLastActivity),
        _storage.delete(key: _keySessionExpiry),
      ]);
      AppLogger.d('Auth tokens cleared', tag: 'SecureStorage');
    } catch (e) {
      AppLogger.e('Failed to clear auth tokens', tag: 'SecureStorage', error: e);
    }
  }
  
  // ============ Biometric Settings ============
  
  /// Enable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _keyBiometricEnabled, 
      value: enabled.toString(),
    );
  }
  
  /// Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }
  
  // ============ Session Management ============
  
  /// Update last activity timestamp
  Future<void> _updateLastActivity() async {
    await _storage.write(
      key: _keyLastActivity,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }
  
  /// Update last activity (call on user interaction)
  Future<void> recordActivity() async {
    await _updateLastActivity();
  }
  
  /// Get last activity timestamp
  Future<DateTime?> getLastActivity() async {
    final value = await _storage.read(key: _keyLastActivity);
    if (value == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(int.parse(value));
  }
  
  /// Check if session has expired (30 minutes inactivity)
  Future<bool> isSessionExpired({Duration timeout = const Duration(minutes: 30)}) async {
    final lastActivity = await getLastActivity();
    if (lastActivity == null) return true;
    
    final now = DateTime.now();
    return now.difference(lastActivity) > timeout;
  }
  
  /// Set session expiry time
  Future<void> setSessionExpiry(DateTime expiry) async {
    await _storage.write(
      key: _keySessionExpiry,
      value: expiry.millisecondsSinceEpoch.toString(),
    );
  }
  
  /// Clear all stored data
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      AppLogger.d('All secure storage cleared', tag: 'SecureStorage');
    } catch (e) {
      AppLogger.e('Failed to clear secure storage', tag: 'SecureStorage', error: e);
    }
  }
}
