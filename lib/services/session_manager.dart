import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kisan_veer/services/secure_storage_service.dart';
import 'package:kisan_veer/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Session manager for automatic logout and security
/// Handles session timeout and token refresh
class SessionManager {
  final SecureStorageService _secureStorage = SecureStorageService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Timer? _inactivityTimer;
  Timer? _tokenRefreshTimer;
  
  // Session timeout duration (30 minutes)
  static const Duration sessionTimeout = Duration(minutes: 30);
  
  // Token refresh interval (50 minutes - before 1 hour expiry)
  static const Duration tokenRefreshInterval = Duration(minutes: 50);
  
  // Singleton pattern
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();
  
  // Callback for session expiry
  VoidCallback? onSessionExpired;
  
  /// Initialize session management
  Future<void> initialize({VoidCallback? onExpired}) async {
    onSessionExpired = onExpired;
    
    // Check if session is already expired
    final isExpired = await _secureStorage.isSessionExpired(timeout: sessionTimeout);
    if (isExpired) {
      AppLogger.w('Session expired on app start', tag: 'Session');
      await handleSessionExpired();
      return;
    }
    
    // Start monitoring
    _startInactivityTimer();
    _startTokenRefreshTimer();
    
    AppLogger.d('Session manager initialized', tag: 'Session');
  }
  
  /// Record user activity (call on user interaction)
  Future<void> recordActivity() async {
    await _secureStorage.recordActivity();
    _resetInactivityTimer();
  }
  
  /// Start inactivity timer
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(sessionTimeout, () async {
      AppLogger.w('Session timed out due to inactivity', tag: 'Session');
      await handleSessionExpired();
    });
  }
  
  /// Reset inactivity timer (call on user activity)
  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _startInactivityTimer();
  }
  
  /// Start token refresh timer
  void _startTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(tokenRefreshInterval, (_) async {
      await _refreshToken();
    });
  }
  
  /// Refresh the authentication token
  Future<void> _refreshToken() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return;
      
      // Check if token is about to expire
      final expiresAt = session.expiresAt;
      if (expiresAt != null) {
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
        final now = DateTime.now();
        
        // Refresh if expiring in less than 10 minutes
        if (expiryTime.difference(now).inMinutes < 10) {
          final response = await _supabase.auth.refreshSession();
          if (response.session != null) {
            // Save new tokens
            await _secureStorage.saveAuthTokens(
              accessToken: response.session!.accessToken,
              refreshToken: response.session!.refreshToken ?? '',
              userId: response.session!.user.id,
              email: response.session!.user.email,
            );
            AppLogger.d('Token refreshed successfully', tag: 'Session');
          }
        }
      }
    } catch (e) {
      AppLogger.e('Token refresh failed', tag: 'Session', error: e);
    }
  }
  
  /// Handle session expiry
  Future<void> handleSessionExpired() async {
    _stopAllTimers();
    onSessionExpired?.call();
  }
  
  /// Handle successful login - save tokens and start session
  Future<void> startSession(Session session) async {
    await _secureStorage.saveAuthTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken ?? '',
      userId: session.user.id,
      email: session.user.email,
    );
    
    _startInactivityTimer();
    _startTokenRefreshTimer();
    
    AppLogger.d('Session started for ${session.user.email}', tag: 'Session');
  }
  
  /// End session (logout)
  Future<void> endSession() async {
    _stopAllTimers();
    await _secureStorage.clearAuthTokens();
    AppLogger.d('Session ended', tag: 'Session');
  }
  
  /// Stop all timers
  void _stopAllTimers() {
    _inactivityTimer?.cancel();
    _tokenRefreshTimer?.cancel();
    _inactivityTimer = null;
    _tokenRefreshTimer = null;
  }
  
  /// Check if user has valid session
  Future<bool> hasValidSession() async {
    // Check if we have stored tokens
    final hasCredentials = await _secureStorage.hasStoredCredentials();
    if (!hasCredentials) return false;
    
    // Check if session is expired
    final isExpired = await _secureStorage.isSessionExpired(timeout: sessionTimeout);
    if (isExpired) return false;
    
    // Check Supabase session
    final session = _supabase.auth.currentSession;
    return session != null;
  }
  
  /// Dispose session manager
  void dispose() {
    _stopAllTimers();
  }
}
