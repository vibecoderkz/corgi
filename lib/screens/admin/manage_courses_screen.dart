import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/course_service.dart';
import 'create_course_screen.dart';
import 'edit_course_screen.dart';

class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  List<Map<String, dynamic>> courses = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      isLoading = true;
    });

    try {
      final loadedCourses = await CourseService.getAllCourses();
      setState(() {
        courses = loadedCourses;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load courses: $e')),
        );
      }
    }
  }

  Future<void> _deleteCourse(String courseId, String courseTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Are you sure you want to delete "$courseTitle"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await AdminService.deleteCourse(courseId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: result['success'] ? Colors.green : Colors.red,
            ),
          );
          
          if (result['success'] == true) {
            _loadCourses(); // Refresh the list
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting course: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleCourseStatus(String courseId, bool currentStatus) async {
    try {
      final result = await AdminService.updateCourse(
        courseId: courseId,
        isActive: !currentStatus,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
        
        if (result['success'] == true) {
          _loadCourses(); // Refresh the list
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating course: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get filteredCourses {
    if (searchQuery.isEmpty) return courses;
    
    return courses.where((course) {
      final title = course['title']?.toString().toLowerCase() ?? '';
      final description = course['description']?.toString().toLowerCase() ?? '';
      final difficulty = course['difficulty']?.toString().toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();
      
      return title.contains(query) || 
             description.contains(query) || 
             difficulty.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateCourseScreen(),
                ),
              );
              if (result == true) {
                _loadCourses(); // Refresh if course was created
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCourses,
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
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search courses',
                hintText: 'Search by title, description, or difficulty',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          
          // Courses List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredCourses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              searchQuery.isEmpty ? Icons.school_outlined : Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isEmpty
                                  ? 'No courses found'
                                  : 'No courses match your search',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (searchQuery.isEmpty)
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CreateCourseScreen(),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadCourses();
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Create First Course'),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCourses,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filteredCourses.length,
                          itemBuilder: (context, index) {
                            final course = filteredCourses[index];
                            return _buildCourseCard(course);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final isActive = course['is_active'] ?? true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.blue : Colors.grey,
          child: Icon(
            Icons.school,
            color: Colors.white,
          ),
        ),
        title: Text(
          course['title'] ?? 'Untitled Course',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? null : Colors.grey[600],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course['description'] ?? 'No description',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isActive ? null : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    course['difficulty'] ?? 'Unknown',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: _getDifficultyColor(course['difficulty']).withOpacity(0.2),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    '\$${course['price']?.toString() ?? '0.00'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.green.withOpacity(0.2),
                ),
                const SizedBox(width: 8),
                if (!isActive)
                  Chip(
                    label: const Text(
                      'Inactive',
                      style: TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.red.withOpacity(0.2),
                  ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Course Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Estimated Time', course['estimated_time'] ?? 'Not specified'),
                _buildDetailRow('Created', _formatDate(course['created_at'])),
                _buildDetailRow('Last Updated', _formatDate(course['updated_at'])),
                if (course['image_url'] != null)
                  _buildDetailRow('Image URL', course['image_url']),
                if (course['video_preview_url'] != null)
                  _buildDetailRow('Video URL', course['video_preview_url']),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditCourseScreen(course: course),
                            ),
                          );
                          if (result == true) {
                            _loadCourses();
                          }
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleCourseStatus(course['id'], isActive),
                        icon: Icon(isActive ? Icons.visibility_off : Icons.visibility),
                        label: Text(isActive ? 'Deactivate' : 'Activate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive ? Colors.orange : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteCourse(course['id'], course['title']),
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not specified',
              style: TextStyle(
                color: value == null ? Colors.grey[600] : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}