import 'package:flutter/material.dart';
import '../models/course_models.dart';
import '../services/course_service.dart';

class LessonScreen extends StatefulWidget {
  final Lesson? lesson;
  final Map<String, dynamic>? lessonData;
  final int lessonNumber;
  final String? moduleId;
  final List<Map<String, dynamic>>? allLessons;

  const LessonScreen({
    super.key,
    this.lesson,
    this.lessonData,
    required this.lessonNumber,
    this.moduleId,
    this.allLessons,
  }) : assert(lesson != null || lessonData != null, 'Either lesson or lessonData must be provided');

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  bool _isCompleted = false;
  bool _isLoading = false;

  // Helper method to get data from either source
  dynamic _getLessonData(String key) {
    if (widget.lessonData != null) {
      // Map database field names to expected keys
      switch (key) {
        case 'duration': return widget.lessonData!['duration_minutes'];
        case 'contentType': return widget.lessonData!['content_type'];
        case 'contentUrl': return widget.lessonData!['content_url'];
        case 'id': return widget.lessonData!['id'];
        default: return widget.lessonData![key];
      }
    } else if (widget.lesson != null) {
      switch (key) {
        case 'title': return widget.lesson!.title;
        case 'description': return widget.lesson!.description;
        case 'price': return widget.lesson!.price;
        case 'duration': return widget.lesson!.durationMinutes;
        case 'contentType': return widget.lesson!.contentType;
        case 'contentUrl': return widget.lesson!.contentUrl;
        case 'homework': return widget.lesson!.homework;
        case 'id': return widget.lesson!.id;
        default: return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final title = _getLessonData('title') ?? 'Lesson ${widget.lessonNumber}';
    
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLessonHeader(context),
            _buildLessonContent(context),
            _buildLessonActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonHeader(BuildContext context) {
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.lessonNumber.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getLessonData('title') ?? 'Lesson ${widget.lessonNumber}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${_getLessonData('price') ?? 0}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getLessonData('description') ?? 'No description available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lesson Content',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Video Content',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Lesson Description',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _getLessonData('description') ?? 'No description available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
          const SizedBox(height: 24),
          _buildLessonResources(context),
        ],
      ),
    );
  }

  Widget _buildLessonResources(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resources',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('Lesson Notes'),
            subtitle: const Text('PDF - 2.5 MB'),
            trailing: const Icon(Icons.download),
            onTap: () {
              // TODO: Download lesson notes
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.code, color: Colors.blue),
            title: const Text('Code Examples'),
            subtitle: const Text('ZIP - 1.2 MB'),
            trailing: const Icon(Icons.download),
            onTap: () {
              // TODO: Download code examples
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.quiz, color: Colors.green),
            title: const Text('Practice Quiz'),
            subtitle: const Text('10 questions'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              // TODO: Navigate to quiz
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLessonActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _markAsCompleted,
              icon: const Icon(Icons.check_circle),
              label: Text(_isCompleted ? 'Completed' : (_isLoading ? 'Loading...' : 'Mark as Completed')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _hasPreviousLesson() ? _navigateToPreviousLesson : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _hasNextLesson() ? _navigateToNextLesson : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _markAsCompleted() async {
    final lessonId = _getLessonData('id');
    if (lessonId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await CourseService.markLessonCompleted(lessonId);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isCompleted = success;
        });
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lesson marked as completed!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _hasPreviousLesson() {
    return widget.lessonNumber > 1;
  }

  bool _hasNextLesson() {
    if (widget.allLessons == null) return false;
    return widget.lessonNumber < widget.allLessons!.length;
  }

  void _navigateToPreviousLesson() {
    if (!_hasPreviousLesson() || widget.allLessons == null) return;
    
    final previousLessonData = widget.allLessons![widget.lessonNumber - 2];
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LessonScreen(
          lessonData: previousLessonData,
          lessonNumber: widget.lessonNumber - 1,
          moduleId: widget.moduleId,
          allLessons: widget.allLessons,
        ),
      ),
    );
  }

  void _navigateToNextLesson() {
    if (!_hasNextLesson() || widget.allLessons == null) return;
    
    final nextLessonData = widget.allLessons![widget.lessonNumber];
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LessonScreen(
          lessonData: nextLessonData,
          lessonNumber: widget.lessonNumber + 1,
          moduleId: widget.moduleId,
          allLessons: widget.allLessons,
        ),
      ),
    );
  }
}