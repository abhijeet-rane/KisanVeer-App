import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kisan_veer/models/community_models.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class CommunityService {
  final _supabase = Supabase.instance.client;

  // Posts
  Future<List<Post>> getPosts({String? category, String? searchQuery}) async {
    var query = _supabase.from('posts').select('*, user_profiles!inner(*)');

    if (category != null) {
      query = query.filter('category', 'eq', category);
    }

    if (searchQuery != null) {
      query = query
          .filter('title', 'ilike', '%$searchQuery%')
          .filter('content', 'ilike', '%$searchQuery%');
    }

    final response = await query;
    final userId = _supabase.auth.currentUser?.id;

    if (userId != null) {
      // Get liked post IDs for the current user
      final likedPosts = await _supabase
          .from('post_likes')
          .select('post_id')
          .eq('user_id', userId);

      final likedPostIds = likedPosts.map((row) => row['post_id']).toSet();

      return response.map((row) {
        return Post.fromJson(
          row,
          author: UserProfile.fromJson(row['user_profiles']),
        )..isLikedByUser = likedPostIds.contains(row['id']);
      }).toList();
    }

    return response
        .map((row) => Post.fromJson(
              row,
              author: UserProfile.fromJson(row['user_profiles']),
            ))
        .toList();
  }

  Future<Post> createPost({
    required String title,
    required String content,
    required String category,
    required List<String> tags,
    required List<String> imageUrls,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final userProfile = await _supabase
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .single();

    final data = await _supabase
        .from('posts')
        .insert({
          'user_id': userId,
          'title': title,
          'content': content,
          'category': category,
          'tags': tags,
          'image_urls': imageUrls,
        })
        .select('*, user_profiles(*)')
        .single();

    return Post.fromJson(
      data,
      author: UserProfile.fromJson(userProfile),
    );
  }

  Future<void> likePost(String postId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _supabase.from('post_likes').insert({
      'user_id': userId,
      'post_id': postId,
    });

    await _supabase.rpc('increment_post_likes', params: {'post_id': postId});
  }

  Future<void> unlikePost(String postId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _supabase
        .from('post_likes')
        .delete()
        .match({'user_id': userId, 'post_id': postId});

    await _supabase.rpc('decrement_post_likes', params: {'post_id': postId});
  }

  Future<String> uploadPostImage(File imageFile, String fileName) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final filePath = '$userId/$fileName';
    await _supabase.storage.from('post_images').upload(filePath, imageFile);

    final url = _supabase.storage.from('post_images').getPublicUrl(filePath);
    return url;
  }

  // Comments
  Future<List<Comment>> getComments(String postId) async {
    final response = await _supabase
        .from('post_comments')
        .select('*, user_profiles!fk_comments_user_profiles(*)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      // Get liked comment IDs for the current user
      final likedComments = await _supabase
          .from('comment_likes')
          .select('comment_id')
          .eq('user_id', userId);

      final likedCommentIds =
          likedComments.map((row) => row['comment_id']).toSet();

      return response.map((row) {
        return Comment.fromJson(
          row,
          author: UserProfile.fromJson(row['user_profiles']),
        )..isLikedByUser = likedCommentIds.contains(row['id']);
      }).toList();
    }

    return response
        .map((row) => Comment.fromJson(
              row,
              author: UserProfile.fromJson(row['user_profiles']),
            ))
        .toList();
  }

  Future<Comment> createComment(String postId, String content,
      {String? parentCommentId}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final userProfile = await _supabase
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .single();

    var uuid = Uuid();

    final commentData = {
      'id': uuid.v4(), // Generate a new UUID
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'parent_comment_id': parentCommentId ?? null,
      'created_at': DateTime.now().toIso8601String(),
    };

    final data = await _supabase
        .from('post_comments')
        .insert(commentData)
        .select('*, user_profiles(*)')
        .single();

    await _supabase.rpc('increment_post_comments', params: {'post_id': postId});

    return Comment.fromJson(
      data,
      author: UserProfile.fromJson(data['user_profiles']),
    );
  }

  Future<void> likeComment(String commentId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _supabase.from('comment_likes').insert({
      'user_id': userId,
      'comment_id': commentId,
      'created_at': DateTime.now().toIso8601String(),
    });

    await _supabase
        .rpc('increment_comment_likes', params: {'comment_id': commentId});
  }

  Future<void> unlikeComment(String commentId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _supabase
        .from('comment_likes')
        .delete()
        .match({'user_id': userId, 'comment_id': commentId});

    await _supabase
        .rpc('decrement_comment_likes', params: {'comment_id': commentId});
  }

  // Categories
  Future<List<PostCategory>> getCategories() async {
    final response = await _supabase
        .from('post_categories')
        .select()
        .order('name', ascending: true);

    return response.map((data) => PostCategory.fromJson(data)).toList();
  }

  // Communities
  Future<List<Community>> getCommunities({String? searchQuery}) async {
    var query = _supabase
        .from('communities')
        .select('*, user_profiles!communities_admin_id_fkey(*)');

    if (searchQuery != null) {
      query = query.ilike('name', '%$searchQuery%');
    }

    final response = await query;
    final userId = _supabase.auth.currentUser?.id;

    if (userId != null) {
      // Get communities where user is a member
      final memberCommunities = await _supabase
          .from('community_members')
          .select('community_id')
          .eq('user_id', userId);

      final memberCommunityIds = memberCommunities
          .map((row) => row['community_id'] as String)
          .toSet();

      // Get pending join requests
      final pendingRequests = await _supabase
          .from('community_join_requests')
          .select('community_id')
          .eq('user_id', userId)
          .eq('status', 'pending');

      final pendingRequestIds = pendingRequests
          .map((row) => row['community_id'] as String)
          .toSet();

      return response.map((row) {
        final community = Community.fromJson(
          row,
          admin: UserProfile.fromJson(row['user_profiles']),
        );
        community.isMember = memberCommunityIds.contains(community.id);
        community.hasRequestedToJoin = pendingRequestIds.contains(community.id);
        return community;
      }).toList();
    }

    return response
        .map((row) => Community.fromJson(
              row,
              admin: UserProfile.fromJson(row['user_profiles']),
            ))
        .toList();
  }

  Future<Community> createCommunity({
    required String name,
    required String description,
    required bool isPrivate,
    File? posterImage,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    String? posterImageUrl;
    if (posterImage != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${name.toLowerCase().replaceAll(' ', '_')}.jpg';
      final filePath = 'community_posters/$fileName';
      
      await _supabase.storage.from('community_images').upload(filePath, posterImage);
      posterImageUrl = _supabase.storage.from('community_images').getPublicUrl(filePath);
    }

    final response = await _supabase

        .from('communities')
        .insert({
          'name': name,
          'description': description,
          'admin_id': userId,
          'is_private': isPrivate,
          'poster_image_url': posterImageUrl,
        })
        .select('*, admin_profiles:user_profiles! communities_admin_id_fkey(*)')
        .single();

    // Add admin as a member
    await _supabase.from('community_members').insert({
      'community_id': response['id'],
      'user_id': userId,
      'role': 'admin',
    });

    return Community.fromJson(
      response,
      admin: UserProfile.fromJson(response['admin_profiles']),
    );
  }



  Future<void> sendJoinRequest(String communityId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _supabase.from('community_join_requests').insert({
      'community_id': communityId,
      'user_id': userId,
    });
  }

  Future<void> processJoinRequest(String requestId, bool accept) async {
    final request = await _supabase
        .from('community_join_requests')
        .select('*, community:communities(*)')
        .eq('id', requestId)
        .single();

    if (accept) {
      await _supabase.from('community_members').insert({
        'community_id': request['community_id'],
        'user_id': request['user_id'],
        'role': 'member',
      });
    }

    await _supabase
        .from('community_join_requests')
        .update({
          'status': accept ? 'accepted' : 'rejected',
          'processed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);
  }

  Future<List<CommunityThread>> getCommunityThreads(String communityId) async {
    final response = await _supabase
        .from('community_threads')
        .select('*, creator_profiles:user_profiles!inner(*)')
        .eq('community_id', communityId)
        .order('created_at', ascending: false);

    return response
        .map((row) => CommunityThread.fromJson(
              row,
              creator: UserProfile.fromJson(row['creator_profiles']),
            ))
        .toList();
  }

  Future<CommunityThread> createThread({
    required String communityId,
    required String title,
    required String category,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase
        .from('community_threads')
        .insert({
          'community_id': communityId,
          'creator_id': userId,
          'title': title,
          'category': category,
        })
        .select('*, creator_profiles:user_profiles!inner(*)')
        .single();

    return CommunityThread.fromJson(
      response,
      creator: UserProfile.fromJson(response['creator_profiles']),
    );
  }

  Future<List<CommunityMessage>> getThreadMessages(String threadId) async {
    final response = await _supabase
        .from('community_messages')
        .select('*, user_profiles:community_messages_sender_id_fkey(*)')
        .eq('thread_id', threadId)
        .order('created_at');

    return response
        .map((row) => CommunityMessage.fromJson(
              row,
              sender: UserProfile.fromJson(row['sender_profiles']),
            ))
        .toList();
  }

  Future<CommunityMessage> sendMessage({
    required String communityId,
    String? threadId,
    String? content,
    List<File>? images,
    String? replyToId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    List<String> imageUrls = [];
    if (images != null && images.isNotEmpty) {
      for (final image in images) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.jpg';
        final filePath = 'community_messages/$fileName';
        
        await _supabase.storage.from('community_images').upload(filePath, image);
        final url = _supabase.storage.from('community_images').getPublicUrl(filePath);
        imageUrls.add(url);
      }
    }

    final response = await _supabase
        .from('community_messages')
        .insert({
          'community_id': communityId,
          'thread_id': threadId,
          'sender_id': userId,
          'content': content,
          'image_urls': imageUrls,
          'reply_to': replyToId,
        })
        .select('*, user_profiles:community_messages_sender_id_fkey(*)')
        .single();

    return CommunityMessage.fromJson(
      response,
      sender: UserProfile.fromJson(response['sender_profiles']),
    );
  }

  Future<List<JoinRequest>> getPendingJoinRequests(String communityId) async {
    final response = await _supabase
        .from('community_join_requests')
        .select('*, user_profiles!inner(*)')
        .eq('community_id', communityId)
        .eq('status', 'pending')
        .order('requested_at', ascending: true);

    return response
        .map((row) => JoinRequest.fromJson(
              row,
              user: UserProfile.fromJson(row['user_profiles']),
            ))
        .toList();
  }

  Future<bool> isUserAdmin(String communityId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _supabase
        .from('community_members')
        .select()
        .eq('community_id', communityId)
        .eq('user_id', userId)
        .eq('role', 'admin')
        .maybeSingle();

    return response != null;
  }

  Future<void> updateCommunity({
    required String communityId,
    String? name,
    String? description,
    bool? isPrivate,
    File? posterImage,
  }) async {
    final updates = <String, dynamic>{};
    
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (isPrivate != null) updates['is_private'] = isPrivate;

    if (posterImage != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${name?.toLowerCase().replaceAll(' ', '_') ?? communityId}.jpg';
      final filePath = 'community_posters/$fileName';
      
      await _supabase.storage.from('community_images').upload(filePath, posterImage);
      updates['poster_image_url'] = _supabase.storage.from('community_images').getPublicUrl(filePath);
    }

    if (updates.isNotEmpty) {
      await _supabase
          .from('communities')
          .update(updates)
          .eq('id', communityId);
    }
  }

  Future<void> joinCommunity(String communityId, bool isPrivate) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    if (isPrivate) {
      // For private communities, create a join request
      await _supabase.from('community_join_requests').insert({
        'user_id': userId,
        'community_id': communityId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Create a notification for the community admin
      final community = await _supabase
          .from('communities')
          .select('admin_id')
          .eq('id', communityId)
          .single();

      await _supabase.from('notifications').insert({
        'user_id': community['admin_id'],
        'type': 'join_request',
        'content': 'New join request for your community',
        'data': {'community_id': communityId, 'requester_id': userId},
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      // For public communities, directly add the user
      await _supabase.from('community_members').insert({
        'user_id': userId,
        'community_id': communityId,
        'joined_at': DateTime.now().toIso8601String(),
      });

      // Update the members count
      await _supabase.rpc('increment_community_members', params: {'community_id': communityId});
    }
  }

  Future<List<UserProfile>> getCommunityMembers(String communityId) async {
    final response = await _supabase
        .from('community_members')
        .select('*, user_profiles(*)')
        .eq('community_id', communityId)
        .order('joined_at', ascending: false);

    return response.map((row) => UserProfile.fromJson(row['user_profiles'])).toList();
  }
}
