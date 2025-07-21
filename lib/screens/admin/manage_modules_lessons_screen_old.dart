import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/course_service.dart';

class ManageModulesLessonsScreen extends StatefulWidget {
  const ManageModulesLessonsScreen({super.key});

  @override
  State<ManageModulesLessonsScreen> createState() => _ManageModulesLessonsScreenState();
}

class _ManageModulesLessonsScreenState extends State<ManageModulesLessonsScreen> {
  List<Map<String, dynamic>> courses = [];
  List<Map<String, dynamic>> modules = [];
  List<Map<String, dynamic>> lessons = [];
  String? selectedCourseId;
  String? selectedModuleId;
  bool isLoading = true;
  bool isLoadingModules = false;
  bool isLoadingLessons = false;

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

  Future<void> _loadModules(String courseId) async {
    setState(() {
      isLoadingModules = true;
      selectedCourseId = courseId;
      selectedModuleId = null;
      lessons.clear();
    });

    try {
      final loadedModules = await CourseService.getCourseModules(courseId);
      setState(() {
        modules = loadedModules;
        isLoadingModules = false;
      });
    } catch (e) {
      setState(() {
        isLoadingModules = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load modules: $e')),
        );
      }
    }
  }

  Future<void> _loadLessons(String moduleId) async {
    setState(() {
      isLoadingLessons = true;
      selectedModuleId = moduleId;
    });

    try {
      final moduleDetails = await CourseService.getModuleDetails(moduleId);
      if (moduleDetails != null && moduleDetails['lessons'] != null) {
        setState(() {
          lessons = List<Map<String, dynamic>>.from(moduleDetails['lessons']);
          isLoadingLessons = false;
        });
      } else {
        setState(() {
          lessons = [];
          isLoadingLessons = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingLessons = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load lessons: $e')),
        );
      }
    }
  }

  Future<void> _createModule() async {
    if (selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course first')),
      );
      return;
    }

    await _showCreateModuleDialog();
  }

  Future<void> _createLesson() async {
    if (selectedModuleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a module first')),
      );
      return;
    }

    await _showCreateLessonDialog();
  }

  Future<void> _showCreateModuleDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final orderIndexController = TextEditingController();
    
    // Calculate next order index
    final nextOrderIndex = modules.isNotEmpty 
        ? modules.map((m) => m['order_index'] as int).reduce((a, b) => a > b ? a : b) + 1
        : 1;
    orderIndexController.text = nextOrderIndex.toString();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Module'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  labelText: 'Order Index',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty &&
                  priceController.text.isNotEmpty &&
                  orderIndexController.text.isNotEmpty) {
                
                final result = await AdminService.createModule(
                  courseId: selectedCourseId!,
                  title: titleController.text,
                  description: descriptionController.text,
                  price: double.parse(priceController.text),
                  orderIndex: int.parse(orderIndexController.text),
                );
                
                if (mounted) {
                  Navigator.pop(context, result['success']);
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

    if (result == true && selectedCourseId != null) {
      _loadModules(selectedCourseId!);
    }
  }

  Future<void> _showCreateLessonDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final orderIndexController = TextEditingController();
    final durationController = TextEditingController();
    String selectedContentType = 'video';
    
    // Calculate next order index
    final nextOrderIndex = lessons.isNotEmpty 
        ? lessons.map((l) => l['order_index'] as int).reduce((a, b) => a > b ? a : b) + 1
        : 1;
    orderIndexController.text = nextOrderIndex.toString();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Lesson'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    labelText: 'Order Index',
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
                      setState(() {
                        selectedContentType = newValue;
                      });
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
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty &&
                    priceController.text.isNotEmpty &&
                    orderIndexController.text.isNotEmpty) {
                  
                  final result = await AdminService.createLesson(
                    moduleId: selectedModuleId!,
                    title: titleController.text,
                    description: descriptionController.text,
                    price: double.parse(priceController.text),
                    orderIndex: int.parse(orderIndexController.text),
                    contentType: selectedContentType,
                    durationMinutes: durationController.text.isNotEmpty ? int.parse(durationController.text) : null,
                  );
                  
                  if (mounted) {
                    Navigator.pop(context, result['success']);
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

    if (result == true && selectedModuleId != null) {
      _loadLessons(selectedModuleId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Modules & Lessons'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCourses,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Courses Panel
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.blue.withOpacity(0.1),
                          child: const Row(
                            children: [
                              Icon(Icons.school, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Courses',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: courses.length,
                            itemBuilder: (context, index) {
                              final course = courses[index];
                              final isSelected = selectedCourseId == course['id'];
                              
                              return ListTile(
                                title: Text(
                                  course['title'],
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  course['difficulty'],
                                  style: TextStyle(
                                    color: isSelected ? Colors.blue : Colors.grey[600],
                                  ),
                                ),
                                selected: isSelected,
                                selectedTileColor: Colors.blue.withOpacity(0.1),
                                onTap: () => _loadModules(course['id']),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Modules Panel
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.green.withOpacity(0.1),
                          child: Row(
                            children: [
                              const Icon(Icons.library_books, color: Colors.green),
                              const SizedBox(width: 8),
                              const Text(
                                'Modules',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              if (selectedCourseId != null)
                                IconButton(
                                  icon: const Icon(Icons.add, color: Colors.green),
                                  onPressed: _createModule,
                                  tooltip: 'Add Module',
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: isLoadingModules
                              ? const Center(child: CircularProgressIndicator())
                              : selectedCourseId == null
                                  ? const Center(
                                      child: Text(
                                        'Select a course to view modules',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : modules.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Text(
                                                'No modules found',
                                                style: TextStyle(color: Colors.grey),
                                              ),
                                              const SizedBox(height: 8),
                                              ElevatedButton.icon(
                                                onPressed: _createModule,
                                                icon: const Icon(Icons.add),
                                                label: const Text('Create Module'),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: modules.length,
                                          itemBuilder: (context, index) {
                                            final module = modules[index];
                                            final isSelected = selectedModuleId == module['id'];
                                            
                                            return ListTile(
                                              title: Text(
                                                module['title'],
                                                style: TextStyle(
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                              subtitle: Text(
                                                'Order: ${module['order_index']} • \$${module['price']}',
                                                style: TextStyle(
                                                  color: isSelected ? Colors.green : Colors.grey[600],
                                                ),
                                              ),
                                              selected: isSelected,
                                              selectedTileColor: Colors.green.withOpacity(0.1),
                                              onTap: () => _loadLessons(module['id']),
                                            );
                                          },
                                        ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Lessons Panel
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.orange.withOpacity(0.1),
                        child: Row(
                          children: [
                            const Icon(Icons.play_lesson, color: Colors.orange),
                            const SizedBox(width: 8),
                            const Text(
                              'Lessons',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            if (selectedModuleId != null)
                              IconButton(
                                icon: const Icon(Icons.add, color: Colors.orange),
                                onPressed: _createLesson,
                                tooltip: 'Add Lesson',
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: isLoadingLessons
                            ? const Center(child: CircularProgressIndicator())
                            : selectedModuleId == null
                                ? const Center(
                                    child: Text(
                                      'Select a module to view lessons',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : lessons.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              'No lessons found',
                                              style: TextStyle(color: Colors.grey),
                                            ),
                                            const SizedBox(height: 8),
                                            ElevatedButton.icon(
                                              onPressed: _createLesson,
                                              icon: const Icon(Icons.add),
                                              label: const Text('Create Lesson'),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: lessons.length,
                                        itemBuilder: (context, index) {
                                          final lesson = lessons[index];
                                          
                                          return Card(
                                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            child: ListTile(
                                              title: Text(lesson['title']),
                                              subtitle: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Order: ${lesson['order_index']} • \$${lesson['price']}'),
                                                  Text('Type: ${lesson['content_type']}'),
                                                  if (lesson['duration_minutes'] != null)
                                                    Text('Duration: ${lesson['duration_minutes']} min'),
                                                ],
                                              ),
                                              isThreeLine: true,
                                              trailing: const Icon(Icons.play_circle_outline),
                                            ),
                                          );
                                        },
                                      ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}