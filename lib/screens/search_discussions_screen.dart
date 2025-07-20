import 'package:flutter/material.dart';
import '../models/discussion_models.dart';
import '../services/discussion_service.dart';
import 'discussion_details_screen.dart';
import 'package:intl/intl.dart';

class SearchDiscussionsScreen extends StatefulWidget {
  const SearchDiscussionsScreen({super.key});

  @override
  State<SearchDiscussionsScreen> createState() => _SearchDiscussionsScreenState();
}

class _SearchDiscussionsScreenState extends State<SearchDiscussionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DiscussionPost> _searchResults = [];
  List<ContentItem> _availableContent = [];
  bool _isLoading = false;
  bool _isLoadingContent = true;
  String? _error;
  String _searchQuery = '';
  
  // Filter options
  String? _selectedContentType;
  String? _selectedContentId;
  bool _questionsOnly = false;
  String _sortBy = 'recent'; // 'recent', 'popular', 'helpful'

  @override
  void initState() {
    super.initState();
    _loadAvailableContent();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableContent() async {
    setState(() {
      _isLoadingContent = true;
    });

    try {
      final content = await DiscussionService.getAccessibleContent();
      if (mounted) {
        setState(() {
          _availableContent = content;
          _isLoadingContent = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingContent = false;
        });
      }
    }
  }

  Future<void> _performSearch() async {
    if (_searchQuery.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await DiscussionService.searchDiscussionsAdvanced(
        query: _searchQuery.trim(),
        contentType: _selectedContentType,
        contentId: _selectedContentId,
        questionsOnly: _questionsOnly,
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _searchResults = result.posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка поиска: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedContentType = null;
      _selectedContentId = null;
      _questionsOnly = false;
      _sortBy = 'recent';
    });
    if (_searchQuery.isNotEmpty) {
      _performSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск в обсуждениях'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Введите поисковый запрос...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _searchResults.clear();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _performSearch();
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _searchQuery.trim().isNotEmpty && !_isLoading
                            ? _performSearch
                            : null,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: Text(_isLoading ? 'Поиск...' : 'Поиск'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => _showFiltersDialog(),
                      icon: Icon(
                        Icons.filter_list,
                        color: _hasActiveFilters() ? Colors.blue[600] : Colors.grey[600],
                      ),
                      tooltip: 'Фильтры',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Active filters display
          if (_hasActiveFilters())
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedContentType != null)
                    Chip(
                      label: Text(_getContentFilterText()),
                      onDeleted: () {
                        setState(() {
                          _selectedContentType = null;
                          _selectedContentId = null;
                        });
                        if (_searchQuery.isNotEmpty) _performSearch();
                      },
                    ),
                  if (_questionsOnly)
                    Chip(
                      label: const Text('Только вопросы'),
                      onDeleted: () {
                        setState(() {
                          _questionsOnly = false;
                        });
                        if (_searchQuery.isNotEmpty) _performSearch();
                      },
                    ),
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear),
                    label: const Text('Очистить фильтры'),
                  ),
                ],
              ),
            ),

          // Search results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Введите поисковый запрос',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Найдите интересующие вас обсуждения',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Ничего не найдено',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Попробуйте изменить поисковый запрос',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final post = _searchResults[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildPostCard(DiscussionPost post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (post.discussionGroup != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DiscussionDetailsScreen(
                  discussionGroup: post.discussionGroup!,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post header
              Row(
                children: [
                  if (post.isQuestion)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Вопрос',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (post.isAnswer)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Ответ',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (post.usefulVotes > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.thumb_up, size: 12, color: Colors.orange[700]),
                          const SizedBox(width: 2),
                          Text(
                            '${post.usefulVotes}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Post title and content
              if (post.title != null && post.title!.isNotEmpty) ...[
                Text(
                  post.title!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                post.content,
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Post metadata
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: post.user?.avatarUrl != null
                        ? NetworkImage(post.user!.avatarUrl!)
                        : null,
                    child: post.user?.avatarUrl == null
                        ? Text(
                            post.user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(fontSize: 10),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.user?.fullName ?? 'Пользователь',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'в ${post.discussionGroup?.name ?? 'обсуждении'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('dd.MM.yyyy').format(post.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Фильтры поиска'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Контент:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_isLoadingContent)
                  const Center(child: CircularProgressIndicator())
                else
                  DropdownButtonFormField<String>(
                    value: _selectedContentId,
                    hint: const Text('Выберите контент'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Все'),
                      ),
                      ..._availableContent.map((content) => DropdownMenuItem(
                        value: content.id,
                        child: Row(
                          children: [
                            _getContentIcon(content.type),
                            const SizedBox(width: 8),
                            Expanded(child: Text(content.title)),
                          ],
                        ),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedContentId = value;
                        if (value != null) {
                          final content = _availableContent.firstWhere((c) => c.id == value);
                          _selectedContentType = content.type;
                        } else {
                          _selectedContentType = null;
                        }
                      });
                    },
                  ),

                const SizedBox(height: 16),

                CheckboxListTile(
                  title: const Text('Только вопросы'),
                  value: _questionsOnly,
                  onChanged: (value) {
                    setState(() {
                      _questionsOnly = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                this.setState(() {}); // Update main widget state
                if (_searchQuery.isNotEmpty) _performSearch();
              },
              child: const Text('Применить'),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedContentType != null || _questionsOnly;
  }

  String _getContentFilterText() {
    if (_selectedContentId != null) {
      final content = _availableContent.firstWhere((c) => c.id == _selectedContentId);
      return '${_getContentTypeText(content.type)}: ${content.title}';
    }
    return '';
  }

  Widget _getContentIcon(String type) {
    switch (type) {
      case 'course':
        return Icon(Icons.school, size: 16, color: Colors.green[600]);
      case 'module':
        return Icon(Icons.book, size: 16, color: Colors.orange[600]);
      case 'lesson':
        return Icon(Icons.play_lesson, size: 16, color: Colors.blue[600]);
      default:
        return Icon(Icons.help_outline, size: 16, color: Colors.grey[600]);
    }
  }

  String _getContentTypeText(String type) {
    switch (type) {
      case 'course':
        return 'Курс';
      case 'module':
        return 'Модуль';
      case 'lesson':
        return 'Урок';
      default:
        return 'Неизвестно';
    }
  }
}