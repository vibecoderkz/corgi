import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import '../services/user_service.dart';
import '../services/course_service.dart';
import '../services/points_config_service.dart';
import '../screens/settings_screen.dart';
import '../screens/purchase_history_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isAdmin = false;
  bool _isLoadingAdminStatus = true;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _userStats;
  List<Map<String, dynamic>> _userSkills = [];
  List<Map<String, dynamic>> _userAchievements = [];
  List<Map<String, dynamic>> _userCertificates = [];
  bool _isLoading = true;
  String _userRole = 'student';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Load user profile data
      final userProfile = await UserService.getCurrentUserProfile();
      final userStats = await UserService.getUserStats(currentUser.id);
      final userSkills = await UserService.getUserSkillProgress(currentUser.id);
      final userAchievements = await UserService.getUserAchievements(currentUser.id);
      final userCertificates = await UserService.getUserCertificates(currentUser.id);
      
      // Check admin status and role
      final isAdmin = await AdminService.isAdmin();
      final role = await AdminService.getCurrentUserRole();
      
      setState(() {
        _userProfile = userProfile;
        _userStats = userStats;
        _userSkills = userSkills;
        _userAchievements = userAchievements;
        _userCertificates = userCertificates;
        _isAdmin = isAdmin;
        _isLoadingAdminStatus = false;
        _userRole = role;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isAdmin = false;
        _isLoadingAdminStatus = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  _buildStatistics(),
                  _buildAchievements(),
                  _buildSkillProgress(),
                  _buildRecentCertificates(),
                  _buildAccountActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final currentUser = _authService.currentUser;
    final userName = _userProfile?['name'] ?? currentUser?.userMetadata?['name'] ?? 'User';
    final userEmail = currentUser?.email ?? 'user@example.com';
    final avatarUrl = _userProfile?['avatar_url'];
    
    // Get initials from name
    final initials = userName.split(' ').take(2).map((name) => name[0]).join().toUpperCase();
    
    // Role display mapping
    final roleDisplay = {
      'student': 'AI Learner',
      'admin': 'Administrator',
      'teacher': 'Instructor',
    };
    
    final roleColor = {
      'student': Colors.green,
      'admin': Colors.purple,
      'teacher': Colors.blue,
    };

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).primaryColor,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                    onPressed: () {
                      // TODO: Change profile picture
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            userEmail,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: (roleColor[_userRole] ?? Colors.green).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              roleDisplay[_userRole] ?? 'AI Learner',
              style: TextStyle(
                color: roleColor[_userRole] ?? Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final stats = _userStats ?? {};
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(child: _buildStatItem('${stats['streak'] ?? 0}', 'Day Streak', Icons.local_fire_department, Colors.orange)),
          Flexible(child: _buildPointsStatItem(stats['points'] ?? 0)),
          Flexible(child: _buildStatItem('${stats['courses_count'] ?? 0}', 'Courses', Icons.school, Colors.blue)),
          Flexible(child: _buildStatItem('${stats['certificates_count'] ?? 0}', 'Certificates', Icons.card_membership, Colors.green)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildPointsStatItem(int points) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: PointsConfigService.calculatePointsValue(points),
      builder: (context, snapshot) {
        String currencyValue = '';
        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;
          final symbol = data['currency_symbol'] ?? '';
          final value = data['currency_value'] ?? 0.0;
          currencyValue = '$symbol${value.toStringAsFixed(2)}';
        }
        
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: Colors.amber, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              '$points',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (currencyValue.isNotEmpty)
              Text(
                currencyValue,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            Text(
              'Points',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAchievements() {
    // Map achievement icons from database strings to Flutter icons
    final iconMap = {
      'flag': Icons.flag,
      'speed': Icons.speed,
      'lightbulb': Icons.lightbulb,
      'groups': Icons.groups,
      'star': Icons.star,
      'trophy': Icons.emoji_events,
      'medal': Icons.military_tech,
      'fire': Icons.local_fire_department,
    };

    final colorMap = {
      'flag': Colors.green,
      'speed': Colors.blue,
      'lightbulb': Colors.amber,
      'groups': Colors.purple,
      'star': Colors.orange,
      'trophy': Colors.red,
      'medal': Colors.teal,
      'fire': Colors.deepOrange,
    };

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Achievements',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: _userAchievements.isEmpty
                ? const Center(
                    child: Text(
                      'No achievements yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _userAchievements.length,
                    itemBuilder: (context, index) {
                      final achievement = _userAchievements[index];
                      final iconName = achievement['achievement_icon'] ?? 'star';
                      final icon = iconMap[iconName] ?? Icons.star;
                      final color = colorMap[iconName] ?? Colors.green;
                      
                      return Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icon,
                                color: color,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              achievement['achievement_name'] ?? 'Achievement',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillProgress() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skill Progress',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ..._userSkills.map((skill) {
            final progress = (skill['progress_percentage'] ?? 0.0) / 100.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          skill['skill_name'] ?? 'Unknown Skill',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('${(progress * 100).toInt()}%'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentCertificates() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Certificates',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  // TODO: View all certificates
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_userCertificates.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.card_membership, color: Colors.grey),
                title: Text('No certificates yet'),
                subtitle: Text('Complete courses to earn certificates'),
              ),
            )
          else
            ..._userCertificates.take(3).map((certificate) {
              final completionDate = certificate['completion_date'] != null
                  ? DateTime.parse(certificate['completion_date'])
                  : DateTime.now();
              
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.card_membership, color: Colors.green),
                  title: Text(certificate['course_title'] ?? 'Certificate'),
                  subtitle: Text('Completed on ${completionDate.day}/${completionDate.month}/${completionDate.year}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () {
                      // TODO: Download certificate
                    },
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Admin Panel Access (only visible to admins)
          if (_isAdmin && !_isLoadingAdminStatus) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Card(
                color: Colors.purple.withOpacity(0.1),
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings, color: Colors.purple),
                  title: const Text(
                    'Admin Dashboard',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('View statistics and manage content'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.purple),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminDashboardScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Quick Admin Actions
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Card(
                color: Colors.blue.withOpacity(0.1),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.add_circle, color: Colors.blue),
                      title: const Text(
                        'Quick Actions',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Add new content'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.school, color: Colors.blue),
                      title: const Text('Add New Course'),
                      onTap: () {
                        _showCreateCourseDialog();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.library_books, color: Colors.blue),
                      title: const Text('Add New Module'),
                      onTap: () {
                        _showCreateModuleDialog();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.book, color: Colors.blue),
                      title: const Text('Add New Lesson'),
                      onTap: () {
                        _showCreateLessonDialog();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          ListTile(
            leading: const Icon(Icons.history, color: Colors.green),
            title: const Text('История покупок'),
            subtitle: const Text('Просмотр купленных курсов и модулей'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PurchaseHistoryScreen(),
                ),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacy & Security'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _authService.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateCourseDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final difficultyController = TextEditingController();
    final estimatedTimeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Course'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Course Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: difficultyController,
                decoration: const InputDecoration(
                  labelText: 'Difficulty Level',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: estimatedTimeController,
                decoration: const InputDecoration(
                  labelText: 'Estimated Time',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty &&
                  priceController.text.isNotEmpty &&
                  difficultyController.text.isNotEmpty &&
                  estimatedTimeController.text.isNotEmpty) {
                
                final result = await AdminService.createCourse(
                  title: titleController.text,
                  description: descriptionController.text,
                  price: double.parse(priceController.text),
                  difficulty: difficultyController.text,
                  estimatedTime: estimatedTimeController.text,
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Course created successfully'),
                      backgroundColor: result['success'] ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateModuleDialog() async {
    // First, get list of available courses
    final courses = await CourseService.getAllCourses();
    
    if (courses.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No courses available. Create a course first.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final orderIndexController = TextEditingController();
    String selectedCourseId = courses.first['id'];
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Create New Module'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCourseId,
                  decoration: const InputDecoration(
                    labelText: 'Select Course',
                    border: OutlineInputBorder(),
                  ),
                  items: courses.map<DropdownMenuItem<String>>((course) {
                    return DropdownMenuItem<String>(
                      value: course['id'],
                      child: Text(
                        course['title'],
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      selectedCourseId = newValue;
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Module Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: orderIndexController,
                  decoration: const InputDecoration(
                    labelText: 'Order Index (1, 2, 3...)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty &&
                    priceController.text.isNotEmpty &&
                    orderIndexController.text.isNotEmpty) {
                  
                  final result = await AdminService.createModule(
                    courseId: selectedCourseId,
                    title: titleController.text,
                    description: descriptionController.text,
                    price: double.parse(priceController.text),
                    orderIndex: int.parse(orderIndexController.text),
                  );
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? 'Module created successfully'),
                        backgroundColor: result['success'] ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      );
    }
  }

  void _showCreateLessonDialog() async {
    // First, get list of available modules
    final courses = await CourseService.getAllCourses();
    
    if (courses.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No courses available. Create a course first.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    // Get modules for the first course initially
    List<Map<String, dynamic>> modules = [];
    String selectedCourseId = courses.first['id'];
    
    try {
      modules = await CourseService.getCourseModules(selectedCourseId);
    } catch (e) {
      modules = [];
    }
    
    if (modules.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No modules available. Create a module first.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final orderIndexController = TextEditingController();
    final durationController = TextEditingController();
    String selectedModuleId = modules.first['id'];
    String selectedContentType = 'video';
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Create New Lesson'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCourseId,
                    decoration: const InputDecoration(
                      labelText: 'Select Course',
                      border: OutlineInputBorder(),
                    ),
                    items: courses.map<DropdownMenuItem<String>>((course) {
                      return DropdownMenuItem<String>(
                        value: course['id'],
                        child: Text(
                          course['title'],
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) async {
                      if (newValue != null) {
                        selectedCourseId = newValue;
                        // Load modules for the selected course
                        try {
                          final newModules = await CourseService.getCourseModules(selectedCourseId);
                          setState(() {
                            modules = newModules;
                            if (modules.isNotEmpty) {
                              selectedModuleId = modules.first['id'];
                            }
                          });
                        } catch (e) {
                          setState(() {
                            modules = [];
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: modules.isNotEmpty ? selectedModuleId : null,
                    decoration: const InputDecoration(
                      labelText: 'Select Module',
                      border: OutlineInputBorder(),
                    ),
                    items: modules.map<DropdownMenuItem<String>>((module) {
                      return DropdownMenuItem<String>(
                        value: module['id'],
                        child: Text(
                          module['title'],
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        selectedModuleId = newValue;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Lesson Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: orderIndexController,
                    decoration: const InputDecoration(
                      labelText: 'Order Index (1, 2, 3...)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedContentType,
                    decoration: const InputDecoration(
                      labelText: 'Content Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'video', child: Text('Video')),
                      DropdownMenuItem(value: 'text', child: Text('Text')),
                      DropdownMenuItem(value: 'interactive', child: Text('Interactive')),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        selectedContentType = newValue;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty &&
                      descriptionController.text.isNotEmpty &&
                      priceController.text.isNotEmpty &&
                      orderIndexController.text.isNotEmpty &&
                      modules.isNotEmpty) {
                    
                    final result = await AdminService.createLesson(
                      moduleId: selectedModuleId,
                      title: titleController.text,
                      description: descriptionController.text,
                      price: double.parse(priceController.text),
                      orderIndex: int.parse(orderIndexController.text),
                      contentType: selectedContentType,
                      durationMinutes: durationController.text.isNotEmpty ? int.parse(durationController.text) : null,
                    );
                    
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message'] ?? 'Lesson created successfully'),
                          backgroundColor: result['success'] ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      );
    }
  }
}