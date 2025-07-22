import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/course_models.dart';
import '../screens/module_screen.dart';
import '../services/course_service.dart';
import '../services/purchase_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class CourseDetailsScreen extends StatefulWidget {
  final dynamic course; // Accept either Course object or Map<String, dynamic> from database
  final Map<String, dynamic>? courseData; // Explicitly for database data

  const CourseDetailsScreen({
    super.key,
    this.course,
    this.courseData,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> 
    with TickerProviderStateMixin {
  Map<String, dynamic>? fullCourseData;
  bool isLoading = true;
  bool hasAccess = false;
  bool isCheckingAccess = false;
  int userPoints = 0;
  
  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _playButtonController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _playButtonScale;
  
  // Design constants
  static const backgroundColor = Color(0xFFF8FAFC);
  static const cardColor = Colors.white;
  static const primaryColor = Color(0xFF6366F1);
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  
  static const videoGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const studentsColor = Color(0xFF10B981);
  static const projectsColor = Color(0xFF3B82F6);
  static const qaColor = Color(0xFFF59E0B);
  static const priceColor = Color(0xFF8B5CF6);
  
  static const accessStatusColor = Color(0xFF10B981);
  static const accessBackgroundColor = Color(0xFFDCFCE7);
  
  static const cardBorderRadius = 16.0;
  static const cardPadding = 20.0;
  static const sectionSpacing = 24.0;
  static const screenPadding = 20.0;
  
  static const cardShadow = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadCourseDetails();
    _checkAccess();
    _loadUserPoints();
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _playButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _playButtonScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _playButtonController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _playButtonController.dispose();
    super.dispose();
  }

  Future<void> _loadCourseDetails() async {
    try {
      String courseId = '';
      
      // Get course ID from either source
      if (widget.courseData != null) {
        courseId = widget.courseData!['id'];
      } else if (widget.course != null && widget.course is Map<String, dynamic>) {
        courseId = widget.course['id'];
      } else if (widget.course != null && widget.course is Course) {
        courseId = widget.course.id;
      }

      if (courseId.isNotEmpty) {
        final courseDetails = await CourseService.getCourseDetails(courseId);
        if (mounted) {
          setState(() {
            fullCourseData = courseDetails;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _checkAccess() async {
    setState(() {
      isCheckingAccess = true;
    });

    try {
      String courseId = _getCourseId();
      if (courseId.isNotEmpty) {
        final access = await PurchaseService.hasAccessToCourse(courseId);
        if (mounted) {
          setState(() {
            hasAccess = access;
            isCheckingAccess = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isCheckingAccess = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isCheckingAccess = false;
        });
      }
    }
  }

  Future<void> _loadUserPoints() async {
    try {
      final points = await UserService.getUserPoints();
      if (mounted) {
        setState(() {
          userPoints = points;
        });
      }
    } catch (e) {
      // Points loading is optional
    }
  }

  String _getCourseId() {
    if (widget.courseData != null) {
      return widget.courseData!['id'] ?? '';
    } else if (widget.course != null && widget.course is Map<String, dynamic>) {
      return widget.course['id'] ?? '';
    } else if (widget.course != null && widget.course is Course) {
      return widget.course.id;
    }
    return '';
  }

  Future<void> _purchaseCourse() async {
    if (!AuthService().isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, войдите в систему для покупки')),
      );
      return;
    }

    final coursePrice = _getCourseData('price');
    if (coursePrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Цена курса недоступна')),
      );
      return;
    }

    final price = double.tryParse(coursePrice.toString()) ?? 0.0;
    await _showPurchaseDialog(
      'курс', 
      _getCourseData('title') ?? 'Курс',
      price,
      () => _executePurchase('course', price),
    );
  }

  Future<void> _showPurchaseDialog(String type, String title, double price, VoidCallback onConfirm) async {
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Купить $type'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Название: $title'),
                const SizedBox(height: 8),
                Text('Цена: \$${price.toStringAsFixed(2)}'),
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
                onConfirm();
              },
              child: const Text('Купить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executePurchase(String type, double price) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Обработка покупки...'),
          ],
        ),
      ),
    );

    try {
      Map<String, dynamic> result;
      String courseId = _getCourseId();

      switch (type) {
        case 'course':
          result = await PurchaseService.purchaseCourse(
            courseId, 
            price, 
            'points_demo',
          );
          break;
        default:
          result = {'success': false, 'message': 'Неизвестный тип покупки'};
      }

      Navigator.pop(context); // Close loading dialog

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Покупка успешна!'),
            backgroundColor: Colors.green,
          ),
        );
        await _checkAccess(); // Refresh access status
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Ошибка покупки'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to get data from either source
  dynamic _getCourseData(String key) {
    // First check if we have loaded full course data
    if (fullCourseData != null) {
      return fullCourseData![key];
    }
    
    // Fallback to original data sources
    if (widget.courseData != null) {
      return widget.courseData![key];
    } else if (widget.course != null && widget.course is Course) {
      final courseObj = widget.course as Course;
      switch (key) {
        case 'title': return courseObj.title;
        case 'description': return courseObj.description;
        case 'price': return courseObj.price;
        case 'difficulty': return courseObj.difficulty;
        case 'estimated_time': return courseObj.estimatedTime;
        case 'id': return courseObj.id;
        case 'video_preview_url': return courseObj.videoPreviewUrl;
        case 'students_enrolled': return courseObj.studentsEnrolled;
        case 'student_projects': return courseObj.studentProjects;
        case 'questions_answered': return courseObj.questionsAnswered;
        case 'modules': return courseObj.modules;
        case 'modulesList': return courseObj.modulesList;
        default: return null;
      }
    } else if (widget.course != null && widget.course is Map<String, dynamic>) {
      final courseMap = widget.course as Map<String, dynamic>;
      return courseMap[key];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final title = _getCourseData('title') ?? 'Course Details';
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(title),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAnimatedSection(
                        child: _buildVideoPreviewSection(),
                        delay: 0.0,
                      ),
                      _buildAnimatedSection(
                        child: _buildCourseStats(),
                        delay: 0.1,
                      ),
                      const SizedBox(height: sectionSpacing),
                      if (hasAccess && !isCheckingAccess)
                        _buildAnimatedSection(
                          child: _buildAccessStatus(),
                          delay: 0.2,
                        )
                      else if (!isCheckingAccess)
                        _buildAnimatedSection(
                          child: _buildPurchaseSection(),
                          delay: 0.2,
                        ),
                      _buildAnimatedSection(
                        child: _buildCourseDescription(),
                        delay: 0.3,
                      ),
                      const SizedBox(height: sectionSpacing),
                      _buildAnimatedSection(
                        child: _buildModulesSection(),
                        delay: 0.4,
                      ),
                      const SizedBox(height: 100), // Bottom padding
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  AppBar _buildAppBar(String title) {
    return AppBar(
      backgroundColor: const Color(0xFFF3F4F6),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.home, color: textPrimary),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/main',
            (route) => false,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPreviewSection() {
    return Container(
      height: 280,
      margin: const EdgeInsets.fromLTRB(0, 0, 0, sectionSpacing),
      decoration: const BoxDecoration(
        gradient: videoGradient,
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTapDown: (_) => _playButtonController.forward(),
                  onTapUp: (_) {
                    _playButtonController.reverse();
                    _handlePlayButton();
                  },
                  onTapCancel: () => _playButtonController.reverse(),
                  child: AnimatedBuilder(
                    animation: _playButtonScale,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _playButtonScale.value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _getCourseData('title') ?? 'Course Title',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: _handleVideoPreview,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'Video Preview',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: screenPadding),
      padding: const EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        boxShadow: cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(
            Icons.people,
            "${_getCourseData('students_enrolled') ?? 0}",
            "Students",
            studentsColor,
          ),
          _buildStatItem(
            Icons.work,
            "${_getCourseData('student_projects') ?? 0}",
            "Projects",
            projectsColor,
          ),
          _buildStatItem(
            Icons.chat_bubble_outline,
            "${_getCourseData('questions_answered') ?? 0}",
            "Q&A",
            qaColor,
          ),
          _buildStatItem(
            Icons.attach_money,
            "\$${_getCourseData('price')?.toStringAsFixed(2) ?? '0.00'}",
            "Price",
            priceColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAccessStatus() {
    return Container(
      margin: const EdgeInsets.all(screenPadding),
      padding: const EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: accessBackgroundColor,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(
          color: accessStatusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: accessStatusColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'У вас есть доступ к этому курсу',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: accessStatusColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Вы можете просматривать все модули и уроки',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF065F46),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseSection() {
    return Container(
      margin: const EdgeInsets.all(screenPadding),
      padding: const EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.lock, color: Colors.orange[600], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Для доступа к курсу требуется покупка',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Купите курс, чтобы получить доступ ко всем модулям и урокам',
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _purchaseCourse,
              icon: const Icon(Icons.shopping_cart),
              label: Text(
                'Купить курс за \$${_getCourseData('price')?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Course Description',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getCourseData('description') ?? 'No description available',
            style: const TextStyle(
              fontSize: 16,
              color: textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildDescriptionTag(
                _getCourseData('difficulty') ?? 'Beginner', 
                _getDifficultyColor(_getCourseData('difficulty') ?? 'Beginner')
              ),
              const SizedBox(width: 12),
              _buildDescriptionTag(
                _getCourseData('estimated_time') ?? 'Unknown', 
                const Color(0xFF3B82F6)
              ),
              const SizedBox(width: 12),
              _buildDescriptionTag(
                '${_getCourseData('modules') ?? 0} modules', 
                const Color(0xFF10B981)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildModulesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Course Modules',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._buildModulesList(),
        ],
      ),
    );
  }

  List<Widget> _buildModulesList() {
    // Try to get modules from different sources
    List<dynamic> modules = [];
    
    // First, check if we have loaded full course data with modules
    if (fullCourseData != null && fullCourseData!['modules'] != null) {
      final moduleData = fullCourseData!['modules'];
      if (moduleData is List) {
        modules = moduleData;
      }
    }
    
    // Fallback: Check if it's from original course data (modules field)
    if (modules.isEmpty && _getCourseData('modules') != null) {
      final moduleData = _getCourseData('modules');
      if (moduleData is List) {
        modules = moduleData;
      }
    }
    
    // Check if it's from Course object (modulesList field)
    if (modules.isEmpty && _getCourseData('modulesList') != null) {
      final moduleData = _getCourseData('modulesList');
      if (moduleData is List) {
        modules = moduleData;
      }
    }
    
    if (modules.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No modules available',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This course doesn\'t have any modules yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ];
    }
    
    return modules.asMap().entries.map((entry) {
      final index = entry.key;
      final module = entry.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: _buildModuleCardFromData(module, index + 1),
      );
    }).toList();
  }

  Widget _buildModuleCardFromData(dynamic moduleData, int moduleNumber) {
    // Handle both Module objects and Map<String, dynamic> from database
    String title = '';
    String description = '';
    double price = 0.0;
    String? videoPreviewUrl;
    int lessonsCount = 0;
    String moduleId = '';
    
    // Debug: Print the type and content of moduleData
    
    if (moduleData is Map<String, dynamic>) {
      title = moduleData['title'] ?? 'Module $moduleNumber';
      description = moduleData['description'] ?? 'No description available';
      price = double.tryParse(moduleData['price']?.toString() ?? '0') ?? 0.0;
      videoPreviewUrl = moduleData['video_preview_url'];
      moduleId = moduleData['id'] ?? '';
      
      // Count lessons if available
      if (moduleData['lessons'] is List) {
        lessonsCount = (moduleData['lessons'] as List).length;
      }
    } else if (moduleData is List) {
      // Handle case where moduleData is unexpectedly a List
      if (moduleData.isNotEmpty && moduleData.first is Map<String, dynamic>) {
        final actualModule = moduleData.first as Map<String, dynamic>;
        title = actualModule['title'] ?? 'Module $moduleNumber';
        description = actualModule['description'] ?? 'No description available';
        price = double.tryParse(actualModule['price']?.toString() ?? '0') ?? 0.0;
        videoPreviewUrl = actualModule['video_preview_url'];
        moduleId = actualModule['id'] ?? '';
        
        if (actualModule['lessons'] is List) {
          lessonsCount = (actualModule['lessons'] as List).length;
        }
        moduleData = actualModule; // Replace moduleData with the actual module object
      } else {
        title = 'Module $moduleNumber';
        description = 'Invalid module data';
      }
    } else {
      // Handle Module object case or other fallback
      title = 'Module $moduleNumber';
      description = 'No description available';
    }
    
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardBorderRadius)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModuleScreen(moduleData: moduleData),
            ),
          );
        },
        borderRadius: BorderRadius.circular(cardBorderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(cardBorderRadius)),
                gradient: LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          videoPreviewUrl != null ? Icons.play_circle_outline : Icons.book,
                          size: 40,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Module $moduleNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.book, size: 16, color: textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '$lessonsCount lessons',
                        style: const TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.people, size: 16, color: textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '0 completed',
                        style: const TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tap to view details',
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: primaryColor,
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

  Widget _buildModuleCard(BuildContext context, Module module, int moduleNumber) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModuleScreen(module: module),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.7),
                    Theme.of(context).primaryColor.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (module.videoPreviewUrl != null)
                          const Icon(
                            Icons.play_circle_outline,
                            size: 40,
                            color: Colors.white,
                          )
                        else
                          const Icon(
                            Icons.book,
                            size: 40,
                            color: Colors.white,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Module $moduleNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '\$${module.price}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    module.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.book, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${module.lessons} lessons',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${module.studentsCompleted} completed',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tap to view details',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Theme.of(context).primaryColor,
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
  
  Widget _buildAnimatedSection({required Widget child, double delay = 0.0}) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        final animation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(delay, delay + 0.3, curve: Curves.easeOut),
          ),
        );
        
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
  
  
  void _handleVideoPreview() {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Preview'),
        content: const Text('Video player would be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handlePlayButton() {
    HapticFeedback.lightImpact();
    
    if (hasAccess) {
      // Navigate to first module if available
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start Course'),
          content: const Text('Navigate to course modules would be implemented here'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to course content
              },
              child: const Text('Start Learning'),
            ),
          ],
        ),
      );
    } else {
      // Show purchase dialog
      _purchaseCourse();
    }
  }
}