class PostModel {
  final String id;
  final String title;
  final String content;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String category;
  final List<String> imageUrls;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final List<String> likedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.userId,
    required this.userName,
    this.userPhotoUrl = '',
    required this.category,
    required this.imageUrls,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    required this.likedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create an empty post
  factory PostModel.empty() {
    return PostModel(
      id: '',
      title: '',
      content: '',
      userId: '',
      userName: '',
      category: 'general',
      imageUrls: [],
      likeCount: 0,
      commentCount: 0,
      viewCount: 0,
      likedBy: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Convert from JSON for local storage
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userPhotoUrl: json['userPhotoUrl'] ?? '',
      category: json['category'] ?? 'general',
      imageUrls: json['imageUrls'] != null 
          ? List<String>.from(json['imageUrls']) 
          : [],
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
      likedBy: json['likedBy'] != null 
          ? List<String>.from(json['likedBy']) 
          : [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'category': category,
      'imageUrls': imageUrls,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'viewCount': viewCount,
      'likedBy': likedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a copy with modified fields
  PostModel copyWith({
    String? id,
    String? title,
    String? content,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? category,
    List<String>? imageUrls,
    int? likeCount,
    int? commentCount,
    int? viewCount,
    List<String>? likedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      viewCount: viewCount ?? this.viewCount,
      likedBy: likedBy ?? this.likedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PostModel{id: $id, title: $title, userId: $userId}';
  }
}
