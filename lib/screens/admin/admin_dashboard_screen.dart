import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import 'create_course_screen.dart';
import 'manage_courses_screen.dart';
import 'manage_modules_lessons_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> stats = {};
  List<Map<String, dynamic>> recentActivity = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final statsResponse = await AdminService.getAdminStats();
      final activityResponse = await AdminService.getRecentActivity();

      if (mounted) {
        setState(() {
          if (statsResponse['success'] == true) {
            stats = statsResponse['stats'];
          }
          recentActivity = activityResponse;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dashboard data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildRecentActivity(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
              'Total Courses',
              '${stats['total_courses'] ?? 0}',
              Icons.school,
              Colors.blue,
            ),
            _buildStatCard(
              'Total Users',
              '${stats['total_users'] ?? 0}',
              Icons.people,
              Colors.green,
            ),
            _buildStatCard(
              'Total Modules',
              '${stats['total_modules'] ?? 0}',
              Icons.book,
              Colors.orange,
            ),
            _buildStatCard(
              'Total Lessons',
              '${stats['total_lessons'] ?? 0}',
              Icons.play_lesson,
              Colors.purple,
            ),
            _buildStatCard(
              'Total Purchases',
              '${stats['total_purchases'] ?? 0}',
              Icons.shopping_cart,
              Colors.teal,
            ),
            _buildStatCard(
              'Total Revenue',
              '\$${(stats['total_revenue'] ?? 0.0).toStringAsFixed(2)}',
              Icons.attach_money,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
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
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2,
          children: [
            _buildActionCard(
              'Create Course',
              Icons.add_circle,
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateCourseScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              'Manage Courses',
              Icons.manage_search,
              Colors.green,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageCoursesScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              'Manage Modules & Lessons',
              Icons.playlist_play,
              Colors.purple,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageModulesLessonsScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              'View Analytics',
              Icons.analytics,
              Colors.orange,
              () {
                // TODO: Implement analytics screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Analytics coming soon!')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: color,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
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
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (recentActivity.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No recent activity',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentActivity.length,
            itemBuilder: (context, index) {
              final activity = recentActivity[index];
              return _buildActivityItem(activity);
            },
          ),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final user = activity['users'];
    final course = activity['courses'];
    final module = activity['modules'];
    final lesson = activity['lessons'];
    
    String itemTitle = 'Unknown';
    if (course != null) {
      itemTitle = course['title'];
    } else if (module != null) {
      itemTitle = module['title'];
    } else if (lesson != null) {
      itemTitle = lesson['title'];
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.2),
          child: const Icon(
            Icons.shopping_cart,
            color: Colors.green,
          ),
        ),
        title: Text(
          '${user?['full_name'] ?? 'Unknown User'} purchased $itemTitle',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Text(
          '\$${activity['amount']} • ${_formatDate(activity['purchased_at'])}',
        ),
        trailing: Chip(
          label: Text(
            activity['payment_status'],
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: activity['payment_status'] == 'completed'
              ? Colors.green.withOpacity(0.2)
              : Colors.orange.withOpacity(0.2),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}