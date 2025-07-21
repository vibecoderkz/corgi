import 'package:flutter/material.dart';
import '../models/discussion_models.dart';
import '../services/discussion_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class DiscussionDetailsScreen extends StatefulWidget {
  final DiscussionGroup discussionGroup;

  const DiscussionDetailsScreen({
    super.key,
    required this.discussionGroup,
  });

  @override
  State<DiscussionDetailsScreen> createState() => _DiscussionDetailsScreenState();
}

class _DiscussionDetailsScreenState extends State<DiscussionDetailsScreen> {
  List<DiscussionPost> _posts = [];
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;
  final TextEditingController _newPostController = TextEditingController();
  final Map<String, TextEditingController> _replyControllers = {};
  final Map<String, bool> _showReplyBoxes = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _loadPosts();
  }

  @override
  void dispose() {
    _newPostController.dispose();
    for (var controller in _replyControllers.values) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUser() async {
    _currentUserId = await AuthService.getCurrentUserId();
    if (mounted) setState(() {});
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final posts = await DiscussionService.getDiscussionPosts(
        widget.discussionGroup.id,
        includeReplies: true,
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки обсуждений: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createPost(String content, {String? parentPostId}) async {
    if (content.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сообщение не может быть пустым')),
      );
      return;
    }

    // Show loading state
    setState(() {
      if (parentPostId != null) {
        _showReplyBoxes[parentPostId] = true;
      }
    });

    try {
      print('Creating post with content: ${content.trim()}');
      print('Parent post ID: $parentPostId');
      print('Discussion group ID: ${widget.discussionGroup.id}');

      final request = CreatePostRequest(
        discussionGroupId: widget.discussionGroup.id,
        title: parentPostId == null ? 'Обсуждение' : '',
        content: content.trim(),
        isQuestion: false,
        parentPostId: parentPostId,
      );

      final result = await DiscussionService.createPost(request);
      print('Create post result: $result');
      
      if (parentPostId == null) {
        _newPostController.clear();
      } else {
        _replyControllers[parentPostId]?.clear();
        _showReplyBoxes[parentPostId] = false;
      }
      
      await _loadPosts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сообщение добавлено'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error creating post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания сообщения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleHelpfulVote(String postId, bool currentVote) async {
    if (_currentUserId == null) return;

    try {
      if (currentVote) {
        // Remove vote
        await DiscussionService.removeVote(postId);
      } else {
        // Add helpful vote
        await DiscussionService.voteOnPost(postId, true);
      }
      
      await _loadPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _togglePostPin(String postId, bool isPinned) async {
    try {
      await DiscussionService.togglePostPin(postId, !isPinned);
      await _loadPosts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPinned ? 'Сообщение откреплено' : 'Сообщение закреплено'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<bool> _isUserAdmin() async {
    if (_currentUserId == null) return false;
    // This would typically check the user role from the database
    // For now, we'll use a simple check
    return true; // Replace with actual admin check
  }

  void _showReplyBox(String postId) {
    setState(() {
      _showReplyBoxes[postId] = !(_showReplyBoxes[postId] ?? false);
      if (_showReplyBoxes[postId] == true && !_replyControllers.containsKey(postId)) {
        _replyControllers[postId] = TextEditingController();
      }
    });
  }

  bool _getUserVote(DiscussionPost post) {
    if (_currentUserId == null || post.votes == null) return false;
    return post.votes!.any((vote) => 
      vote.userId == _currentUserId && vote.isUseful);
  }

  List<DiscussionPost> _getTopLevelPosts() {
    return _posts.where((post) => post.parentPostId == null).toList();
  }

  List<DiscussionPost> _getReplies(String postId) {
    return _posts.where((post) => post.parentPostId == postId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.discussionGroup.name),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPosts,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Discussion header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.discussionGroup.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.discussionGroup.description != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.discussionGroup.description!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Posts list
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadPosts,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _getTopLevelPosts().length + 1,
                          itemBuilder: (context, index) {
                            if (index == _getTopLevelPosts().length) {
                              // New post form at the bottom
                              return _buildNewPostForm();
                            }
                            
                            final post = _getTopLevelPosts()[index];
                            return _buildPostCard(post);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPostCard(DiscussionPost post) {
    final replies = _getReplies(post.id);
    final userVote = _getUserVote(post);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post.user?.avatarUrl != null
                      ? NetworkImage(post.user!.avatarUrl!)
                      : null,
                  child: post.user?.avatarUrl == null
                      ? Text(
                          post.user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.user?.fullName ?? 'Пользователь',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat('dd.MM.yyyy HH:mm').format(post.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Helpful votes
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thumb_up,
                        size: 16,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.usefulVotes}',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Post content
            if (post.title != null && post.title!.isNotEmpty) ...[
              Text(
                post.title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              post.content,
              style: const TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                // Helpful button
                TextButton.icon(
                  onPressed: _currentUserId != null && _currentUserId != post.userId
                      ? () => _toggleHelpfulVote(post.id, userVote)
                      : null,
                  icon: Icon(
                    userVote ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: userVote ? Colors.green : Colors.grey[600],
                  ),
                  label: Text(
                    userVote ? 'ПОЛЕЗНО' : 'ПОЛЕЗНО',
                    style: TextStyle(
                      color: userVote ? Colors.green : Colors.grey[600],
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Reply button
                TextButton.icon(
                  onPressed: _currentUserId != null
                      ? () => _showReplyBox(post.id)
                      : null,
                  icon: Icon(Icons.reply, color: Colors.blue[600]),
                  label: Text(
                    'ОТВЕТИТЬ',
                    style: TextStyle(color: Colors.blue[600]),
                  ),
                ),
                
                const Spacer(),
                
                // Replies count
                if (replies.isNotEmpty)
                  Text(
                    '${replies.length} ${_getReplyText(replies.length)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            
            // Reply box
            if (_showReplyBoxes[post.id] == true) ...[
              const SizedBox(height: 16),
              _buildReplyForm(post.id),
            ],
            
            // Replies
            if (replies.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...replies.map((reply) => _buildReplyCard(reply)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReplyCard(DiscussionPost reply) {
    final userVote = _getUserVote(reply);
    
    return Container(
      margin: const EdgeInsets.only(left: 32, top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reply header
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: reply.user?.avatarUrl != null
                    ? NetworkImage(reply.user!.avatarUrl!)
                    : null,
                child: reply.user?.avatarUrl == null
                    ? Text(
                        reply.user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply.user?.fullName ?? 'Пользователь',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat('dd.MM.yyyy HH:mm').format(reply.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Helpful votes for reply
              if (reply.usefulVotes > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thumb_up,
                        size: 12,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${reply.usefulVotes}',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Reply content
          Text(
            reply.content,
            style: const TextStyle(fontSize: 14),
          ),
          
          const SizedBox(height: 8),
          
          // Reply actions
          Row(
            children: [
              TextButton.icon(
                onPressed: _currentUserId != null && _currentUserId != reply.userId
                    ? () => _toggleHelpfulVote(reply.id, userVote)
                    : null,
                icon: Icon(
                  userVote ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 16,
                  color: userVote ? Colors.green : Colors.grey[600],
                ),
                label: Text(
                  'ПОЛЕЗНО',
                  style: TextStyle(
                    color: userVote ? Colors.green : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyForm(String postId) {
    final controller = _replyControllers[postId]!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Напишите ответ...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _showReplyBox(postId),
                child: const Text('Отмена'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _createPost(controller.text, parentPostId: postId),
                child: const Text('Ответить'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewPostForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Добавить сообщение',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPostController,
              decoration: const InputDecoration(
                hintText: 'Поделитесь своими мыслями...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _currentUserId != null
                      ? () => _createPost(_newPostController.text)
                      : null,
                  child: const Text('Опубликовать'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getReplyText(int count) {
    if (count == 1) return 'ответ';
    if (count >= 2 && count <= 4) return 'ответа';
    return 'ответов';
  }
}