import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CourseOverviewScreen extends StatefulWidget {
  final String courseTitle;
  final CourseOverview? courseData;
  
  const CourseOverviewScreen({
    super.key,
    required this.courseTitle,
    this.courseData,
  });
  
  @override
  State<CourseOverviewScreen> createState() => _CourseOverviewScreenState();
}

class _CourseOverviewScreenState extends State<CourseOverviewScreen> 
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late AnimationController _playButtonController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _playButtonScale;
  
  late CourseOverview courseData;
  
  // Design constants
  static const backgroundColor = Color(0xFFF8FAFC);
  static const cardColor = Colors.white;
  static const primaryColor = Color(0xFF6366F1);
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  
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
  
  // Sizes
  static const double videoSectionHeight = 280.0;
  static const double playButtonSize = 80.0;
  static const double statIconSize = 50.0;
  static const double cardBorderRadius = 16.0;
  static const double tagBorderRadius = 20.0;
  static const double screenPadding = 20.0;
  static const double sectionSpacing = 24.0;
  static const double cardPadding = 20.0;
  
  static const List<BoxShadow> cardShadow = [
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
    _loadCourseData();
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

  void _loadCourseData() {
    // Use provided data or default sample data
    courseData = widget.courseData ?? CourseOverview(
      title: widget.courseTitle,
      description: "Learn the fundamentals of artificial intelligence and how it's changing our world",
      students: 0,
      projects: 0,
      qna: 0,
      price: 29.99,
      level: "Beginner",
      duration: "4 weeks",
      hasAccess: true,
      videoPreviewUrl: "assets/videos/intro_preview.mp4",
      jsonData: "[{id: 550e8400-e29b-41d4-a716-446655440011, price: 4.99, title: What is AI?, lessons: [{id: 550e8400-e29b-41d4-a716-446655440111, price: 0.99, title: Introduction to AI, homework: [{id: 550e8400-e29b-41d4-a716-446655441111, title: AI Concepts Quiz, description: Complete the quiz about basic AI concepts, requirements: [Watch the video, Complete 10 questions], points_reward: 10, submission_format: online_quiz}], is_active: true, content_url: assets/lessons/1-1-1.mp4, description: Basic concepts and terminology of artificial intelligence.",
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _playButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: CustomScrollView(
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
                if (courseData.hasAccess)
                  _buildAnimatedSection(
                    child: _buildAccessStatus(),
                    delay: 0.2,
                  ),
                _buildAnimatedSection(
                  child: _buildCourseDescription(),
                  delay: 0.3,
                ),
                const SizedBox(height: sectionSpacing),
                _buildAnimatedSection(
                  child: _buildJsonData(),
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

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF3F4F6),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.courseTitle,
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
      height: videoSectionHeight,
      margin: const EdgeInsets.fromLTRB(0, 0, 0, sectionSpacing),
      decoration: const BoxDecoration(
        gradient: videoGradient,
      ),
      child: Stack(
        children: [
          // Центрированный контент
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
                          width: playButtonSize,
                          height: playButtonSize,
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
                  courseData.title,
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
          // Кнопка Video Preview
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
            "${courseData.students}",
            "Students",
            studentsColor,
          ),
          _buildStatItem(
            Icons.work,
            "${courseData.projects}",
            "Projects",
            projectsColor,
          ),
          _buildStatItem(
            Icons.chat_bubble_outline,
            "${courseData.qna}",
            "Q&A",
            qaColor,
          ),
          _buildStatItem(
            Icons.attach_money,
            "\$${courseData.price.toStringAsFixed(2)}",
            "Price",
            priceColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: statIconSize,
          height: statIconSize,
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
            courseData.description,
            style: const TextStyle(
              fontSize: 16,
              color: textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildDescriptionTag(courseData.level, const Color(0xFF10B981)),
              const SizedBox(width: 12),
              _buildDescriptionTag(courseData.duration, const Color(0xFF3B82F6)),
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
        borderRadius: BorderRadius.circular(tagBorderRadius),
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

  Widget _buildJsonData() {
    return Container(
      margin: const EdgeInsets.all(screenPadding),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          courseData.jsonData,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF065F46),
            fontFamily: 'monospace',
          ),
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
    
    // Show video preview dialog or navigate to video player
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
    
    // Navigate to course modules or first lesson
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
  }
}

// Course Overview Model
class CourseOverview {
  final String title;
  final String description;
  final int students;
  final int projects;
  final int qna;
  final double price;
  final String level;
  final String duration;
  final bool hasAccess;
  final String videoPreviewUrl;
  final String jsonData;
  
  CourseOverview({
    required this.title,
    required this.description,
    required this.students,
    required this.projects,
    required this.qna,
    required this.price,
    required this.level,
    required this.duration,
    required this.hasAccess,
    required this.videoPreviewUrl,
    required this.jsonData,
  });
}