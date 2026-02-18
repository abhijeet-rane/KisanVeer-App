import 'package:flutter/material.dart';
import 'package:kisan_veer/models/community_models.dart';
import 'package:kisan_veer/screens/community/create_post_screen.dart';
import 'package:kisan_veer/services/community_service.dart';
import 'package:kisan_veer/widgets/post_card.dart';
import 'package:kisan_veer/screens/community/post_details_screen.dart';
import 'package:kisan_veer/screens/community/communities_screen.dart';


class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  final _communityService = CommunityService();
  final _scrollController = ScrollController();
  late final TabController _tabController;

  List<Post> _posts = [];
  List<PostCategory> _categories = [];
  String? _selectedCategory;
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Ensures UI updates when the tab changes
    });
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _communityService.getCategories();
      final posts = await _communityService.getPosts(
        category: _selectedCategory,
      );

      setState(() {
        _categories = categories;
        _posts = posts;
        _hasMore = posts.length >= 10;
        _offset = posts.length;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);
    try {
      final posts = await _communityService.getPosts(
        category: _selectedCategory,
      );

      if (mounted) {
        setState(() {
          _posts.addAll(posts);
          _hasMore = posts.length >= 10;
          _offset += posts.length;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more posts: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _offset = 0;
      _posts.clear();
      _hasMore = true;
    });
    await _loadInitialData();
  }

  Future<void> _createPost() async {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for categories to load')),
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(categories: _categories),
      ),
    );

    if (result == true && mounted) {
      _refreshPosts();
    }
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
      _offset = 0;
      _posts.clear();
      _hasMore = true;
    });
    _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: _tabController.index == 1
        ? [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CommunitySearchDelegate(_communityService),
              );
            },
          ),
        ]
          : null,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Discussions'),
            Tab(text: 'Communities'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Discussions Tab
          RefreshIndicator(
            onRefresh: _refreshPosts,
            child: Column(
              children: [
                // Category selector
                if (_categories.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        FilterChip(
                          label: const Text('All'),
                          selected: _selectedCategory == null,
                          onSelected: (_) => _onCategorySelected(null),
                        ),
                        const SizedBox(width: 8),
                        ..._categories.map(
                          (category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category.name),
                              selected: category.name == _selectedCategory,
                              onSelected: (_) =>
                                  _onCategorySelected(category.name),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Posts list
                Expanded(
                  child: _isLoading && _posts.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _posts.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _posts.length) {
                              return _hasMore
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : const SizedBox();
                            }

                            final post = _posts[index];
                            return PostCard(
                              post: post,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PostDetailsScreen(post: post),
                                  ),
                                );
                              },
                              onLike: () async {
                                try {
                                  if (post.isLikedByUser) {
                                    await _communityService.unlikePost(post.id);
                                    setState(() {
                                      post.isLikedByUser = false;
                                      post.likesCount--;
                                    });
                                  } else {
                                    await _communityService.likePost(post.id);
                                    setState(() {
                                      post.isLikedByUser = true;
                                      post.likesCount++;
                                    });
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                            );

                          },
                        ),
                ),

              ],


            ),
          ),

          // Communities Tab (to be implemented)
          // Communities Tab
          const CommunitiesScreen(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return _tabController.index == 0
              ? FloatingActionButton(
            onPressed: _createPost,
            child: const Icon(Icons.add),
          )
              : SizedBox(); // Empty SizedBox hides the button
        },
      ),
    );
  }
}
