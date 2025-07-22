import 'package:flutter/material.dart';
import '../models/course_models.dart';
import '../screens/lesson_screen.dart';
import '../screens/final_project_screen.dart';
import '../services/purchase_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class ModuleScreen extends StatefulWidget {
  final Module? module;
  final Map<String, dynamic>? moduleData;

  const ModuleScreen({
    super.key,
    this.module,
    this.moduleData,
  }) : assert(module != null || moduleData != null, 'Either module or moduleData must be provided');

  @override
  State<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  bool hasAccess = false;
  bool isCheckingAccess = false;
  int userPoints = 0;

  @override
  void initState() {
    super.initState();
    _checkAccess();
    _loadUserPoints();
  }

  Future<void> _checkAccess() async {
    setState(() {
      isCheckingAccess = true;
    });

    try {
      String moduleId = _getModuleId();
      if (moduleId.isNotEmpty) {
        final access = await PurchaseService.hasAccessToModule(moduleId);
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

  String _getModuleId() {
    if (widget.moduleData != null) {
      if (widget.moduleData is Map<String, dynamic>) {
        return widget.moduleData!['id'] ?? '';
      } else if (widget.moduleData is List && (widget.moduleData as List).isNotEmpty) {
        final moduleList = widget.moduleData as List;
        if (moduleList.first is Map<String, dynamic>) {
          return (moduleList.first as Map<String, dynamic>)['id'] ?? '';
        }
      }
    } else if (widget.module != null) {
      return widget.module!.id;
    }
    return '';
  }

  Future<void> _purchaseModule() async {
    if (!AuthService().isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, войдите в систему для покупки')),
      );
      return;
    }

    final modulePrice = _getModuleData('price');
    if (modulePrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Цена модуля недоступна')),
      );
      return;
    }

    final price = double.tryParse(modulePrice.toString()) ?? 0.0;
    await _showPurchaseDialog(
      'модуль',
      _getModuleData('title') ?? 'Модуль',
      price,
    );
  }

  Future<void> _showPurchaseDialog(String type, String title, double price) async {
    
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
                _executePurchase(price);
              },
              child: const Text('Купить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executePurchase(double price) async {
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
      String moduleId = _getModuleId();
      final result = await PurchaseService.purchaseModule(
        moduleId,
        price,
        'points_demo',
      );

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
  dynamic _getModuleData(String key) {
    if (widget.moduleData != null) {
      // Debug: Print the type and content of moduleData
      print('ModuleScreen - moduleData type: ${widget.moduleData.runtimeType}');
      print('ModuleScreen - moduleData content: ${widget.moduleData}');
      
      // Handle case where moduleData might be a List instead of Map
      Map<String, dynamic>? actualModuleData;
      if (widget.moduleData is Map<String, dynamic>) {
        actualModuleData = widget.moduleData;
      } else if (widget.moduleData is List && (widget.moduleData as List).isNotEmpty) {
        print('Warning: moduleData is a List in ModuleScreen, taking first element');
        final moduleList = widget.moduleData as List;
        if (moduleList.first is Map<String, dynamic>) {
          actualModuleData = moduleList.first as Map<String, dynamic>;
        }
      }
      
      if (actualModuleData != null) {
        // Map database field names to expected keys
        switch (key) {
          case 'videoPreviewUrl': return actualModuleData['video_preview_url'];
          case 'imageUrl': return actualModuleData['image_url'];
          case 'finalProject': return actualModuleData['final_projects'];
          default: return actualModuleData[key];
        }
      }
    } else if (widget.module != null) {
      switch (key) {
        case 'title': return widget.module!.title;
        case 'description': return widget.module!.description;
        case 'price': return widget.module!.price;
        case 'lessons': return widget.module!.lessons;
        case 'studentsCompleted': return widget.module!.studentsCompleted;
        case 'videoPreviewUrl': return widget.module!.videoPreviewUrl;
        case 'lessonsList': return widget.module!.lessonsList;
        case 'finalProject': return widget.module!.finalProject;
        default: return null;
      }
    }
    return null;
  }

  int _getLessonsCount() {
    // Try to get lessons count from different sources
    if (widget.moduleData != null) {
      // Handle case where moduleData might be a List instead of Map
      Map<String, dynamic>? actualModuleData;
      if (widget.moduleData is Map<String, dynamic>) {
        actualModuleData = widget.moduleData;
      } else if (widget.moduleData is List && (widget.moduleData as List).isNotEmpty) {
        final moduleList = widget.moduleData as List;
        if (moduleList.first is Map<String, dynamic>) {
          actualModuleData = moduleList.first as Map<String, dynamic>;
        }
      }
      
      if (actualModuleData != null) {
        // If lessons is a list, return its length
        if (actualModuleData['lessons'] is List) {
          return (actualModuleData['lessons'] as List).length;
        }
        // If lessons is a number, return it
        return int.tryParse(actualModuleData['lessons']?.toString() ?? '0') ?? 0;
      }
    } else if (widget.module != null) {
      // If it's a number, return it
      return int.tryParse(widget.module!.lessons?.toString() ?? '0') ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final title = _getModuleData('title') ?? 'Module Details';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModuleHeader(context),
            _buildModuleStats(context),
            _buildPurchaseSection(context),
            _buildPreviewSection(context),
            _buildLessonsSection(context),
            _buildFinalProjectSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getModuleData('title') ?? 'Module Title',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            _getModuleData('description') ?? 'No description available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            context,
            'Students Completed',
            '${_getModuleData('studentsCompleted') ?? 0}',
            Icons.people,
            Colors.green,
          ),
          _buildStatItem(
            context,
            'Lessons',
            '${_getLessonsCount()}',
            Icons.book,
            Colors.blue,
          ),
          _buildStatItem(
            context,
            'Price',
            '\$${_getModuleData('price') ?? 0}',
            Icons.monetization_on,
            Colors.orange,
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPurchaseSection(BuildContext context) {
    if (isCheckingAccess) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (hasAccess) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'У вас есть доступ к этому модулю',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Вы можете просматривать все уроки',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
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
                        'Для доступа к модулю требуется покупка',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Купите модуль, чтобы получить доступ ко всем урокам',
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
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _purchaseModule,
                  icon: const Icon(Icons.shopping_cart),
                  label: Text(
                    'Купить модуль за \$${_getModuleData('price') ?? 0}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
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
          if (userPoints > 0) ...[
            const SizedBox(height: 8),
            Text(
              'У вас есть $userPoints баллов для скидки!',
              style: TextStyle(
                color: Colors.green[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_getModuleData('videoPreviewUrl') != null)
                  const Icon(
                    Icons.play_circle_outline,
                    size: 64,
                    color: Colors.grey,
                  )
                else
                  const Icon(
                    Icons.image,
                    size: 64,
                    color: Colors.grey,
                  ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getModuleData('videoPreviewUrl') != null ? 'Video Preview' : 'Image Preview',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lessons',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ..._buildLessonsList(context),
        ],
      ),
    );
  }

  List<Widget> _buildLessonsList(BuildContext context) {
    // Try to get lessons from different sources
    List<dynamic> lessons = [];
    
    // Check if it's from database (lessons field)
    if (_getModuleData('lessons') != null) {
      final lessonData = _getModuleData('lessons');
      if (lessonData is List) {
        lessons = lessonData;
      }
    }
    
    // Check if it's from Module object (lessonsList field)
    if (lessons.isEmpty && _getModuleData('lessonsList') != null) {
      final lessonData = _getModuleData('lessonsList');
      if (lessonData is List) {
        lessons = lessonData;
      }
    }
    
    if (lessons.isEmpty) {
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
                  'No lessons available',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This module doesn\'t have any lessons yet.',
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
    
    return lessons.asMap().entries.map((entry) {
      final index = entry.key;
      final lesson = entry.value;
      return _buildLessonCardFromData(context, lesson, index + 1);
    }).toList();
  }

  Widget _buildLessonCardFromData(BuildContext context, dynamic lessonData, int lessonNumber) {
    // Handle both Lesson objects and Map<String, dynamic> from database
    String title = '';
    String description = '';
    double price = 0.0;
    String lessonId = '';
    
    if (lessonData is Map<String, dynamic>) {
      title = lessonData['title'] ?? 'Lesson $lessonNumber';
      description = lessonData['description'] ?? 'No description available';
      price = double.tryParse(lessonData['price']?.toString() ?? '0') ?? 0.0;
      lessonId = lessonData['id'] ?? '';
    } else if (lessonData is Lesson) {
      // Handle Lesson object case
      title = lessonData.title;
      description = lessonData.description;
      price = lessonData.price;
      lessonId = lessonData.id;
    } else if (lessonData is List && lessonData.isNotEmpty) {
      // Handle case where lessonData is unexpectedly a List
      print('Warning: lessonData is a List, taking first element');
      if (lessonData.first is Map<String, dynamic>) {
        final actualLesson = lessonData.first as Map<String, dynamic>;
        title = actualLesson['title'] ?? 'Lesson $lessonNumber';
        description = actualLesson['description'] ?? 'No description available';
        price = double.tryParse(actualLesson['price']?.toString() ?? '0') ?? 0.0;
        lessonId = actualLesson['id'] ?? '';
      } else {
        title = 'Lesson $lessonNumber';
        description = 'Invalid lesson data';
      }
    } else {
      // Fallback for unexpected types
      print('Warning: lessonData is of unexpected type: ${lessonData.runtimeType}');
      title = 'Lesson $lessonNumber';
      description = 'No description available';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            lessonNumber.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(description),
        trailing: Text(
          '\$${price.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LessonScreen(
                lessonData: lessonData,
                lessonNumber: lessonNumber,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLessonCard(BuildContext context, Lesson lesson, int lessonNumber) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            lessonNumber.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          lesson.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(lesson.description),
        trailing: Text(
          '\$${lesson.price}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LessonScreen(
                lesson: lesson,
                lessonNumber: lessonNumber,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFinalProjectSection(BuildContext context) {
    final finalProjectData = _getModuleData('finalProject');
    if (finalProjectData == null) return const SizedBox.shrink();

    // Handle case where finalProject might be a List instead of Map
    Map<String, dynamic>? finalProject;
    if (finalProjectData is Map<String, dynamic>) {
      finalProject = finalProjectData;
    } else if (finalProjectData is List && finalProjectData.isNotEmpty) {
      print('Warning: finalProject is a List, taking first element');
      if (finalProjectData.first is Map<String, dynamic>) {
        finalProject = finalProjectData.first as Map<String, dynamic>;
      }
    }

    if (finalProject == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Final Project',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Theme.of(context).primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Theme.of(context).primaryColor,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          finalProject['title'] ?? 'Final Project',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                        ),
                      ),
                      Text(
                        '\$${finalProject['price'] ?? '0'}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    finalProject['description'] ?? 'No description available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FinalProjectScreen(
                              finalProjectData: finalProject,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Start Final Project'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}