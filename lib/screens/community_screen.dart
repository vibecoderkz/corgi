import 'package:flutter/material.dart';
import '../models/discussion_models.dart';
import '../services/discussion_service.dart';
import 'discussion_details_screen.dart';
import 'package:intl/intl.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DiscussionGroup> _discussionGroups = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDiscussionGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDiscussionGroups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final groups = await DiscussionService.getAccessibleDiscussionGroups();
      if (mounted) {
        setState(() {
          _discussionGroups = groups;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/main',
                (route) => false,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Discussions'),
            Tab(text: 'Study Groups'),
            Tab(text: 'Events'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscussionsTab(),
          _buildStudyGroupsTab(),
          _buildEventsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create new content coming soon!')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDiscussionsTab() {
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
              onPressed: _loadDiscussionGroups,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_discussionGroups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Нет доступных обсуждений',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Купите курсы, чтобы участвовать в обсуждениях',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDiscussionGroups,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _discussionGroups.length,
        itemBuilder: (context, index) {
          final group = _discussionGroups[index];
          return _buildDiscussionGroupCard(group);
        },
      ),
    );
  }

  Widget _buildDiscussionGroupCard(DiscussionGroup group) {
    String accessLevelText = '';
    IconData accessIcon = Icons.forum;
    Color accessColor = Colors.blue;

    switch (group.accessLevel) {
      case 'course':
        accessLevelText = 'Курс';
        accessIcon = Icons.school;
        accessColor = Colors.green;
        break;
      case 'module':
        accessLevelText = 'Модуль';
        accessIcon = Icons.book;
        accessColor = Colors.orange;
        break;
      case 'lesson':
        accessLevelText = 'Урок';
        accessIcon = Icons.play_lesson;
        accessColor = Colors.blue;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiscussionDetailsScreen(discussionGroup: group),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accessColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(accessIcon, size: 14, color: accessColor),
                        const SizedBox(width: 4),
                        Text(
                          accessLevelText,
                          style: TextStyle(
                            color: accessColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd.MM.yyyy').format(group.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                group.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (group.description != null && group.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  group.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.forum_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Обсуждение',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    Color color;
    IconData icon;
    switch (category) {
      case 'Question':
        color = Colors.blue;
        icon = Icons.help_outline;
        break;
      case 'Story':
        color = Colors.purple;
        icon = Icons.book_outlined;
        break;
      case 'Challenge':
        color = Colors.orange;
        icon = Icons.emoji_events_outlined;
        break;
      case 'Tutorial':
        color = Colors.green;
        icon = Icons.school_outlined;
        break;
      default:
        color = Colors.grey;
        icon = Icons.label_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            category,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyGroupsTab() {
    final studyGroups = [
      StudyGroup(
        id: '1',
        name: 'AI Beginners United',
        members: 156,
        description: 'A supportive group for AI beginners',
        isJoined: true,
        meetingTime: 'Every Monday, 7 PM',
      ),
      StudyGroup(
        id: '2',
        name: 'Deep Learning Masters',
        members: 89,
        description: 'Advanced deep learning discussions',
        isJoined: false,
        meetingTime: 'Wednesdays, 8 PM',
      ),
      StudyGroup(
        id: '3',
        name: 'NLP Enthusiasts',
        members: 234,
        description: 'Natural Language Processing study group',
        isJoined: false,
        meetingTime: 'Fridays, 6 PM',
      ),
      StudyGroup(
        id: '4',
        name: 'Computer Vision Club',
        members: 167,
        description: 'Exploring computer vision together',
        isJoined: true,
        meetingTime: 'Tuesdays, 7:30 PM',
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: studyGroups.length,
      itemBuilder: (context, index) {
        final group = studyGroups[index];
        return _buildStudyGroupCard(group);
      },
    );
  }

  Widget _buildStudyGroupCard(StudyGroup group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to group details
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Study group details coming soon!')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      group.name.substring(0, 2).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${group.members} members',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (group.isJoined)
                    const Chip(
                      label: Text('Joined'),
                      backgroundColor: Colors.green,
                      labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                    )
                  else
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Join group coming soon!')),
                        );
                      },
                      child: const Text('Join'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                group.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    group.meetingTime,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    final events = [
      Event(
        id: '1',
        title: 'AI Workshop: Building Your First Chatbot',
        date: 'Dec 15, 2024',
        time: '3:00 PM - 5:00 PM',
        type: 'Workshop',
        attendees: 45,
        isRegistered: true,
      ),
      Event(
        id: '2',
        title: 'Guest Lecture: Future of AI',
        date: 'Dec 18, 2024',
        time: '6:00 PM - 7:30 PM',
        type: 'Lecture',
        attendees: 128,
        isRegistered: false,
      ),
      Event(
        id: '3',
        title: 'Hackathon: AI for Good',
        date: 'Dec 20-21, 2024',
        time: 'All day',
        type: 'Hackathon',
        attendees: 89,
        isRegistered: false,
      ),
      Event(
        id: '4',
        title: 'Study Session: Preparing for AI Certification',
        date: 'Dec 22, 2024',
        time: '2:00 PM - 4:00 PM',
        type: 'Study Session',
        attendees: 23,
        isRegistered: true,
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(Event event) {
    Color typeColor;
    IconData typeIcon;
    switch (event.type) {
      case 'Workshop':
        typeColor = Colors.blue;
        typeIcon = Icons.build;
        break;
      case 'Lecture':
        typeColor = Colors.purple;
        typeIcon = Icons.school;
        break;
      case 'Hackathon':
        typeColor = Colors.orange;
        typeIcon = Icons.code;
        break;
      case 'Study Session':
        typeColor = Colors.green;
        typeIcon = Icons.group;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.event;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to event details
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event details coming soon!')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(typeIcon, color: typeColor),
                  const SizedBox(width: 8),
                  Text(
                    event.type,
                    style: TextStyle(
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (event.isRegistered)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(event.date, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(event.time, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${event.attendees} attending',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      if (!event.isRegistered)
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Event registration coming soon!')),
                            );
                          },
                          child: const Text('Register'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Discussion {
  final String id;
  final String title;
  final String author;
  final String timeAgo;
  final int replies;
  final int likes;
  final String category;
  final bool isPinned;

  Discussion({
    required this.id,
    required this.title,
    required this.author,
    required this.timeAgo,
    required this.replies,
    required this.likes,
    required this.category,
    this.isPinned = false,
  });
}

class StudyGroup {
  final String id;
  final String name;
  final int members;
  final String description;
  final bool isJoined;
  final String meetingTime;

  StudyGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.description,
    required this.isJoined,
    required this.meetingTime,
  });
}

class Event {
  final String id;
  final String title;
  final String date;
  final String time;
  final String type;
  final int attendees;
  final bool isRegistered;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.type,
    required this.attendees,
    required this.isRegistered,
  });
}