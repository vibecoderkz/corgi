import 'package:flutter/material.dart';
import 'course_details_screen.dart';
import 'search_screen.dart';
import '../services/course_service.dart';
import '../services/purchase_service.dart';
import '../models/course_models.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> 
    with TickerProviderStateMixin {
  
  // Data
  List<Course> courses = [];
  List<Course> filteredCourses = [];
  bool isLoading = true;
  String selectedFilter = "All";
  final List<String> filters = ["All", "In Progress", "Not Started", "Completed"];
  
  // Animation
  late AnimationController _animationController;
  
  // Design constants
  static const backgroundColor = Color(0xFFF8FAFC);
  static const cardColor = Colors.white;
  static const primaryColor = Color(0xFF6366F1);
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const purpleGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const purchasedColor = Color(0xFF10B981);
  static const beginnerColor = Color(0xFF10B981);
  static const intermediateColor = Color(0xFFF59E0B);
  
  // Sizes
  static const double cardBorderRadius = 16.0;
  static const double cardPadding = 20.0;
  static const double cardImageHeight = 200.0;
  static const double chipBorderRadius = 20.0;
  static const double filterChipHeight = 50.0;
  static const double screenPadding = 20.0;
  static const double cardSpacing = 16.0;
  static const double sectionSpacing = 16.0;
  
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 25,
      offset: Offset(0, 8),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadCourses();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load real courses from database
      final realCourses = await CourseService.getAllCourses();
      
      if (realCourses.isNotEmpty) {
        // Convert database courses to Course objects
        courses = realCourses.map((courseData) => Course(
          id: courseData['id'] ?? '',
          title: courseData['title'] ?? 'Unknown Course',
          description: courseData['description'] ?? 'No description available',
          duration: int.tryParse(courseData['estimated_time']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '4') ?? 4,
          students: courseData['students_enrolled'] ?? 0,
          projects: courseData['student_projects'] ?? 0,
          qna: courseData['questions_answered'] ?? 0,
          level: courseData['difficulty'] ?? 'Beginner',
          status: _determineStatus(courseData),
          price: double.tryParse(courseData['price']?.toString() ?? '0') ?? 0.0,
          gradient: _getGradientForCourse(courseData['difficulty'] ?? 'Beginner'),
          icon: _getIconForCourse(courseData['difficulty'] ?? 'Beginner'),
        )).toList();
      } else {
        // Fallback to sample data if no database courses
        courses = _getSampleCourses();
      }
      
      filteredCourses = courses;
      
      // Start animations after loading
      _animationController.forward();
    } catch (e) {
      // Fallback to sample data on error
      courses = _getSampleCourses();
      filteredCourses = courses;
      _animationController.forward();
    }

    setState(() {
      isLoading = false;
    });
  }

  List<Course> _getSampleCourses() {
    return [
      Course(
        id: '1',
        title: "Introduction to AI",
        description: "Learn the fundamentals of artificial intelligence and how it's changing our world",
        duration: 4,
        students: 1,
        projects: 0,
        qna: 4,
        level: "Beginner",
        status: "Purchased",
        price: 29.99,
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.psychology,
      ),
      Course(
        id: '2',
        title: "Machine Learning Basics",
        description: "Master the fundamentals of machine learning algorithms and applications",
        duration: 6,
        students: 0,
        projects: 3,
        qna: 8,
        level: "Intermediate",
        status: "Not Started",
        price: 49.99,
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.developer_board,
      ),
      Course(
        id: '3',
        title: "Deep Learning Advanced",
        description: "Dive deep into neural networks and advanced machine learning concepts",
        duration: 8,
        students: 2,
        projects: 5,
        qna: 12,
        level: "Advanced",
        status: "In Progress",
        price: 79.99,
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.memory,
      ),
      Course(
        id: '4',
        title: "Data Science Fundamentals",
        description: "Learn data analysis, visualization, and statistical modeling techniques",
        duration: 5,
        students: 0,
        projects: 2,
        qna: 6,
        level: "Beginner",
        status: "Completed",
        price: 39.99,
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.analytics,
      ),
    ];
  }

  String _determineStatus(Map<String, dynamic> courseData) {
    // You can implement logic here to determine course status based on user data
    // For now, return a default status
    return "Not Started";
  }
  
  LinearGradient _getGradientForCourse(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'intermediate':
        return const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'advanced':
        return const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
  
  IconData _getIconForCourse(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Icons.psychology;
      case 'intermediate':
        return Icons.developer_board;
      case 'advanced':
        return Icons.memory;
      default:
        return Icons.analytics;
    }
  }

  void _filterCourses(String filter) {
    setState(() {
      selectedFilter = filter;
      if (filter == "All") {
        filteredCourses = courses;
      } else {
        filteredCourses = courses.where((course) => course.status == filter).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: sectionSpacing),
                _buildFilterChips(),
                const SizedBox(height: sectionSpacing),
                _buildCoursesList(),
              ],
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Courses',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: textSecondary, size: 24),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.home, color: textSecondary, size: 24),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/main',
              (route) => false,
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: filterChipHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: screenPadding),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          itemBuilder: (context, index) {
            final filter = filters[index];
            final isSelected = selectedFilter == filter;
            
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) const Icon(Icons.check, size: 16, color: Colors.white),
                    if (isSelected) const SizedBox(width: 4),
                    Text(filter),
                  ],
                ),
                selected: isSelected,
                onSelected: (bool selected) {
                  _filterCourses(filter);
                },
                backgroundColor: Colors.transparent,
                selectedColor: primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                side: BorderSide(
                  color: isSelected ? primaryColor : const Color(0xFFE5E7EB),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCoursesList() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: screenPadding),
        child: ListView.builder(
          itemCount: filteredCourses.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: cardSpacing),
              child: _buildAnimatedCourseCard(filteredCourses[index], index),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedCourseCard(Course course, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              index * 0.1,
              (index * 0.1) + 0.3,
              curve: Curves.easeOut,
            ),
          ),
        );
        
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(animation),
            child: CourseCard(course: course, index: index),
          ),
        );
      },
    );
  }
}

// Course Model
class Course {
  final String id;
  final String title;
  final String description;
  final int duration;
  final int students;
  final int projects;
  final int qna;
  final String level;
  final String status;
  final double price;
  final LinearGradient gradient;
  final IconData icon;
  
  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.students,
    required this.projects,
    required this.qna,
    required this.level,
    required this.status,
    required this.price,
    required this.gradient,
    required this.icon,
  });
}

// Course Card Widget
class CourseCard extends StatelessWidget {
  final Course course;
  final int index;
  
  const CourseCard({super.key, required this.course, required this.index});
  
  static const backgroundColor = Color(0xFFF8FAFC);
  static const cardColor = Colors.white;
  static const primaryColor = Color(0xFF6366F1);
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const purchasedColor = Color(0xFF10B981);
  static const beginnerColor = Color(0xFF10B981);
  static const intermediateColor = Color(0xFFF59E0B);
  static const advancedColor = Color(0xFFEF4444);
  
  static const double cardBorderRadius = 16.0;
  static const double cardPadding = 20.0;
  static const double cardImageHeight = 200.0;
  static const double chipBorderRadius = 20.0;
  
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 25,
      offset: Offset(0, 8),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardBorderRadius)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseDetailsScreen(
                  course: course,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(cardBorderRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCourseImage(),
              _buildCourseContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseImage() {
    return Container(
      height: cardImageHeight,
      decoration: BoxDecoration(
        gradient: course.gradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(cardBorderRadius)),
      ),
      child: Center(
        child: Icon(
          course.icon,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCourseContent() {
    return Padding(
      padding: const EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  course.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildLevelChip(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            course.description,
            style: const TextStyle(
              fontSize: 14,
              color: textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildCourseMetadata(),
          const SizedBox(height: 16),
          _buildCourseFooter(),
        ],
      ),
    );
  }

  Widget _buildCourseMetadata() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildMetadataItem(Icons.access_time, "${course.duration} weeks"),
        _buildMetadataItem(Icons.people, "${course.students} students"),
        _buildMetadataItem(Icons.work, "${course.projects} projects"),
        _buildMetadataItem(Icons.chat_bubble_outline, "${course.qna} Q&A"),
      ],
    );
  }

  Widget _buildMetadataItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelChip() {
    Color chipColor;
    switch (course.level) {
      case "Beginner":
        chipColor = beginnerColor;
        break;
      case "Intermediate":
        chipColor = intermediateColor;
        break;
      case "Advanced":
        chipColor = advancedColor;
        break;
      default:
        chipColor = textSecondary;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(chipBorderRadius),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        course.level,
        style: TextStyle(
          fontSize: 12,
          color: chipColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCourseFooter() {
    Color statusColor;
    switch (course.status) {
      case "Purchased":
      case "Completed":
        statusColor = purchasedColor;
        break;
      case "In Progress":
        statusColor = intermediateColor;
        break;
      case "Not Started":
        statusColor = textSecondary;
        break;
      default:
        statusColor = textSecondary;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(chipBorderRadius),
          ),
          child: Text(
            course.status,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          "\$${course.price.toStringAsFixed(2)}",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}