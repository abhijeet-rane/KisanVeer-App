import 'dart:convert';

class ApplicationModel {
  final String id;
  final String userId;
  final String schemeId;
  final String name;
  final String phoneNumber;
  final String state;
  final String district;
  final double landholding;
  final String casteCategory;
  final List<String> uploadedFiles;
  final String status;
  final String? remarks;
  final DateTime submittedAt;
  final DateTime updatedAt;
  final String? schemeName;
  final String? departmentName;

  ApplicationModel({
    required this.id,
    required this.userId,
    required this.schemeId,
    required this.name,
    required this.phoneNumber,
    required this.state,
    required this.district,
    required this.landholding,
    required this.casteCategory,
    required this.uploadedFiles,
    required this.status,
    this.remarks,
    required this.submittedAt,
    required this.updatedAt,
    this.schemeName,
    this.departmentName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'scheme_id': schemeId,
      'name': name,
      'phone_number': phoneNumber,
      'state': state,
      'district': district,
      'landholding': landholding,
      'caste_category': casteCategory,
      'uploaded_files': uploadedFiles,
      'status': status,
      'remarks': remarks,
      'submitted_at': submittedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'user_id': userId,
      'scheme_id': schemeId,
      'name': name,
      'phone_number': phoneNumber,
      'state': state,
      'district': district,
      'landholding': landholding,
      'caste_category': casteCategory,
      'uploaded_files': uploadedFiles,
      'status': 'Pending',
    };
  }

  factory ApplicationModel.fromMap(Map<String, dynamic> map) {
    return ApplicationModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      schemeId: map['scheme_id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phone_number'] ?? '',
      state: map['state'] ?? '',
      district: map['district'] ?? '',
      landholding: (map['landholding'] is int)
          ? (map['landholding'] as int).toDouble()
          : (map['landholding'] ?? 0.0),
      casteCategory: map['caste_category'] ?? '',
      uploadedFiles: List<String>.from(map['uploaded_files'] ?? []),
      status: map['status'] ?? 'Pending',
      remarks: map['remarks'],
      submittedAt: DateTime.parse(map['submitted_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      schemeName: map['scheme_name'],
      departmentName: map['department_name'],
    );
  }

  String toJson() => json.encode(toMap());

  factory ApplicationModel.fromJson(String source) => ApplicationModel.fromMap(json.decode(source));
}
