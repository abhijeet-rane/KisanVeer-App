import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/community_models.dart';
import 'package:kisan_veer/screens/community/communities_screen.dart';
import 'package:kisan_veer/screens/community/create_post_screen.dart';
import 'package:kisan_veer/screens/community/post_details_screen.dart';
import 'package:kisan_veer/services/community_service.dart';
import 'package:kisan_veer/utils/app_logger.dart';
import 'package:kisan_veer/widgets/post_card.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';

/// V2 community hub.
///
/// Two-tab surface (Discussions / Communities). The Discussions tab
/// shows category pills + paginated post feed; the Communities tab
/// delegates to the existing [CommunitiesScreen].
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

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

  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
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
        offset: 0,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _posts = posts;
        _hasMore = posts.length >= _pageSize;
        _offset = posts.length;
      });
    } catch (e) {
      AppLogger.e('Community load failed', tag: 'Community', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not load community'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        offset: _offset,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _posts.addAll(posts);
        _hasMore = posts.length >= _pageSize;
        _offset += posts.length;
      });
    } catch (e) {
      AppLogger.e('Load more posts failed', tag: 'Community', error: e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        const SnackBar(content: Text('Still loading categories, try again')),
      );
      return;
    }
    final result = await Navigator.of(
      context,
    ).push<bool>(AppPageRoute.of(CreatePostScreen(categories: _categories)));
    if (result == true && mounted) _refreshPosts();
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
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'Community',
        showBack: false,
        actions: [
          if (_tabController.index == 1)
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Search communities',
              onPressed: () {
                showSearch<dynamic>(
                  context: context,
                  delegate: CommunitySearchDelegate(_communityService),
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          labelStyle: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: AppTextStyles.titleSmall,
          tabs: const [
            Tab(text: 'Discussions'),
            Tab(text: 'Communities'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDiscussionsTab(), const CommunitiesScreen()],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index != 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _createPost,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.edit_rounded),
            label: const Text('New post'),
          );
        },
      ),
    );
  }

  Widget _buildDiscussionsTab() {
    return RefreshIndicator(
      onRefresh: _refreshPosts,
      color: AppColors.primary,
      child: Column(
        children: [
          if (_categories.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                  vertical: AppSpacing.space8,
                ),
                itemCount: _categories.length + 1,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.space8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _CategoryPill(
                      label: 'All',
                      selected: _selectedCategory == null,
                      onTap: () => _onCategorySelected(null),
                    );
                  }
                  final category = _categories[index - 1];
                  return _CategoryPill(
                    label: category.name,
                    selected: category.name == _selectedCategory,
                    onTap: () => _onCategorySelected(category.name),
                  );
                },
              ),
            ),
          Expanded(
            child: _isLoading && _posts.isEmpty
                ? const AppLoadingState(message: 'Loading discussions…')
                : _posts.isEmpty
                ? const AppEmptyState(
                    icon: Icons.forum_outlined,
                    title: 'No discussions yet',
                    message:
                        'Be the first to start a conversation. Tap '
                        '"New post" below.',
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.space16,
                      AppSpacing.space8,
                      AppSpacing.space16,
                      AppSpacing.space96,
                    ),
                    itemCount: _posts.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _posts.length) {
                        if (!_hasMore) return const SizedBox.shrink();
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.space16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }
                      final post = _posts[index];
                      return PostCard(
                        post: post,
                        onTap: () => Navigator.of(
                          context,
                        ).push(AppPageRoute.of(PostDetailsScreen(post: post))),
                        onLike: () => _togglePostLike(post),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePostLike(Post post) async {
    try {
      if (post.isLikedByUser) {
        await _communityService.unlikePost(post.id);
        if (!mounted) return;
        setState(() {
          post.isLikedByUser = false;
          post.likesCount--;
        });
      } else {
        await _communityService.likePost(post.id);
        if (!mounted) return;
        setState(() {
          post.isLikedByUser = true;
          post.likesCount++;
        });
      }
    } catch (e) {
      AppLogger.e('Toggle post like failed', tag: 'Community', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not update like'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.brFull,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space8,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: AppRadii.brFull,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: selected ? AppColors.onPrimary : AppColors.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
