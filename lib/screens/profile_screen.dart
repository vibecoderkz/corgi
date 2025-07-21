import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import '../services/user_service.dart';
import '../services/points_service.dart';
import '../models/purchase_models.dart';
import '../models/main_page_models.dart';
import '../screens/settings_screen.dart';
import '../screens/purchase_history_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late TabController _tabController;
  
  bool _isAdmin = false;
  bool _isLoadingAdminStatus = true;
  Map<String, dynamic>? _userProfile;
  UserStats? _userStats;
  PointsSummary? _pointsSummary;
  List<Map<String, dynamic>> _userSkills = [];
  List<Map<String, dynamic>> _userAchievements = [];
  List<Map<String, dynamic>> _userCertificates = [];
  bool _isLoading = true;
  String _userRole = 'student';
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);
      
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Load all data concurrently
      final results = await Future.wait([
        UserService.getCurrentUserProfile(),
        UserService.getUserStats(),
        PointsService.getUserPointsSummary(),
        PointsService.getUserTotalPoints(),
        UserService.getUserSkillProgress(currentUser.id),
        UserService.getUserAchievements(currentUser.id),
        UserService.getUserCertificates(currentUser.id),
        AdminService.isAdmin(),
        AdminService.getCurrentUserRole(),
      ]);
      
      if (mounted) {
        setState(() {
          _userProfile = results[0] as Map<String, dynamic>?;
          _userStats = results[1] as UserStats?;
          _pointsSummary = results[2] as PointsSummary?;
          _totalPoints = results[3] as int;
          _userSkills = results[4] as List<Map<String, dynamic>>;
          _userAchievements = results[5] as List<Map<String, dynamic>>;
          _userCertificates = results[6] as List<Map<String, dynamic>>;
          _isAdmin = results[7] as bool;
          _userRole = results[8] as String;
          _isLoadingAdminStatus = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isLoadingAdminStatus = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildUserInfo(),
                      _buildStatsSection(),
                      _buildTabsSection(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.indigo[600],
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Профиль',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.indigo[700]!,
                Colors.indigo[600]!,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadUserData,
          tooltip: 'Обновить',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
          tooltip: 'Настройки',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'purchase_history',
              child: Row(
                children: [
                  Icon(Icons.history, size: 18),
                  SizedBox(width: 8),
                  Text('История покупок'),
                ],
              ),
            ),
            if (_isAdmin) ...[
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'admin_dashboard',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, size: 18, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Админ панель', style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
            ],
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Выйти', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    final currentUser = _authService.currentUser;
    final userName = _userProfile?['full_name'] ?? currentUser?.userMetadata?['name'] ?? 'Пользователь';
    final userEmail = currentUser?.email ?? '';
    final avatarUrl = _userProfile?['avatar_url'];

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.indigo[100],
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.indigo[600],
                          )
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getRoleColor(_userRole).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _getRoleColor(_userRole).withOpacity(0.3)),
                          ),
                          child: Text(
                            _translateRole(_userRole),
                            style: TextStyle(
                              color: _getRoleColor(_userRole),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoChip(
                    'Баллы',
                    '$_totalPoints',
                    Icons.star,
                    Colors.orange[600]!,
                  ),
                  _buildInfoChip(
                    'Курсы',
                    '${_userStats?.coursesCompleted ?? 0}/${_userStats?.totalCourses ?? 0}',
                    Icons.school,
                    Colors.blue[600]!,
                  ),
                  _buildInfoChip(
                    'Уроки',
                    '${_userStats?.lessonsCompleted ?? 0}',
                    Icons.book,
                    Colors.green[600]!,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, color: Colors.indigo[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Прогресс обучения',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_userStats != null) ...[
                _buildProgressBar(
                  'Курсы завершены',
                  _userStats!.coursesCompleted,
                  _userStats!.totalCourses,
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildProgressBar(
                  'Модули завершены',
                  _userStats!.modulesCompleted,
                  _userStats!.totalModules,
                  Colors.green,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatTile(
                        'Время обучения',
                        '${_userStats!.totalLearningMinutes} мин',
                        Icons.access_time,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatTile(
                        'Рейтинг',
                        '${_userStats!.userRank}',
                        Icons.emoji_events,
                        Colors.amber,
                      ),
                    ),
                  ],
                ),
              ] else
                const Center(
                  child: Text('Нет данных о прогрессе'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, int completed, int total, Color color) {
    final progress = total > 0 ? completed / total : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              '$completed/$total',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Colors.indigo[600],
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.indigo[600],
              tabs: const [
                Tab(icon: Icon(Icons.star), text: 'Баллы'),
                Tab(icon: Icon(Icons.psychology), text: 'Навыки'),
                Tab(icon: Icon(Icons.emoji_events), text: 'Достижения'),
                Tab(icon: Icon(Icons.card_membership), text: 'Сертификаты'),
              ],
            ),
            SizedBox(
              height: 400,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPointsTab(),
                  _buildSkillsTab(),
                  _buildAchievementsTab(),
                  _buildCertificatesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsTab() {
    if (_pointsSummary == null) {
      return const Center(child: Text('Нет данных о баллах'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[400]!, Colors.orange[600]!],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Всего баллов',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$_totalPoints',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Разбор по активностям',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _pointsSummary!.breakdown.entries.length,
              itemBuilder: (context, index) {
                final entry = _pointsSummary!.breakdown.entries.elementAt(index);
                return _buildPointsBreakdownItem(entry.key, entry.value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsBreakdownItem(String activityType, int points) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getActivityIcon(activityType),
            color: _getActivityColor(activityType),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _translateActivityType(activityType),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+$points',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsTab() {
    if (_userSkills.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('Пока нет развитых навыков'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userSkills.length,
      itemBuilder: (context, index) {
        final skill = _userSkills[index];
        return _buildSkillCard(skill);
      },
    );
  }

  Widget _buildSkillCard(Map<String, dynamic> skill) {
    final progress = (skill['progress'] ?? 0) / 100.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.indigo[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    skill['skill_name'] ?? 'Unknown Skill',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '${skill['progress'] ?? 0}%',
                  style: TextStyle(
                    color: Colors.indigo[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo[600]!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsTab() {
    if (_userAchievements.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('Пока нет достижений'),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _userAchievements.length,
      itemBuilder: (context, index) {
        final achievement = _userAchievements[index];
        return _buildAchievementCard(achievement);
      },
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              color: Colors.amber[600],
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              achievement['achievement_name'] ?? 'Unknown Achievement',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (achievement['earned_at'] != null)
              Text(
                DateFormat('dd.MM.yyyy').format(DateTime.parse(achievement['earned_at'])),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatesTab() {
    if (_userCertificates.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_membership_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('Пока нет сертификатов'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userCertificates.length,
      itemBuilder: (context, index) {
        final certificate = _userCertificates[index];
        return _buildCertificateCard(certificate);
      },
    );
  }

  Widget _buildCertificateCard(Map<String, dynamic> certificate) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.card_membership,
                color: Colors.blue[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    certificate['certificate_name'] ?? 'Unknown Certificate',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (certificate['issued_at'] != null)
                    Text(
                      'Выдан: ${DateFormat('dd.MM.yyyy').format(DateTime.parse(certificate['issued_at']))}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // TODO: Download or view certificate
              },
              icon: const Icon(Icons.download),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red[600]!;
      case 'teacher':
        return Colors.orange[600]!;
      case 'student':
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _translateRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Администратор';
      case 'teacher':
        return 'Преподаватель';
      case 'student':
        return 'Студент';
      default:
        return 'Пользователь';
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

  String _translateActivityType(String activityType) {
    switch (activityType) {
      case 'lesson_completed':
        return 'Уроки завершены';
      case 'homework_completed':
        return 'Домашние задания';
      case 'module_completed':
        return 'Модули завершены';
      case 'course_completed':
        return 'Курсы завершены';
      case 'useful_post':
        return 'Полезные посты';
      default:
        return activityType;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'purchase_history':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PurchaseHistoryScreen()),
        );
        break;
      case 'admin_dashboard':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
        );
        break;
      case 'logout':
        _logout();
        break;
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердить выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }
}