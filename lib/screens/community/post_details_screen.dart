import 'package:flutter/material.dart';
import 'package:kisan_veer/models/community_models.dart';
import 'package:kisan_veer/services/community_service.dart';
import 'package:kisan_veer/widgets/comment_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostDetailsScreen extends StatefulWidget {
  final Post post;

  const PostDetailsScreen({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final _communityService = CommunityService();
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  List<Comment> _comments = [];
  bool _isLoading = false;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final comments = await _communityService.getComments(widget.post.id);
      setState(() => _comments = comments);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading comments: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPostingComment = true);
    try {
      final comment = await _communityService.createComment(
        widget.post.id,
        content,
      );

      setState(() {
        _comments.insert(0, comment);
        widget.post.commentsCount++;
        _commentController.clear();
      });

      // Scroll to top to show the new comment
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPostingComment = false);
      }
    }
  }

  Future<void> _handleCommentLike(Comment comment) async {
    try {
      if (comment.isLikedByUser) {
        await _communityService.unlikeComment(comment.id);
        setState(() {
          comment.isLikedByUser = false;
          comment.likesCount--;
        });
      } else {
        await _communityService.likeComment(comment.id);
        setState(() {
          comment.isLikedByUser = true;
          comment.likesCount++;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: Column(
        children: [
          // Post details
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Author info
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: widget.post.author.avatarUrl != null
                        ? NetworkImage(widget.post.author.avatarUrl!)
                        : null,
                    child: widget.post.author.avatarUrl == null
                        ? Text(widget.post.author.displayName[0].toUpperCase())
                        : null,
                  ),
                  title: Text(
                    widget.post.author.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(timeago.format(widget.post.createdAt)),
                  trailing: widget.post.category != null
                      ? Chip(
                          label: Text(widget.post.category!),
                          backgroundColor:
                              Theme.of(context).colorScheme.secondaryContainer,
                          labelStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  widget.post.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Content
                Text(
                  widget.post.content,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),

                // Images
                if (widget.post.imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.post.imageUrls.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index == widget.post.imageUrls.length - 1
                                ? 0
                                : 8,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: widget.post.imageUrls[index],
                              fit: BoxFit.cover,
                              width: 200,
                              placeholder: (context, url) => Container(
                                color:
                                    Theme.of(context).colorScheme.surfaceVariant,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color:
                                    Theme.of(context).colorScheme.errorContainer,
                                child: const Icon(Icons.error),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // Tags
                if (widget.post.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.post.tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            backgroundColor:
                                Theme.of(context).colorScheme.surfaceVariant,
                          ),
                        )
                        .toList(),
                  ),
                ],

                const Divider(height: 32),

                // Comments section
                Text(
                  'Comments (${widget.post.commentsCount})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_comments.isEmpty)
                  const Center(
                    child: Text('No comments yet. Be the first to comment!'),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return CommentCard(
                        comment: comment,
                        onLike: () => _handleCommentLike(comment),
                      );
                    },
                  ),
              ],
            ),
          ),

          // Comment input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _isPostingComment ? null : _postComment,
                  icon: _isPostingComment
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
