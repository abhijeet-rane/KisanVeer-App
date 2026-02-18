import 'dart:async';
import 'dart:io';
import 'package:kisan_veer/models/privacy_settings_model.dart';
import 'package:kisan_veer/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  // Get the current user's profile from Supabase
  Future<UserModel?> getUserProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('user_profiles')
          .select('*')
          .eq('id', userId)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      // Map the database fields to the UserModel fields
      final userData = {
        'uid': userId.toString(),
        'email': _client.auth.currentUser!.email ?? '',
        'name': response['display_name']?.toString() ?? '',
        'phoneNumber': response['phone']?.toString() ?? '',
        'photoUrl': response['profile_image_url']?.toString() ?? '',
        'userType': response['user_type']?.toString() ?? 'farmer',
        'city': response['city']?.toString() ?? '',
        'pincode': response['pincode']?.toString() ?? '',
        'state': response['state']?.toString() ?? 'Maharashtra',
        'createdAt': response['created_at']?.toString() ??
            DateTime.now().toIso8601String(),
        'lastActive': response['updated_at']?.toString() ??
            DateTime.now().toIso8601String(),
        'address': response['location']?.toString() ?? '',
      };

      return UserModel.fromJson(userData);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(UserModel user) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      // Update in the user_profiles table
      await _client.from('user_profiles').update({
        'display_name': user.name,
        'phone': user.phoneNumber,
        'profile_image_url': user.photoUrl,
        'location': user.address,
        'city': user.city,
        'pincode': user.pincode,
        'state': user.state,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // Update crops in user_preferences
      await _client.from('user_preferences').update({
        // Store as Postgres array literal: '{crop1,crop2}'
        'crops': '{${user.crops.join(',')}}',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Upload profile image
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final fileExt = path.extension(imageFile.path);
      final fileName = '${userId}_${const Uuid().v4()}$fileExt';

      // Explicitly use the correct bucket name
      final bucketName = 'profile-images';

      // Upload the file to the bucket
      await _client.storage.from(bucketName).upload(
            'profiles/$fileName',
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Get the public URL of the uploaded image
      final imageUrl =
          _client.storage.from(bucketName).getPublicUrl('profiles/$fileName');

      // Update the user profile with the new image URL
      await _client.from('user_profiles').update({
        'profile_image_url': imageUrl,
      }).eq('id', userId);

      return imageUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Get Maharashtra crops
  List<String> getMaharashtraCrops() {
    return [
      'Rice',
      'Wheat',
      'Jowar',
      'Bajra',
      'Cotton',
      'Sugarcane',
      'Soybean',
      'Groundnut',
      'Turmeric',
      'Onion',
      'Potato',
      'Tomato',
      'Grapes',
      'Mango',
      'Banana',
      'Orange',
      'Pomegranate',
    ];
  }

  // Submit a user report/problem
  Future<bool> submitUserReport({
    required String category,
    required String subject,
    required String description,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      await _client.from('user_reports').insert({
        'user_id': userId,
        'category': category,
        'subject': subject,
        'description': description,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error submitting report: $e');
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      // Reauthenticate the user with their current password
      await _client.auth.signInWithPassword(
        email: _client.auth.currentUser!.email ?? '',
        password: currentPassword,
      );

      // Update to the new password
      await _client.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );

      // Log the password change
      await _client.from('password_change_log').insert({
        'user_id': userId,
        'changed_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  // Get privacy settings
  Future<PrivacySettingsModel> getPrivacySettings() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return PrivacySettingsModel();

      final response = await _client
          .from('user_privacy_settings')
          .select('*')
          .eq('user_id', userId)
          .single();

      return PrivacySettingsModel.fromJson(response);
    } catch (e) {
      print('Error getting privacy settings: $e');
      return PrivacySettingsModel();
    }
  }

  // Update privacy settings
  Future<bool> updatePrivacySettings(PrivacySettingsModel settings) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      await _client.from('user_privacy_settings').upsert({
        'user_id': userId,
        'share_location': settings.shareLocation,
        'show_online_status': settings.showOnlineStatus,
        'profile_visibility': settings.profileVisibility,
        'allow_messages_from': settings.allowMessagesFrom,
        'share_crop_data': settings.shareCropData,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error updating privacy settings: $e');
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      // First backup user data to deleted_accounts table
      final userData = await getUserProfile();
      if (userData != null) {
        await _client.from('deleted_accounts').insert({
          'user_id': userId,
          'email': userData.email,
          'name': userData.name,
          'deleted_at': DateTime.now().toIso8601String(),
          'reason': 'user_requested',
        });
      }

      // Delete user data from all tables
      await _client.from('user_profiles').delete().eq('id', userId);
      await _client.from('user_preferences').delete().eq('user_id', userId);
      await _client
          .from('user_privacy_settings')
          .delete()
          .eq('user_id', userId);

      // Finally delete the auth user
      await _client.auth.admin.deleteUser(userId);

      return true;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }
}
