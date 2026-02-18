import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static UserProfile defaultProfile() {
    return UserProfile(id: "unknown", displayName: "Unknown Admin", createdAt: DateTime.now());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Post {
  final String id;
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  final List<String> imageUrls;
  final UserProfile author;
  final DateTime createdAt;
  int likesCount;
  int commentsCount;
  bool isLikedByUser;
  bool isPinned;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.tags,
    required this.imageUrls,
    required this.author,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLikedByUser = false,
    this.isPinned = false,
  });

  factory Post.fromJson(Map<String, dynamic> json,
      {required UserProfile author}) {
    return Post(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      tags: List<String>.from(json['tags'] as List),
      imageUrls: List<String>.from(json['image_urls'] as List),
      author: author,
      createdAt: DateTime.parse(json['created_at'] as String),
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isPinned: json['is_pinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'tags': tags,
      'image_urls': imageUrls,
      'user_id': author.id,
      'created_at': createdAt.toIso8601String(),
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_pinned': isPinned,
    };
  }
}

class Comment {
  final String id;
  final String content;
  final UserProfile author;
  final DateTime createdAt;
  int likesCount;
  bool isLikedByUser;

  Comment({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
    this.likesCount = 0,
    this.isLikedByUser = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json,
      {required UserProfile author}) {
    return Comment(
      id: json['id'] as String,
      content: json['content'] as String,
      author: author,
      createdAt: DateTime.parse(json['created_at'] as String),
      likesCount: json['likes_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'user_id': author.id,
      'created_at': createdAt.toIso8601String(),
      'likes_count': likesCount,
    };
  }
}

class PostCategory {
  final String name;
  final String? description;
  final String? iconName;
  final int postsCount;

  PostCategory({
    required this.name,
    this.description,
    this.iconName,
    this.postsCount = 0,
  });

  factory PostCategory.fromJson(Map<String, dynamic> json) {
    return PostCategory(
      name: json['name'] as String,
      description: json['description'] as String?,
      iconName: json['icon_name'] as String?,
      postsCount: json['posts_count'] as int? ?? 0,
    );
  }
}

class Community {
  final String id;
  final String name;
  final String description;
  final UserProfile admin;
  final bool isPrivate;
  final int memberCount;
  final int postCount;
  final String? posterImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  bool isMember;
  bool hasRequestedToJoin;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.admin,
    required this.isPrivate,
    required this.memberCount,
    required this.postCount,
    this.posterImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isMember = false,
    this.hasRequestedToJoin = false,
  });

  factory Community.fromJson(Map<String, dynamic>? json, {UserProfile? admin}) {
    if (json == null) {
      throw ArgumentError("Received null JSON for Community");
    }

    Map<String, dynamic>? adminJson = json['admin_profiles'];
    return Community(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      admin: admin ??
          (adminJson != null && adminJson is Map<String, dynamic>
              ? UserProfile.fromJson(adminJson)
              : UserProfile.defaultProfile()), // Use default if null
      isPrivate: json['is_private'] as bool? ?? false,
      memberCount: json['member_count'] as int? ?? 0,
      postCount: json['post_count'] as int? ?? 0,
      posterImageUrl: json['poster_image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'admin_id': admin.id,
      'is_private': isPrivate,
      'member_count': memberCount,
      'post_count': postCount,
      'poster_image_url': posterImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CommunityThread {
  final String id;
  final String title;
  final String category;
  final UserProfile creator;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  CommunityThread({
    required this.id,
    required this.title,
    required this.category,
    required this.creator,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
  });

  factory CommunityThread.fromJson(Map<String, dynamic> json, {UserProfile? creator}) {
    return CommunityThread(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      creator: creator ?? UserProfile.fromJson(json['creator_profiles']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      messageCount: json['message_count'] as int? ?? 0,
    );
  }
}

class CommunityMessage {
  final String id;
  final String? content;
  final List<String> imageUrls;
  final UserProfile sender;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? replyToId;
  final CommunityMessage? replyTo;
  final String? threadId;

  CommunityMessage({
    required this.id,
    this.content,
    required this.imageUrls,
    required this.sender,
    required this.createdAt,
    required this.updatedAt,
    this.replyToId,
    this.replyTo,
    this.threadId,
  });

  factory CommunityMessage.fromJson(Map<String, dynamic> json, {UserProfile? sender, CommunityMessage? replyTo}) {
    return CommunityMessage(
      id: json['id'] as String,
      content: json['content'] as String?,
      imageUrls: List<String>.from(json['image_urls'] as List? ?? []),
      sender: sender ?? UserProfile.fromJson(json['sender_profiles']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      replyToId: json['reply_to'] as String?,
      replyTo: replyTo,
      threadId: json['thread_id'] as String?,
    );
  }
}

class JoinRequest {
  final String id;
  final String communityId;
  final UserProfile user;
  final String status;
  final DateTime requestedAt;
  final DateTime? processedAt;

  JoinRequest({
    required this.id,
    required this.communityId,
    required this.user,
    required this.status,
    required this.requestedAt,
    this.processedAt,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json, {UserProfile? user}) {
    return JoinRequest(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      user: user ?? UserProfile.fromJson(json['user_profiles']),
      status: json['status'] as String,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
    );
  }
}
