import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kisan_veer/services/secure_storage_service.dart';
import 'package:kisan_veer/utils/app_logger.dart';

/// Biometric authentication service for fingerprint/face ID login
/// Works with Android fingerprint and iOS Face ID/Touch ID
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureStorageService _secureStorage = SecureStorageService();
  
  // Singleton pattern
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();
  
  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      AppLogger.e('Error checking device support', tag: 'Biometric', error: e);
      return false;
    }
  }
  
  /// Check if biometrics are available and enrolled
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      AppLogger.e('Error checking biometrics', tag: 'Biometric', error: e);
      return false;
    }
  }
  
  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      AppLogger.e('Error getting available biometrics', tag: 'Biometric', error: e);
      return [];
    }
  }
  
  /// Check if biometric login is available and enabled
  Future<bool> isBiometricLoginAvailable() async {
    final isSupported = await isDeviceSupported();
    final canCheck = await canCheckBiometrics();
    final isEnabled = await _secureStorage.isBiometricEnabled();
    final hasCredentials = await _secureStorage.hasStoredCredentials();
    
    return isSupported && canCheck && isEnabled && hasCredentials;
  }
  
  /// Authenticate user with biometrics
  /// Returns true if authentication successful, false otherwise
  Future<BiometricResult> authenticate({
    String reason = 'Authenticate to access Kisan Veer',
    bool biometricOnly = false,
  }) async {
    try {
      // Check if biometrics are available
      final canCheck = await canCheckBiometrics();
      if (!canCheck) {
        return BiometricResult.notAvailable;
      }
      
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
        ),
      );
      
      if (authenticated) {
        AppLogger.success('Biometric authentication successful', tag: 'Biometric');
        return BiometricResult.success;
      } else {
        AppLogger.w('Biometric authentication failed', tag: 'Biometric');
        return BiometricResult.failed;
      }
    } on PlatformException catch (e) {
      AppLogger.e('Biometric auth error', tag: 'Biometric', error: e);
      
      switch (e.code) {
        case auth_error.notEnrolled:
          return BiometricResult.notEnrolled;
        case auth_error.lockedOut:
        case auth_error.permanentlyLockedOut:
          return BiometricResult.lockedOut;
        case auth_error.notAvailable:
          return BiometricResult.notAvailable;
        default:
          return BiometricResult.error;
      }
    } catch (e) {
      AppLogger.e('Unexpected biometric error', tag: 'Biometric', error: e);
      return BiometricResult.error;
    }
  }
  
  /// Enable biometric authentication for the user
  Future<bool> enableBiometric() async {
    try {
      // First authenticate to confirm identity
      final result = await authenticate(
        reason: 'Confirm your identity to enable biometric login',
      );
      
      if (result == BiometricResult.success) {
        // Store locally
        await _secureStorage.setBiometricEnabled(true);
        
        // Sync to Supabase
        await _syncBiometricToSupabase(true);
        
        AppLogger.success('Biometric login enabled', tag: 'Biometric');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.e('Failed to enable biometric', tag: 'Biometric', error: e);
      return false;
    }
  }
  
  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    await _secureStorage.setBiometricEnabled(false);
    await _syncBiometricToSupabase(false);
    AppLogger.d('Biometric login disabled', tag: 'Biometric');
  }
  
  /// Sync biometric setting to Supabase
  Future<void> _syncBiometricToSupabase(bool enabled) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        AppLogger.w('Cannot sync biometric - user not logged in', tag: 'Biometric');
        return;
      }
      
      await supabase.from('user_security_settings').upsert({
        'user_id': userId,
        'biometric_enabled': enabled,
        'biometric_last_used': enabled ? DateTime.now().toIso8601String() : null,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
      
      AppLogger.d('Biometric setting synced to Supabase: $enabled', tag: 'Biometric');
    } catch (e) {
      AppLogger.e('Failed to sync biometric to Supabase', tag: 'Biometric', error: e);
    }
  }
  
  /// Check if biometric is enabled by user
  Future<bool> isBiometricEnabled() async {
    return _secureStorage.isBiometricEnabled();
  }
  
  /// Get biometric type string for display
  Future<String> getBiometricTypeName() async {
    final types = await getAvailableBiometrics();
    
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (types.contains(BiometricType.strong)) {
      return 'Biometric';
    }
    return 'Biometric';
  }
  
  /// Stop any ongoing authentication
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      AppLogger.e('Error stopping authentication', tag: 'Biometric', error: e);
    }
  }
}

/// Result of biometric authentication
enum BiometricResult {
  success,
  failed,
  notAvailable,
  notEnrolled,
  lockedOut,
  error,
}

/// Extension for user-friendly messages
extension BiometricResultMessage on BiometricResult {
  String get message => switch (this) {
    BiometricResult.success => 'Authentication successful',
    BiometricResult.failed => 'Authentication failed. Please try again.',
    BiometricResult.notAvailable => 'Biometric authentication is not available on this device.',
    BiometricResult.notEnrolled => 'No biometrics enrolled. Please set up fingerprint or face recognition in your device settings.',
    BiometricResult.lockedOut => 'Too many failed attempts. Please try again later or use your password.',
    BiometricResult.error => 'An error occurred. Please try again.',
  };
  
  bool get isSuccess => this == BiometricResult.success;
}
