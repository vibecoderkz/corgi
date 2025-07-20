import 'package:flutter/material.dart';
import '../models/course_models.dart';

class LessonScreen extends StatelessWidget {
  final Lesson? lesson;
  final Map<String, dynamic>? lessonData;
  final int lessonNumber;

  const LessonScreen({
    super.key,
    this.lesson,
    this.lessonData,
    required this.lessonNumber,
  }) : assert(lesson != null || lessonData != null, 'Either lesson or lessonData must be provided');

  // Helper method to get data from either source
  dynamic _getLessonData(String key) {
    if (lessonData != null) {
      // Map database field names to expected keys
      switch (key) {
        case 'duration': return lessonData!['duration_minutes'];
        case 'contentType': return lessonData!['content_type'];
        case 'contentUrl': return lessonData!['content_url'];
        default: return lessonData![key];
      }
    } else if (lesson != null) {
      switch (key) {
        case 'title': return lesson!.title;
        case 'description': return lesson!.description;
        case 'price': return lesson!.price;
        case 'duration': return lesson!.durationMinutes;
        case 'contentType': return lesson!.contentType;
        case 'contentUrl': return lesson!.contentUrl;
        case 'homework': return lesson!.homework;
        default: return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final title = _getLessonData('title') ?? 'Lesson $lessonNumber';
    
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
                    lessonNumber.toString(),
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
                      _getLessonData('title') ?? 'Lesson $lessonNumber',
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
              onPressed: () {
                // TODO: Mark lesson as completed
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Completed'),
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
                  onPressed: () {
                    // TODO: Navigate to previous lesson
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to next lesson
                  },
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
}