import 'package:flutter/material.dart';
import '../models/course_models.dart';
import '../screens/module_screen.dart';
import '../services/course_service.dart';

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

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  Map<String, dynamic>? fullCourseData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourseDetails();
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
      appBar: AppBar(
        title: Text(title),
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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCourseHeader(context),
                  _buildCourseStats(context),
                  _buildCourseInfo(context),
                  _buildModulesSection(context),
                ],
              ),
            ),
    );
  }

  Widget _buildCourseHeader(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).primaryColor,
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
                if (_getCourseData('video_preview_url') != null)
                  const Icon(
                    Icons.play_circle_outline,
                    size: 64,
                    color: Colors.white,
                  )
                else
                  const Icon(
                    Icons.school,
                    size: 64,
                    color: Colors.white,
                  ),
                const SizedBox(height: 16),
                Text(
                  _getCourseData('title') ?? 'Course Title',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getCourseData('video_preview_url') != null ? 'Video Preview' : 'Image Preview',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
            child: _buildStatItem(
              context,
              'Students',
              '${_getCourseData('students_enrolled') ?? 0}',
              Icons.people,
              Colors.green,
            ),
          ),
          Flexible(
            child: _buildStatItem(
              context,
              'Projects',
              '${_getCourseData('student_projects') ?? 0}',
              Icons.work,
              Colors.blue,
            ),
          ),
          Flexible(
            child: _buildStatItem(
              context,
              'Q&A',
              '${_getCourseData('questions_answered') ?? 0}',
              Icons.question_answer,
              Colors.orange,
            ),
          ),
          Flexible(
            child: _buildStatItem(
              context,
              'Price',
              '\$${_getCourseData('price') ?? 0}',
              Icons.monetization_on,
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
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

  Widget _buildCourseInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Description',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            _getCourseData('description') ?? 'No description available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                context,
                _getCourseData('difficulty') ?? 'Beginner',
                _getDifficultyColor(_getCourseData('difficulty') ?? 'Beginner'),
              ),
              _buildInfoChip(
                context,
                _getCourseData('estimated_time') ?? 'Unknown',
                Colors.blue,
              ),
              _buildInfoChip(
                context,
                '${_getCourseData('modules') ?? 0} modules',
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
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

  Widget _buildModulesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Modules',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ..._buildModulesList(context),
        ],
      ),
    );
  }

  List<Widget> _buildModulesList(BuildContext context) {
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
      return _buildModuleCardFromData(context, module, index + 1);
    }).toList();
  }

  Widget _buildModuleCardFromData(BuildContext context, dynamic moduleData, int moduleNumber) {
    // Handle both Module objects and Map<String, dynamic> from database
    String title = '';
    String description = '';
    double price = 0.0;
    String? videoPreviewUrl;
    int lessonsCount = 0;
    String moduleId = '';
    
    // Debug: Print the type and content of moduleData
    print('ModuleData type: ${moduleData.runtimeType}');
    print('ModuleData content: $moduleData');
    
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
      print('Warning: moduleData is a List, taking first element');
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
      print('Warning: moduleData is neither Map nor List: ${moduleData.runtimeType}');
      title = 'Module $moduleNumber';
      description = 'No description available';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModuleScreen(moduleData: moduleData),
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
                        if (videoPreviewUrl != null)
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
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
                        '$lessonsCount lessons',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '0 completed', // TODO: Get actual completion count
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
}