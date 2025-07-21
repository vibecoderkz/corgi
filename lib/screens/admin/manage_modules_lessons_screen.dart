import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/course_service.dart';
import 'package:intl/intl.dart';

class ManageModulesLessonsScreen extends StatefulWidget {
  const ManageModulesLessonsScreen({super.key});

  @override
  State<ManageModulesLessonsScreen> createState() => _ManageModulesLessonsScreenState();
}

class _ManageModulesLessonsScreenState extends State<ManageModulesLessonsScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  List<Map<String, dynamic>> courses = [];
  List<Map<String, dynamic>> modules = [];
  List<Map<String, dynamic>> lessons = [];
  String? selectedCourseId;
  String? selectedModuleId;
  
  bool isLoading = true;
  bool isLoadingModules = false;
  bool isLoadingLessons = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCourses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        _showErrorSnackBar('Failed to load courses: $e');
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
      _tabController.animateTo(1);
    } catch (e) {
      setState(() {
        isLoadingModules = false;
      });
      if (mounted) {
        _showErrorSnackBar('Failed to load modules: $e');
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
        _tabController.animateTo(2);
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
        _showErrorSnackBar('Failed to load lessons: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredCourses() {
    if (searchQuery.isEmpty) return courses;
    return courses.where((course) {
      return course['title'].toLowerCase().contains(searchQuery.toLowerCase()) ||
             course['description'].toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> _getFilteredModules() {
    if (searchQuery.isEmpty) return modules;
    return modules.where((module) {
      return module['title'].toLowerCase().contains(searchQuery.toLowerCase()) ||
             module['description'].toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> _getFilteredLessons() {
    if (searchQuery.isEmpty) return lessons;
    return lessons.where((lesson) {
      return lesson['title'].toLowerCase().contains(searchQuery.toLowerCase()) ||
             (lesson['description']?.toLowerCase() ?? '').contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Управление контентом',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCourses,
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: _showStatistics,
            tooltip: 'Статистика',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.school),
              text: 'Курсы (${courses.length})',
            ),
            Tab(
              icon: const Icon(Icons.folder),
              text: 'Модули (${modules.length})',
            ),
            Tab(
              icon: const Icon(Icons.book),
              text: 'Уроки (${lessons.length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Поиск...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          
          // Breadcrumb Navigation
          if (selectedCourseId != null || selectedModuleId != null)
            _buildBreadcrumb(),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCoursesTab(),
                _buildModulesTab(),
                _buildLessonsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue[50],
      child: Row(
        children: [
          const Icon(Icons.navigation, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          if (selectedCourseId != null) ...[
            Text(
              courses.firstWhere((c) => c['id'] == selectedCourseId)['title'],
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (selectedModuleId != null) ...[
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              Text(
                modules.firstWhere((m) => m['id'] == selectedModuleId)['title'],
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              setState(() {
                selectedCourseId = null;
                selectedModuleId = null;
                modules.clear();
                lessons.clear();
              });
              _tabController.animateTo(0);
            },
            icon: const Icon(Icons.home, size: 16),
            label: const Text('Назад к курсам'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredCourses = _getFilteredCourses();

    return Column(
      children: [
        Expanded(
          child: filteredCourses.isEmpty
              ? _buildEmptyState(
                  'Нет курсов',
                  'Создайте первый курс для начала работы',
                  Icons.school_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredCourses.length,
                  itemBuilder: (context, index) {
                    final course = filteredCourses[index];
                    return _buildCourseCard(course);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildModulesTab() {
    if (selectedCourseId == null) {
      return _buildEmptyState(
        'Выберите курс',
        'Сначала выберите курс из первой вкладки',
        Icons.arrow_back,
      );
    }

    if (isLoadingModules) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredModules = _getFilteredModules();

    return Column(
      children: [
        // Add Module Button
        Container(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _createModule,
              icon: const Icon(Icons.add),
              label: const Text('Добавить модуль'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        
        Expanded(
          child: filteredModules.isEmpty
              ? _buildEmptyState(
                  'Нет модулей',
                  'Добавьте первый модуль в этот курс',
                  Icons.folder_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredModules.length,
                  itemBuilder: (context, index) {
                    final module = filteredModules[index];
                    return _buildModuleCard(module);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLessonsTab() {
    if (selectedModuleId == null) {
      return _buildEmptyState(
        'Выберите модуль',
        'Сначала выберите модуль из второй вкладки',
        Icons.arrow_back,
      );
    }

    if (isLoadingLessons) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredLessons = _getFilteredLessons();

    return Column(
      children: [
        // Add Lesson Button
        Container(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _createLesson,
              icon: const Icon(Icons.add),
              label: const Text('Добавить урок'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        
        Expanded(
          child: filteredLessons.isEmpty
              ? _buildEmptyState(
                  'Нет уроков',
                  'Добавьте первый урок в этот модуль',
                  Icons.book_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredLessons.length,
                  itemBuilder: (context, index) {
                    final lesson = filteredLessons[index];
                    return _buildLessonCard(lesson);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String description, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _loadModules(course['id']),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.school,
                  color: Colors.blue[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course['description'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusChip(course['difficulty'], Colors.purple),
                        const SizedBox(width: 8),
                        _buildStatusChip('₸${course['price']}', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(Map<String, dynamic> module) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _loadLessons(module['id']),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.folder,
                  color: Colors.green[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      module['description'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusChip('Порядок: ${module['order_index']}', Colors.blue),
                        const SizedBox(width: 8),
                        _buildStatusChip('₸${module['price']}', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleModuleAction(value, module),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Редактировать'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Удалить', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> lesson) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getLessonIcon(lesson['content_type']),
                color: Colors.orange[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (lesson['description'] != null)
                    Text(
                      lesson['description'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildStatusChip('Порядок: ${lesson['order_index']}', Colors.blue),
                      _buildStatusChip('${lesson['duration_minutes']} мин', Colors.indigo),
                      _buildStatusChip('₸${lesson['price']}', Colors.green),
                      _buildStatusChip(
                        lesson['content_type'],
                        _getContentTypeColor(lesson['content_type']),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleLessonAction(value, lesson),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Редактировать'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Удалить', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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

  IconData _getLessonIcon(String? contentType) {
    switch (contentType) {
      case 'video':
        return Icons.play_circle_outline;
      case 'text':
        return Icons.article_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      case 'interactive':
        return Icons.touch_app_outlined;
      default:
        return Icons.book_outlined;
    }
  }

  Color _getContentTypeColor(String? contentType) {
    switch (contentType) {
      case 'video':
        return Colors.red;
      case 'text':
        return Colors.blue;
      case 'quiz':
        return Colors.purple;
      case 'interactive':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _handleModuleAction(String action, Map<String, dynamic> module) {
    switch (action) {
      case 'edit':
        _editModule(module);
        break;
      case 'delete':
        _deleteModule(module);
        break;
    }
  }

  void _handleLessonAction(String action, Map<String, dynamic> lesson) {
    switch (action) {
      case 'edit':
        _editLesson(lesson);
        break;
      case 'delete':
        _deleteLesson(lesson);
        break;
    }
  }

  Future<void> _createModule() async {
    if (selectedCourseId == null) {
      _showErrorSnackBar('Please select a course first');
      return;
    }

    final result = await _showModuleDialog();
    if (result == true && selectedCourseId != null) {
      _loadModules(selectedCourseId!);
    }
  }

  Future<void> _createLesson() async {
    if (selectedModuleId == null) {
      _showErrorSnackBar('Please select a module first');
      return;
    }

    final result = await _showLessonDialog();
    if (result == true && selectedModuleId != null) {
      _loadLessons(selectedModuleId!);
    }
  }

  Future<void> _editModule(Map<String, dynamic> module) async {
    final result = await _showModuleDialog(module: module);
    if (result == true && selectedCourseId != null) {
      _loadModules(selectedCourseId!);
    }
  }

  Future<void> _editLesson(Map<String, dynamic> lesson) async {
    final result = await _showLessonDialog(lesson: lesson);
    if (result == true && selectedModuleId != null) {
      _loadLessons(selectedModuleId!);
    }
  }

  Future<void> _deleteModule(Map<String, dynamic> module) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердить удаление'),
        content: Text('Вы уверены, что хотите удалить модуль "${module['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.deleteModule(module['id']);
        _showSuccessSnackBar('Модуль удален');
        if (selectedCourseId != null) {
          _loadModules(selectedCourseId!);
        }
      } catch (e) {
        _showErrorSnackBar('Ошибка удаления модуля: $e');
      }
    }
  }

  Future<void> _deleteLesson(Map<String, dynamic> lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердить удаление'),
        content: Text('Вы уверены, что хотите удалить урок "${lesson['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.deleteLesson(lesson['id']);
        _showSuccessSnackBar('Урок удален');
        if (selectedModuleId != null) {
          _loadLessons(selectedModuleId!);
        }
      } catch (e) {
        _showErrorSnackBar('Ошибка удаления урока: $e');
      }
    }
  }

  Future<bool?> _showModuleDialog({Map<String, dynamic>? module}) async {
    final titleController = TextEditingController(text: module?['title'] ?? '');
    final descriptionController = TextEditingController(text: module?['description'] ?? '');
    final priceController = TextEditingController(text: module?['price']?.toString() ?? '');
    final orderIndexController = TextEditingController();
    
    // Calculate next order index for new modules
    if (module == null) {
      final nextOrderIndex = modules.isNotEmpty 
          ? modules.map((m) => m['order_index'] as int).reduce((a, b) => a > b ? a : b) + 1
          : 1;
      orderIndexController.text = nextOrderIndex.toString();
    } else {
      orderIndexController.text = module['order_index'].toString();
    }
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(module == null ? 'Создать модуль' : 'Редактировать модуль'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Название модуля',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Цена',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: orderIndexController,
                decoration: const InputDecoration(
                  labelText: 'Порядок',
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
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty &&
                  priceController.text.isNotEmpty &&
                  orderIndexController.text.isNotEmpty) {
                
                try {
                  if (module == null) {
                    // Create new module
                    final result = await AdminService.createModule(
                      courseId: selectedCourseId!,
                      title: titleController.text,
                      description: descriptionController.text,
                      price: double.parse(priceController.text),
                      orderIndex: int.parse(orderIndexController.text),
                    );
                    
                    if (mounted) {
                      Navigator.pop(context, result['success']);
                      if (result['success']) {
                        _showSuccessSnackBar('Модуль создан');
                      } else {
                        _showErrorSnackBar(result['message'] ?? 'Ошибка создания модуля');
                      }
                    }
                  } else {
                    // Update existing module
                    final result = await AdminService.updateModule(
                      moduleId: module['id'],
                      title: titleController.text,
                      description: descriptionController.text,
                      price: double.parse(priceController.text),
                      orderIndex: int.parse(orderIndexController.text),
                    );
                    
                    if (mounted) {
                      Navigator.pop(context, result['success']);
                      if (result['success']) {
                        _showSuccessSnackBar('Модуль обновлен');
                      } else {
                        _showErrorSnackBar(result['message'] ?? 'Ошибка обновления модуля');
                      }
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context, false);
                    _showErrorSnackBar('Ошибка: $e');
                  }
                }
              }
            },
            child: Text(module == null ? 'Создать' : 'Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showLessonDialog({Map<String, dynamic>? lesson}) async {
    final titleController = TextEditingController(text: lesson?['title'] ?? '');
    final descriptionController = TextEditingController(text: lesson?['description'] ?? '');
    final priceController = TextEditingController(text: lesson?['price']?.toString() ?? '');
    final orderIndexController = TextEditingController();
    final durationController = TextEditingController(text: lesson?['duration_minutes']?.toString() ?? '');
    String selectedContentType = lesson?['content_type'] ?? 'video';
    
    // Calculate next order index for new lessons
    if (lesson == null) {
      final nextOrderIndex = lessons.isNotEmpty 
          ? lessons.map((l) => l['order_index'] as int).reduce((a, b) => a > b ? a : b) + 1
          : 1;
      orderIndexController.text = nextOrderIndex.toString();
    } else {
      orderIndexController.text = lesson['order_index'].toString();
    }
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(lesson == null ? 'Создать урок' : 'Редактировать урок'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название урока',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Цена',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        decoration: const InputDecoration(
                          labelText: 'Длительность (мин)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: orderIndexController,
                        decoration: const InputDecoration(
                          labelText: 'Порядок',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedContentType,
                        decoration: const InputDecoration(
                          labelText: 'Тип контента',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'video', child: Text('Видео')),
                          DropdownMenuItem(value: 'text', child: Text('Текст')),
                          DropdownMenuItem(value: 'quiz', child: Text('Квиз')),
                          DropdownMenuItem(value: 'interactive', child: Text('Интерактив')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedContentType = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    priceController.text.isNotEmpty &&
                    orderIndexController.text.isNotEmpty &&
                    durationController.text.isNotEmpty) {
                  
                  try {
                    if (lesson == null) {
                      // Create new lesson
                      final result = await AdminService.createLesson(
                        moduleId: selectedModuleId!,
                        title: titleController.text,
                        description: descriptionController.text,
                        price: double.parse(priceController.text),
                        orderIndex: int.parse(orderIndexController.text),
                        durationMinutes: int.parse(durationController.text),
                        contentType: selectedContentType,
                      );
                      
                      if (mounted) {
                        Navigator.pop(context, result['success']);
                        if (result['success']) {
                          _showSuccessSnackBar('Урок создан');
                        } else {
                          _showErrorSnackBar(result['message'] ?? 'Ошибка создания урока');
                        }
                      }
                    } else {
                      // Update existing lesson
                      final result = await AdminService.updateLesson(
                        lessonId: lesson['id'],
                        title: titleController.text,
                        description: descriptionController.text,
                        price: double.parse(priceController.text),
                        orderIndex: int.parse(orderIndexController.text),
                        durationMinutes: int.parse(durationController.text),
                        contentType: selectedContentType,
                      );
                      
                      if (mounted) {
                        Navigator.pop(context, result['success']);
                        if (result['success']) {
                          _showSuccessSnackBar('Урок обновлен');
                        } else {
                          _showErrorSnackBar(result['message'] ?? 'Ошибка обновления урока');
                        }
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context, false);
                      _showErrorSnackBar('Ошибка: $e');
                    }
                  }
                }
              },
              child: Text(lesson == null ? 'Создать' : 'Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Статистика контента'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Всего курсов:', courses.length.toString()),
            _buildStatRow('Всего модулей:', modules.length.toString()),
            _buildStatRow('Всего уроков:', lessons.length.toString()),
            if (selectedCourseId != null)
              _buildStatRow('Модулей в курсе:', modules.length.toString()),
            if (selectedModuleId != null)
              _buildStatRow('Уроков в модуле:', lessons.length.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}