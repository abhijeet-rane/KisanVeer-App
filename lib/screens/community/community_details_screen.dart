import 'package:flutter/material.dart';
import 'package:kisan_veer/models/community_models.dart';
import 'package:kisan_veer/services/community_service.dart';
import 'package:kisan_veer/screens/community/community_thread_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kisan_veer/widgets/community_members_sheet.dart';

class CommunityDetailsScreen extends StatefulWidget {
  final Community community;

  const CommunityDetailsScreen({Key? key, required this.community}) : super(key: key);

  @override
  State<CommunityDetailsScreen> createState() => _CommunityDetailsScreenState();
}

class _CommunityDetailsScreenState extends State<CommunityDetailsScreen> with SingleTickerProviderStateMixin {
  final _communityService = CommunityService();
  late TabController _tabController;
  List<CommunityThread> _threads = [];
  List<JoinRequest> _pendingRequests = [];
  bool _isAdmin = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _communityService.getCommunityThreads(widget.community.id),
        _communityService.isUserAdmin(widget.community.id),
      ]);

      setState(() {
        _threads = results[0] as List<CommunityThread>;
        _isAdmin = results[1] as bool;
      });

      if (_isAdmin) {
        _pendingRequests = await _communityService.getPendingJoinRequests(widget.community.id);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.green,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.community.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              background: CachedNetworkImage(
                imageUrl: widget.community.posterImageUrl ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[300]),
                errorWidget: (context, url, error) => Container(color: Colors.grey[300], child: const Icon(Icons.error)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(widget.community.isPrivate ? Icons.lock : Icons.public, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text(widget.community.isPrivate ? 'Private Community' : 'Public Community', style: TextStyle(color: Colors.grey[700])),
                  ]),
                  const SizedBox(height: 10),
                  Text(widget.community.description, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 16),
                  Row(children: [
                    Icon(Icons.people, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () => _showMembersSheet(),
                      child: Text(
                        '${widget.community.memberCount} members',
                        style: TextStyle(
                          color: Colors.grey[600],
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.chat, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 5),
                    Text('${widget.community.postCount} posts', style: TextStyle(color: Colors.grey[600])),
                  ]),
                ],
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.deepPurple,
              tabs: [
                const Tab(text: 'Discussions'),
                if (_isAdmin && widget.community.isPrivate) const Tab(text: 'Requests'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDiscussionList(),
                  if (_isAdmin) _buildRequestList(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityThreadScreen(community: widget.community),
          ),
        ).then((_) => _loadData()),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDiscussionList() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _threads.isEmpty
        ? _emptyState('No discussions yet', Icons.chat_bubble_outline)
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _threads.length,
      itemBuilder: (context, index) {
        final thread = _threads[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(backgroundImage: thread.creator.avatarUrl != null ? NetworkImage(thread.creator.avatarUrl!) : null),
            title: Text(thread.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${thread.messageCount} messages', style: TextStyle(color: Colors.grey[600])),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommunityThreadScreen(community: widget.community, thread: thread),
              ),
            ).then((_) => _loadData()),
          ),
        );
      },
    );
  }

  Widget _buildRequestList() {
    return _pendingRequests.isEmpty
        ? _emptyState('No pending requests', Icons.group_add)
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(backgroundImage: request.user.avatarUrl != null ? NetworkImage(request.user.avatarUrl!) : null),
            title: Text(request.user.displayName),
            subtitle: Text('Requested ${timeAgo(request.requestedAt)}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () async {
                  try {
                    await _communityService.processJoinRequest(request.id, true);
                    setState(() {
                      _pendingRequests.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User added to community!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add user: $e')),
                    );
                  }
                },
              ),
              IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () {}),
            ]),
          ),
        );
      },
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 64, color: Colors.grey[400]), const SizedBox(height: 10), Text(message)]));
  }

  void _showMembersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => CommunityMembersSheet(
          community: widget.community,
        ),
      ),
    );
  }
}