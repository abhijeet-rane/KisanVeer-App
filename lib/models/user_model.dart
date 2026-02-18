/// User model for storing user information
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String phoneNumber;
  final String photoUrl;
  final String userType; // 'farmer' or 'buyer'
  final DateTime createdAt;
  final DateTime lastActive;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final List<String> crops; // Array of crops the user is growing
  
  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.userType,
    this.photoUrl = '',
    required this.createdAt,
    required this.lastActive,
    this.address = '',
    this.city = '',
    this.state = 'Maharashtra',
    this.pincode = '',
    this.crops = const [],
  });
  
  /// Create empty user
  factory UserModel.empty() {
    return UserModel(
      uid: '',
      email: '',
      name: '',
      phoneNumber: '',
      userType: 'farmer',
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
      address: '',
      city: '',
      state: 'Maharashtra',
      pincode: '',
      crops: const [],
    );
  }
  
  /// Convert JSON to UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> cropsList = [];
    if (json['crops'] != null) {
      if (json['crops'] is List) {
        cropsList = List<String>.from(json['crops']);
      } else if (json['crops'] is String) {
        cropsList = (json['crops'] as String)
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      // Prefer profile_image_url if present, else photoUrl, else ''
      photoUrl: json['profile_image_url'] ?? json['photoUrl'] ?? '',
      userType: json['userType'] ?? 'farmer',
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
      lastActive: json['lastActive'] != null 
        ? DateTime.parse(json['lastActive']) 
        : DateTime.now(),
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? 'Maharashtra',
      pincode: json['pincode'] ?? '',
      crops: cropsList,
    );
  }
  
  // Getter for profile image URL to maintain UI compatibility
  String get profileImageUrl => photoUrl;
  
  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'userType': userType,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'crops': crops,
    };
  }
  
  /// Create a copy of this UserModel with modified fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phoneNumber,
    String? photoUrl,
    String? userType,
    DateTime? createdAt,
    DateTime? lastActive,
    String? address,
    String? city,
    String? state,
    String? pincode,
    List<String>? crops,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      crops: crops ?? this.crops,
    );
  }
}
