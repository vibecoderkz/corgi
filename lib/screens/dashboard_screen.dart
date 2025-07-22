import 'package:flutter/material.dart';
import '../models/main_page_models.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/course_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String _error = '';
  
  // Dashboard data
  UserStats? _userStats;
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      // Load data concurrently
      final results = await Future.wait([
        UserService.getUserStats(),
        _getRecentActivities(),
      ]);

      if (mounted) {
        setState(() {
          _userStats = results[0] as UserStats?;
          _recentActivities = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки данных: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getRecentActivities() async {
    // Get recent transactions as activities
    final pointsSummary = await PointsService.getUserPointsSummary();
    return pointsSummary.recentTransactions.take(5).map((transaction) => {
      'type': transaction.transactionType,
      'description': transaction.description,
      'points': transaction.points,
      'date': transaction.createdAt,
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDashboardData,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeSection(),
                          const SizedBox(height: 24),
                          _buildProgressSection(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                          _buildRecentActivity(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Continue your AI learning journey',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    final completedCourses = _userStats?.coursesCompleted ?? 0;
    final totalCourses = _userStats?.totalCourses ?? 0;
    final completedLessons = _userStats?.lessonsCompleted ?? 0;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green[600]),
                const SizedBox(width: 8),
                Text(
                  'Ваш прогресс',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Курсы', 
                  '$completedCourses/$totalCourses', 
                  Icons.school,
                  Colors.blue[600]!,
                ),
                _buildStatCard(
                  'Уроки', 
                  '$completedLessons', 
                  Icons.book,
                  Colors.green[600]!,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildActionCard(
              'Continue Learning',
              Icons.play_circle_outline,
              Colors.blue,
              () {
                Navigator.pushNamed(context, '/courses');
              },
            ),
            _buildActionCard(
              'Practice Quiz',
              Icons.quiz,
              Colors.green,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Practice quiz coming soon!')),
                );
              },
            ),
            _buildActionCard(
              'Daily Challenge',
              Icons.emoji_events,
              Colors.orange,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Daily challenge coming soon!')),
                );
              },
            ),
            _buildActionCard(
              'Study Groups',
              Icons.groups,
              Colors.purple,
              () {
                Navigator.pushNamed(context, '/community');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: Colors.indigo[600]),
            const SizedBox(width: 8),
            Text(
              'Последняя активность',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: _recentActivities.isEmpty 
            ? const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'Пока нет активности',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentActivities.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final activity = _recentActivities[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: _getActivityColor(activity['type']).withOpacity(0.1),
                      child: Icon(
                        _getActivityIcon(activity['type']),
                        color: _getActivityColor(activity['type']),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      activity['description'] ?? 'Неизвестная активность',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      _formatDate(DateTime.parse(activity['date'].toString())),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+${activity['points']}',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Color _getActivityColor(String activityType) {
    switch (activityType) {
      case 'lesson_completed':
        return Colors.green[600]!;
      case 'homework_completed':
        return Colors.blue[600]!;
      case 'module_completed':
        return Colors.orange[600]!;
      case 'course_completed':
        return Colors.purple[600]!;
      case 'useful_post':
        return Colors.teal[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getActivityIcon(String activityType) {
    switch (activityType) {
      case 'lesson_completed':
        return Icons.book;
      case 'homework_completed':
        return Icons.assignment;
      case 'module_completed':
        return Icons.folder;
      case 'course_completed':
        return Icons.school;
      case 'useful_post':
        return Icons.thumb_up;
      default:
        return Icons.star;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }
}