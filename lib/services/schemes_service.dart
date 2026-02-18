import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../models/scheme_model.dart';
import '../models/application_model.dart';

class SchemesService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final String _schemesTable = 'schemes';
  final String _applicationsTable = 'applications';

  // Get all schemes or filter by state/district
  Future<List<SchemeModel>> getSchemes({
    String? state,
    String? district,
    String? searchQuery,
  }) async {
    // Use the most basic query without filters
    final response = await _supabaseClient
        .from(_schemesTable)
        .select()
        .order('created_at', ascending: false);

    // Filter in Dart instead of at the database level
    return (response as List)
        .map((scheme) => SchemeModel.fromMap(scheme))
        .where((scheme) {
          bool matches = true;
          
          // Apply state filter
          if (state != null && state.isNotEmpty) {
            matches = matches && scheme.applicableState == state;
          }
          
          // Apply district filter: show only schemes for the selected district, or those available state-wide
          if (district != null && district.isNotEmpty) {
            if (scheme.applicableDistrict.isNotEmpty) {
              matches = matches && scheme.applicableDistrict == district;
            } else {
              matches = matches && true; // state-wide scheme
            }
          }
          
          // Apply search filter (case insensitive)
          if (searchQuery != null && searchQuery.isNotEmpty) {
            matches = matches && 
                scheme.schemeName.toLowerCase().contains(searchQuery.toLowerCase());
          }
          
          return matches;
        })
        .toList();
  }

  // Get a single scheme by ID
  Future<SchemeModel> getSchemeById(String id) async {
    final response = await _supabaseClient
        .from(_schemesTable)
        .select();
        
    // Find the scheme with matching ID
    final scheme = (response as List).firstWhere(
      (scheme) => scheme['id'] == id,
      orElse: () => throw Exception('Scheme not found'),
    );

    return SchemeModel.fromMap(scheme);
  }

  // Create a new application
  Future<ApplicationModel> createApplication(
      ApplicationModel application) async {
    final response = await _supabaseClient
        .from(_applicationsTable)
        .insert(application.toCreateMap())
        .select()
        .single();

    return ApplicationModel.fromMap(response);
  }

  // Get user's applications
  Future<List<ApplicationModel>> getUserApplications() async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      return [];
    }
    
    final response = await _supabaseClient
        .from(_applicationsTable)
        .select('*, schemes(scheme_name, department_name)')
        .order('submitted_at', ascending: false);
        
    // Filter for the current user's applications
    final userApplications = (response as List).where((app) => app['user_id'] == userId).toList();
    
    return userApplications.map((app) {
      final Map<String, dynamic> flattenedMap = {
        ...app,
        'scheme_name': app['schemes']['scheme_name'],
        'department_name': app['schemes']['department_name'],
      };
      return ApplicationModel.fromMap(flattenedMap);
    }).toList();
  }

  // Upload documents for application
  Future<List<String>> uploadApplicationDocuments(List<File> files) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    List<String> uploadedFileUrls = [];

    for (final file in files) {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final filePath = 'applications/$userId/$fileName';

      await _supabaseClient.storage
          .from('application-documents')
          .upload(filePath, file);

      final fileUrl = _supabaseClient.storage
          .from('application-documents')
          .getPublicUrl(filePath);

      uploadedFileUrls.add(fileUrl);
    }

    return uploadedFileUrls;
  }

  // Check if user is admin
  Future<bool> isUserAdmin() async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      return false;
    }
    
    final response = await _supabaseClient
        .from('user_profiles')
        .select('is_admin');
        
    // Filter for the current user's profile
    final userProfile = (response as List).firstWhere(
      (profile) => profile['id'] == userId,
      orElse: () => {'is_admin': false},
    );

    return userProfile['is_admin'] ?? false;
  }

  // Admin: Create a new scheme
  Future<SchemeModel> createScheme(SchemeModel scheme) async {
    if (!await isUserAdmin()) {
      throw Exception('Unauthorized: Only admins can create schemes');
    }

    final response = await _supabaseClient
        .from(_schemesTable)
        .insert(scheme.toMap())
        .select();

    // Since we expect only one scheme to be created, take the first one
    return SchemeModel.fromMap(response[0]);
  }

  // Admin: Update a scheme
  Future<SchemeModel> updateScheme(SchemeModel scheme) async {
    if (!await isUserAdmin()) {
      throw Exception('Unauthorized: Only admins can update schemes');
    }

    // First verify the scheme exists
    final existingSchemes = await _supabaseClient
        .from(_schemesTable)
        .select();
    
    final exists = (existingSchemes as List).any((s) => s['id'] == scheme.id);
    if (!exists) {
      throw Exception('Scheme not found');
    }
    
    // Update the scheme
    final response = await _supabaseClient
        .from(_schemesTable)
        .update(scheme.toMap())
        .select();
    
    // If empty response, get the updated scheme separately
    if ((response as List).isEmpty) {
      final updated = await getSchemeById(scheme.id);
      return updated;
    }
    
    return SchemeModel.fromMap(response[0]);
  }

  // Admin: Delete a scheme
  Future<void> deleteScheme(String id) async {
    if (!await isUserAdmin()) {
      throw Exception('Unauthorized: Only admins can delete schemes');
    }

    // First verify the scheme exists
    final existingSchemes = await _supabaseClient
        .from(_schemesTable)
        .select();
    
    final exists = (existingSchemes as List).any((s) => s['id'] == id);
    if (!exists) {
      throw Exception('Scheme not found');
    }
    
    // Delete the scheme
    await _supabaseClient
        .from(_schemesTable)
        .delete();
  }

  // Admin: Get all applications
  Future<List<ApplicationModel>> getAllApplications({String? status}) async {
    if (!await isUserAdmin()) {
      throw Exception('Unauthorized: Only admins can access all applications');
    }
    
    final response = await _supabaseClient
        .from(_applicationsTable)
        .select('*, schemes(scheme_name, department_name), user_profiles(display_name)')
        .order('submitted_at', ascending: false);
    
    // Filter by status in Dart if specified
    final filteredApps = status != null && status.isNotEmpty
        ? (response as List).where((app) => app['status'] == status).toList()
        : response as List;
        
    return filteredApps.map((app) {
      final Map<String, dynamic> flattenedMap = {
        ...app,
        'scheme_name': app['schemes']['scheme_name'],
        'department_name': app['schemes']['department_name'],
        'applicant_name': app['user_profiles']['display_name'],
      };
      return ApplicationModel.fromMap(flattenedMap);
    }).toList();
  }

  // Admin: Update application status
  Future<ApplicationModel> updateApplicationStatus(
      String id, String status, String? remarks) async {
    if (!await isUserAdmin()) {
      throw Exception(
          'Unauthorized: Only admins can update application status');
    }

    // First verify the application exists
    final existingApplications = await _supabaseClient
        .from(_applicationsTable)
        .select();
    
    final exists = (existingApplications as List).any((a) => a['id'] == id);
    if (!exists) {
      throw Exception('Application not found');
    }
    
    // Update the application
    await _supabaseClient
        .from(_applicationsTable)
        .update({
          'status': status,
          'remarks': remarks,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select();
    
    // Get the updated application
    final updatedApplications = await _supabaseClient
        .from(_applicationsTable)
        .select('*, schemes(scheme_name, department_name), user_profiles(display_name)');
    
    final updated = (updatedApplications as List).firstWhere(
      (a) => a['id'] == id,
      orElse: () => throw Exception('Application not found after update'),
    );
    
    return ApplicationModel.fromMap(updated);
  }

  // Public method to get current user id
  String? getCurrentUserId() {
    return _supabaseClient.auth.currentUser?.id;
  }
}
