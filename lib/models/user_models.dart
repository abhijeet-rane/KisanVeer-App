// lib/models/user_models.dart

class UserProfile {
  final String id;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? avatar;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final bool? isSeller;
  final String? about;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? location;  // Added for product details screen
  
  // Getters for compatibility with existing code
  String? get avatarUrl => avatar;
  String? get displayName => fullName;

  UserProfile({
    required this.id,
    this.fullName,
    this.phone,
    this.email,
    this.avatar,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.isSeller,
    this.about,
    this.createdAt,
    this.updatedAt,
    this.location,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] != null ? json['id'].toString() : '',
      fullName: (json['display_name'] ?? json['full_name'])?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      avatar: json['avatar']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      pincode: json['pincode']?.toString(),
      isSeller: json['is_seller'] as bool?,
      about: json['about']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      location: json['location']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
    };
    
    if (fullName != null) data['full_name'] = fullName;
    if (phone != null) data['phone'] = phone;
    if (email != null) data['email'] = email;
    if (avatar != null) data['avatar'] = avatar;
    if (address != null) data['address'] = address;
    if (city != null) data['city'] = city;
    if (state != null) data['state'] = state;
    if (pincode != null) data['pincode'] = pincode;
    if (isSeller != null) data['is_seller'] = isSeller;
    if (about != null) data['about'] = about;
    if (createdAt != null) data['created_at'] = createdAt!.toIso8601String();
    if (updatedAt != null) data['updated_at'] = updatedAt!.toIso8601String();
    
    return data;
  }
}
