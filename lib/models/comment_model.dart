class CommentModel {
  final String id;
  final String content;
  final String postId;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final int likeCount;
  final List<String> likedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommentModel({
    required this.id,
    required this.content,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl = '',
    required this.likeCount,
    required this.likedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create an empty comment
  factory CommentModel.empty() {
    return CommentModel(
      id: '',
      content: '',
      postId: '',
      userId: '',
      userName: '',
      likeCount: 0,
      likedBy: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  // Convert from JSON for local storage
  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      postId: json['postId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userPhotoUrl: json['userPhotoUrl'] ?? '',
      likeCount: json['likeCount'] ?? 0,
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
      'content': content,
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'likeCount': likeCount,
      'likedBy': likedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  CommentModel copyWith({
    String? id,
    String? content,
    String? postId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    int? likeCount,
    List<String>? likedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommentModel(
      id: id ?? this.id,
      content: content ?? this.content,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CommentModel{id: $id, userId: $userId, postId: $postId}';
  }
}
