class UserReportModel {
  final String id;
  final String userId;
  final String subject;
  final String description;
  final String status; // 'pending', 'in_progress', 'resolved', 'closed'
  final DateTime createdAt;
  final DateTime updatedAt;

  UserReportModel({
    this.id = '',
    required this.userId,
    required this.subject,
    required this.description,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserReportModel.fromJson(Map<String, dynamic> json) {
    return UserReportModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject': subject,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
