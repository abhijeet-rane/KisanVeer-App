import 'dart:convert';

class SchemeModel {
  final String id;
  final String schemeName;
  final String departmentName;
  final String overview;
  final String benefits;
  final String eligibility;
  final String requiredDocuments;
  final String? viewBenefitsLink;
  final String? mahadbtApplyLink;
  final String applicableState;
  final String applicableDistrict;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  SchemeModel({
    required this.id,
    required this.schemeName,
    required this.departmentName,
    required this.overview,
    required this.benefits,
    required this.eligibility,
    required this.requiredDocuments,
    this.viewBenefitsLink,
    this.mahadbtApplyLink,
    this.applicableState = '',
    this.applicableDistrict = '',
    this.category = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scheme_name': schemeName,
      'department_name': departmentName,
      'overview': overview,
      'benefits': benefits,
      'eligibility': eligibility,
      'required_documents': requiredDocuments,
      'view_benefits_link': viewBenefitsLink,
      'mahadbt_apply_link': mahadbtApplyLink,
      'applicable_state': applicableState,
      'applicable_district': applicableDistrict,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SchemeModel.fromMap(Map<String, dynamic> map) {
    print('Parsing SchemeModel from map:');
    print(map);
    return SchemeModel(
      id: map['id'] ?? '',
      schemeName: map['scheme_name'] ?? '',
      departmentName: map['department_name'] ?? '',
      overview: map['overview'] ?? '',
      benefits: map['benefits'] ?? '',
      eligibility: map['eligibility'] ?? '',
      requiredDocuments: map['required_documents'] ?? '',
      viewBenefitsLink: map['view_benefits_link'],
      mahadbtApplyLink: map['mahadbt_apply_link'],
      applicableState: map['applicable_state'] ?? '',
      applicableDistrict: map['applicable_district'] ?? '',
      category: map['category'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
    );
  }

  factory SchemeModel.fromJson(Map<String, dynamic> json) {
    return SchemeModel(
      id: json['id'] ?? '',
      schemeName: json['scheme_name'] ?? '',
      departmentName: json['department_name'] ?? '',
      overview: json['overview'] ?? '',
      benefits: json['benefits'] ?? '',
      eligibility: json['eligibility'] ?? '',
      requiredDocuments: json['required_documents'] ?? '',
      viewBenefitsLink: json['view_benefits_link'],
      mahadbtApplyLink: json['mahadbt_apply_link'],
      applicableState: json['applicable_state'] ?? '',
      applicableDistrict: json['applicable_district'] ?? '',
      category: json['category'] ?? '',
      createdAt: DateTime.parse((json['created_at'] ?? '').replaceFirst(' ', 'T')),
      updatedAt: DateTime.parse((json['updated_at'] ?? json['created_at'] ?? '').replaceFirst(' ', 'T')),
    );
  }

  String toJson() => json.encode(toMap());

  List<String> getRequiredDocumentsList() {
    // Split on both commas and newlines, and trim whitespace
    return requiredDocuments
        .replaceAll('\\n', '\n')
        .split(RegExp(r'[\n,]+'))
        .map((doc) => doc.trim())
        .where((doc) => doc.isNotEmpty)
        .toList();
  }
}
