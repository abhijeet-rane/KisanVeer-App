import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:kisan_veer/models/user_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kisan_veer/utils/app_logger.dart';
import 'package:kisan_veer/services/secure_storage_service.dart';

class AuthService {
  final supabase = Supabase.instance.client;
  final SecureStorageService _secureStorage = SecureStorageService();
  bool _listenerInitialized = false;

  // Get current user
  User? get currentUser => supabase.auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => supabase.auth.currentUser != null;
  
  /// Initialize auth state listener to save session on any login
  void initAuthStateListener() {
    if (_listenerInitialized) return;
    _listenerInitialized = true;
    
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      if (event == AuthChangeEvent.signedIn && session != null) {
        // Save session for biometric on ANY sign in
        _saveSessionForBiometric(session);
        AppLogger.d('Session saved on auth state change', tag: 'Auth');
      } else if (event == AuthChangeEvent.signedOut) {
        // Clear tokens on sign out
        _secureStorage.clearAuthTokens();
        AppLogger.d('Tokens cleared on sign out', tag: 'Auth');
      }
    });
  }

  // Register with email and password
  Future<void> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String phone,
    String userType,
  ) async {
    try {
      // Register user with Supabase Auth
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': name,
          'phone': phone,
          'user_type': userType,
          'provider': 'email',
        },
      );

      if (response.user == null) {
        throw Exception('Registration failed');
      }

      // Send new user details to Supabase function
      await _sendUserToSupabase(response.session);

      // If you need to add extra data to a separate table in Supabase
      await supabase.from('user_profiles').insert({
        'id': response.user!.id,
        'display_name': name,
        'email': email,
        'phone': phone,
        'user_type': userType,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Create initial user preferences
      await supabase.from('user_preferences').insert({
        'id': response.user!.id,
        'user_id': response.user!.id,
        'crops': [],
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Function to send new user details to Supabase function
  Future<void> _sendUserToSupabase(Session? session) async {
    if (session == null) return;

    final url = Uri.parse('https://wmqpftdxdduhbdsjybzu.supabase.co/functions/v1/handle-new-user');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({
        'event': 'INSERT',
        'session': {
          'user_id': session.user.id,
          'email': session.user.email,
        },
      }),
    );

    if (response.statusCode != 200) {
      AppLogger.e('Error sending user data', tag: 'Auth', error: response.body);
    }
  }

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Authentication failed');
      }
      
      // Save session for biometric login
      if (response.session != null) {
        await _saveSessionForBiometric(response.session!);
      }
    } catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  /// Save session tokens for biometric login restoration
  Future<void> _saveSessionForBiometric(Session session) async {
    try {
      final secureStorage = SecureStorageService();
      await secureStorage.saveAuthTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken ?? '',
        userId: session.user.id,
        email: session.user.email,
      );
      AppLogger.d('Session saved for biometric login', tag: 'Auth');
    } catch (e) {
      AppLogger.e('Failed to save session for biometric', tag: 'Auth', error: e);
    }
  }
  
  /// Restore session for biometric login
  /// Call this after successful biometric authentication
  Future<bool> restoreSessionForBiometric() async {
    try {
      final secureStorage = SecureStorageService();
      final refreshToken = await secureStorage.getRefreshToken();
      
      if (refreshToken == null || refreshToken.isEmpty) {
        AppLogger.w('No refresh token found for biometric login', tag: 'Auth');
        return false;
      }
      
      // Refresh the session using stored refresh token
      final response = await supabase.auth.setSession(refreshToken);
      
      if (response.session != null) {
        // Update stored tokens with new session
        await _saveSessionForBiometric(response.session!);
        AppLogger.success('Session restored for biometric login', tag: 'Auth');
        return true;
      }
      
      return false;
    } catch (e) {
      AppLogger.e('Failed to restore session for biometric', tag: 'Auth', error: e);
      return false;
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.kisanveer.app://login-callback/',
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    // Clear tokens but keep biometric enabled setting
    // So user can still use biometric after re-logging in
    await _secureStorage.clearAuthTokens();
    // Don't clear biometric enabled - keep it persistent
    await supabase.auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get current user model
  Future<UserModel> getCurrentUserModel() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      final response = await supabase
          .from('user_profiles')
          .select('*')
          .eq('id', userId)
          .single();

      return UserModel.fromJson({
        'uid': userId,
        'email': supabase.auth.currentUser?.email,
        'name': response['display_name'],
        'phoneNumber': response['phone'],
        'photoUrl': response['profile_image_url'],
        'userType': response['user_type'],
        'address': response['location'],
        'createdAt': response['created_at'],
        'lastActive': response['updated_at'],
        'crops': await _getUserCrops(userId),
      });
    } catch (e) {
      throw 'Failed to get user data: $e';
    }
  }

  // Get user crops
  Future<List<String>> _getUserCrops(String userId) async {
    try {
      final response = await supabase
          .from('user_preferences')
          .select('crops')
          .eq('user_id', userId)
          .single();
      return List<String>.from(response['crops'] ?? []);
    } catch (e) {
      return [];
    }
  }

  // Update user crops
  Future<void> updateUserCrops(List<String> crops) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      await supabase.from('user_preferences').update({
        'crops': crops,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);

      // Notify listeners that crops have been updated
      _notifyUserDataChange();
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle auth errors with specific messages
  String _handleAuthException(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Invalid email or password. Please check your credentials and try again.';
        case 'Email not confirmed':
          return 'Please verify your email address before logging in.';
        case 'User not found':
          return 'No account found with this email. Please register first.';
        case 'Password is too weak':
          return 'Password is too weak. Please use a stronger password.';
        case 'Email already in use':
          return 'An account with this email already exists.';
        default:
          return 'Authentication error: ${error.message}';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  // Stream controller for user data changes
  final _userDataController = StreamController<void>.broadcast();
  Stream<void> get userDataStream => _userDataController.stream;

  void _notifyUserDataChange() {
    _userDataController.add(null);
  }

  void dispose() {
    _userDataController.close();
  }
}
