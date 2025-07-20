import 'package:flutter/material.dart';
import 'course_details_screen.dart';
import 'search_screen.dart';
import '../services/course_service.dart';
import '../services/purchase_service.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final List<Course> courses = [
    Course(
      id: '1',
      title: 'Introduction to AI',
      description: 'Learn the fundamentals of artificial intelligence and how it\'s changing our world',
      progress: 0.3,
      modules: 10,
      completedModules: 3,
      difficulty: 'Beginner',
      estimatedTime: '4 weeks',
      imageUrl: 'assets/ai_intro.png',
      videoPreviewUrl: 'assets/ai_intro_preview.mp4',
      studentsEnrolled: 1245,
      studentProjects: 89,
      questionsAnswered: 156,
      price: 29.99,
      modulesList: [
        Module(
          id: '1-1',
          title: 'What is AI?',
          description: 'Understanding artificial intelligence basics and fundamental concepts',
          lessons: 5,
          price: 4.99,
          imageUrl: 'assets/module_1_1.png',
          videoPreviewUrl: 'assets/module_1_1_preview.mp4',
          studentsCompleted: 1156,
          lessonsList: [
            Lesson(
              id: '1-1-1',
              title: 'Introduction to AI',
              description: 'Basic concepts and terminology of artificial intelligence',
              price: 0.99,
              contentType: 'video',
              contentUrl: 'assets/lessons/1-1-1.mp4',
              durationMinutes: 15,
              homework: Homework(
                id: '1-1-1-hw',
                title: 'AI Concepts Quiz',
                description: 'Complete the quiz about basic AI concepts',
                pointsReward: 10,
                requirements: ['Watch the video', 'Complete 10 questions'],
                submissionFormat: 'online_quiz',
              ),
            ),
            Lesson(
              id: '1-1-2',
              title: 'Types of AI',
              description: 'Understanding different categories of AI systems',
              price: 0.99,
            ),
            Lesson(
              id: '1-1-3',
              title: 'AI vs Machine Learning',
              description: 'Distinguishing between AI and machine learning',
              price: 0.99,
            ),
            Lesson(
              id: '1-1-4',
              title: 'AI in Daily Life',
              description: 'Examples of AI applications in everyday scenarios',
              price: 0.99,
            ),
            Lesson(
              id: '1-1-5',
              title: 'Future of AI',
              description: 'Exploring the potential and challenges of AI development',
              price: 1.01,
            ),
          ],
          finalProject: FinalProject(
            id: '1-1-final',
            title: 'AI Identification Challenge',
            description: 'Create a presentation identifying AI systems in your environment',
            price: 2.99,
            pointsReward: 50,
            requirements: [
              'Complete all module lessons',
              'Identify 10 AI systems in daily life',
              'Create a 10-slide presentation',
              'Include real-world examples'
            ],
            submissionFormat: 'presentation',
          ),
        ),
        Module(
          id: '1-2',
          title: 'History of AI',
          description: 'Journey through AI development from early concepts to modern breakthroughs',
          lessons: 4,
          price: 3.99,
          imageUrl: 'assets/module_1_2.png',
          videoPreviewUrl: 'assets/module_1_2_preview.mp4',
          studentsCompleted: 1089,
          lessonsList: [
            Lesson(
              id: '1-2-1',
              title: 'Early AI Concepts',
              description: 'From ancient myths to early computing concepts',
              price: 0.99,
            ),
            Lesson(
              id: '1-2-2',
              title: 'The Birth of Modern AI',
              description: 'Key developments in the 1950s and 1960s',
              price: 0.99,
            ),
            Lesson(
              id: '1-2-3',
              title: 'AI Winter and Revival',
              description: 'Understanding the cycles of AI development',
              price: 1.01,
            ),
            Lesson(
              id: '1-2-4',
              title: 'Modern AI Breakthroughs',
              description: 'Recent advances in deep learning and neural networks',
              price: 1.00,
            ),
          ],
          finalProject: FinalProject(
            id: '1-2-final',
            title: 'AI Timeline Project',
            description: 'Create a comprehensive timeline of AI development milestones',
            price: 2.99,
          ),
        ),
        Module(
          id: '1-3',
          title: 'AI Applications',
          description: 'Real-world AI implementations across various industries and sectors',
          lessons: 6,
          price: 5.99,
          imageUrl: 'assets/module_1_3.png',
          videoPreviewUrl: 'assets/module_1_3_preview.mp4',
          studentsCompleted: 967,
          lessonsList: [
            Lesson(
              id: '1-3-1',
              title: 'AI in Healthcare',
              description: 'Medical diagnosis and treatment applications',
              price: 0.99,
            ),
            Lesson(
              id: '1-3-2',
              title: 'AI in Transportation',
              description: 'Autonomous vehicles and traffic management',
              price: 0.99,
            ),
            Lesson(
              id: '1-3-3',
              title: 'AI in Finance',
              description: 'Fraud detection and algorithmic trading',
              price: 1.01,
            ),
            Lesson(
              id: '1-3-4',
              title: 'AI in Education',
              description: 'Personalized learning and educational technology',
              price: 0.99,
            ),
            Lesson(
              id: '1-3-5',
              title: 'AI in Entertainment',
              description: 'Gaming, recommendation systems, and content creation',
              price: 1.01,
            ),
            Lesson(
              id: '1-3-6',
              title: 'AI Ethics and Society',
              description: 'Responsible AI development and societal implications',
              price: 1.00,
            ),
          ],
          finalProject: FinalProject(
            id: '1-3-final',
            title: 'AI Application Analysis',
            description: 'Research and present on AI implementation in a chosen industry',
            price: 3.99,
          ),
        ),
      ],
    ),
    Course(
      id: '2',
      title: 'Machine Learning Basics',
      description: 'Understand the core concepts of machine learning algorithms and techniques',
      progress: 0.0,
      modules: 12,
      completedModules: 0,
      difficulty: 'Intermediate',
      estimatedTime: '6 weeks',
      imageUrl: 'assets/ml_basics.png',
      videoPreviewUrl: 'assets/ml_basics_preview.mp4',
      studentsEnrolled: 892,
      studentProjects: 67,
      questionsAnswered: 234,
      price: 49.99,
      modulesList: [
        Module(
          id: '2-1',
          title: 'Supervised Learning',
          description: 'Learn supervised learning algorithms and their applications',
          lessons: 8,
          price: 9.99,
          imageUrl: 'assets/module_2_1.png',
          videoPreviewUrl: 'assets/module_2_1_preview.mp4',
          studentsCompleted: 745,
          lessonsList: [
            Lesson(id: '2-1-1', title: 'Linear Regression', description: 'Basic linear regression concepts', price: 1.25),
            Lesson(id: '2-1-2', title: 'Logistic Regression', description: 'Classification using logistic regression', price: 1.25),
            Lesson(id: '2-1-3', title: 'Decision Trees', description: 'Tree-based learning algorithms', price: 1.24),
            Lesson(id: '2-1-4', title: 'Random Forest', description: 'Ensemble methods with random forests', price: 1.25),
            Lesson(id: '2-1-5', title: 'Support Vector Machines', description: 'SVM for classification and regression', price: 1.25),
            Lesson(id: '2-1-6', title: 'Naive Bayes', description: 'Probabilistic classification methods', price: 1.25),
            Lesson(id: '2-1-7', title: 'K-Nearest Neighbors', description: 'Instance-based learning with KNN', price: 1.25),
            Lesson(id: '2-1-8', title: 'Feature Engineering', description: 'Preparing data for supervised learning', price: 1.25),
          ],
          finalProject: FinalProject(
            id: '2-1-final',
            title: 'Supervised Learning Project',
            description: 'Build a complete supervised learning pipeline',
            price: 4.99,
          ),
        ),
        Module(
          id: '2-2',
          title: 'Unsupervised Learning',
          description: 'Explore unsupervised learning techniques and clustering methods',
          lessons: 7,
          price: 8.99,
          imageUrl: 'assets/module_2_2.png',
          videoPreviewUrl: 'assets/module_2_2_preview.mp4',
          studentsCompleted: 623,
          lessonsList: [
            Lesson(id: '2-2-1', title: 'K-Means Clustering', description: 'Partitioning clustering with K-means', price: 1.28),
            Lesson(id: '2-2-2', title: 'Hierarchical Clustering', description: 'Agglomerative and divisive clustering', price: 1.28),
            Lesson(id: '2-2-3', title: 'DBSCAN', description: 'Density-based clustering methods', price: 1.29),
            Lesson(id: '2-2-4', title: 'Principal Component Analysis', description: 'Dimensionality reduction with PCA', price: 1.28),
            Lesson(id: '2-2-5', title: 'Association Rules', description: 'Market basket analysis and frequent patterns', price: 1.28),
            Lesson(id: '2-2-6', title: 'Anomaly Detection', description: 'Identifying outliers in data', price: 1.29),
            Lesson(id: '2-2-7', title: 'Gaussian Mixture Models', description: 'Probabilistic clustering methods', price: 1.29),
          ],
          finalProject: FinalProject(
            id: '2-2-final',
            title: 'Unsupervised Learning Analysis',
            description: 'Perform comprehensive clustering and dimensionality reduction',
            price: 3.99,
          ),
        ),
        Module(
          id: '2-3',
          title: 'Model Evaluation',
          description: 'Techniques for evaluating ML models and performance metrics',
          lessons: 5,
          price: 6.99,
          imageUrl: 'assets/module_2_3.png',
          videoPreviewUrl: 'assets/module_2_3_preview.mp4',
          studentsCompleted: 567,
          lessonsList: [
            Lesson(id: '2-3-1', title: 'Cross-Validation', description: 'K-fold and other validation techniques', price: 1.40),
            Lesson(id: '2-3-2', title: 'Performance Metrics', description: 'Accuracy, precision, recall, and F1-score', price: 1.40),
            Lesson(id: '2-3-3', title: 'ROC Curves', description: 'Receiver Operating Characteristic analysis', price: 1.39),
            Lesson(id: '2-3-4', title: 'Bias-Variance Tradeoff', description: 'Understanding model complexity', price: 1.40),
            Lesson(id: '2-3-5', title: 'Hyperparameter Tuning', description: 'Grid search and random search optimization', price: 1.40),
          ],
          finalProject: FinalProject(
            id: '2-3-final',
            title: 'Model Evaluation Project',
            description: 'Comprehensive evaluation of multiple ML models',
            price: 2.99,
          ),
        ),
      ],
    ),
    Course(
      id: '3',
      title: 'Deep Learning Fundamentals',
      description: 'Dive into neural networks and deep learning architectures',
      progress: 0.0,
      modules: 15,
      completedModules: 0,
      difficulty: 'Advanced',
      estimatedTime: '8 weeks',
      imageUrl: 'assets/dl_fundamentals.png',
      videoPreviewUrl: 'assets/dl_fundamentals_preview.mp4',
      studentsEnrolled: 567,
      studentProjects: 123,
      questionsAnswered: 345,
      price: 79.99,
      modulesList: [
        Module(
          id: '3-1',
          title: 'Neural Networks',
          description: 'Understanding neural network fundamentals and architectures',
          lessons: 10,
          price: 12.99,
          imageUrl: 'assets/module_3_1.png',
          videoPreviewUrl: 'assets/module_3_1_preview.mp4',
          studentsCompleted: 423,
          lessonsList: [
            Lesson(id: '3-1-1', title: 'Perceptron', description: 'Single-layer neural networks', price: 1.30),
            Lesson(id: '3-1-2', title: 'Multi-layer Networks', description: 'Deep neural network architectures', price: 1.30),
            Lesson(id: '3-1-3', title: 'Backpropagation', description: 'Training neural networks', price: 1.29),
            Lesson(id: '3-1-4', title: 'Activation Functions', description: 'ReLU, sigmoid, and other functions', price: 1.30),
            Lesson(id: '3-1-5', title: 'Loss Functions', description: 'Optimizing network performance', price: 1.30),
            Lesson(id: '3-1-6', title: 'Regularization', description: 'Preventing overfitting', price: 1.30),
            Lesson(id: '3-1-7', title: 'Optimization', description: 'Gradient descent and variants', price: 1.30),
            Lesson(id: '3-1-8', title: 'Batch Normalization', description: 'Stabilizing training', price: 1.30),
            Lesson(id: '3-1-9', title: 'Dropout', description: 'Regularization technique', price: 1.30),
            Lesson(id: '3-1-10', title: 'Network Architectures', description: 'Designing effective networks', price: 1.30),
          ],
          finalProject: FinalProject(
            id: '3-1-final',
            title: 'Neural Network from Scratch',
            description: 'Build and train a neural network from scratch',
            price: 5.99,
          ),
        ),
        Module(
          id: '3-2',
          title: 'CNNs & Computer Vision',
          description: 'Convolutional Neural Networks for image processing',
          lessons: 9,
          price: 11.99,
          imageUrl: 'assets/module_3_2.png',
          videoPreviewUrl: 'assets/module_3_2_preview.mp4',
          studentsCompleted: 356,
          lessonsList: [
            Lesson(id: '3-2-1', title: 'Convolution Operation', description: 'Understanding convolution layers', price: 1.33),
            Lesson(id: '3-2-2', title: 'Pooling Layers', description: 'Max pooling and average pooling', price: 1.33),
            Lesson(id: '3-2-3', title: 'CNN Architecture', description: 'Building convolutional networks', price: 1.33),
            Lesson(id: '3-2-4', title: 'Image Classification', description: 'Training CNNs for classification', price: 1.33),
            Lesson(id: '3-2-5', title: 'Transfer Learning', description: 'Using pre-trained models', price: 1.33),
            Lesson(id: '3-2-6', title: 'Object Detection', description: 'YOLO and R-CNN architectures', price: 1.34),
            Lesson(id: '3-2-7', title: 'Image Segmentation', description: 'Pixel-level classification', price: 1.33),
            Lesson(id: '3-2-8', title: 'Data Augmentation', description: 'Improving model performance', price: 1.33),
            Lesson(id: '3-2-9', title: 'Computer Vision Applications', description: 'Real-world CV projects', price: 1.34),
          ],
          finalProject: FinalProject(
            id: '3-2-final',
            title: 'Computer Vision Project',
            description: 'Build an image classification or object detection system',
            price: 6.99,
          ),
        ),
        Module(
          id: '3-3',
          title: 'RNNs & Sequence Models',
          description: 'Recurrent Neural Networks for sequential data',
          lessons: 8,
          price: 10.99,
          imageUrl: 'assets/module_3_3.png',
          videoPreviewUrl: 'assets/module_3_3_preview.mp4',
          studentsCompleted: 289,
          lessonsList: [
            Lesson(id: '3-3-1', title: 'Vanilla RNNs', description: 'Basic recurrent neural networks', price: 1.37),
            Lesson(id: '3-3-2', title: 'LSTM Networks', description: 'Long Short-Term Memory networks', price: 1.38),
            Lesson(id: '3-3-3', title: 'GRU Networks', description: 'Gated Recurrent Unit networks', price: 1.37),
            Lesson(id: '3-3-4', title: 'Sequence-to-Sequence', description: 'Encoder-decoder architectures', price: 1.38),
            Lesson(id: '3-3-5', title: 'Attention Mechanisms', description: 'Focusing on relevant information', price: 1.37),
            Lesson(id: '3-3-6', title: 'Language Modeling', description: 'Predicting next words', price: 1.38),
            Lesson(id: '3-3-7', title: 'Text Generation', description: 'Generating natural language', price: 1.37),
            Lesson(id: '3-3-8', title: 'Time Series Analysis', description: 'RNNs for temporal data', price: 1.37),
          ],
          finalProject: FinalProject(
            id: '3-3-final',
            title: 'Sequence Modeling Project',
            description: 'Build a text generation or time series prediction model',
            price: 4.99,
          ),
        ),
      ],
    ),
  ];

  String selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
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
          _buildFilterChips(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                return _buildCourseCard(courses[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'In Progress', 'Not Started', 'Completed'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.map((filter) {
            final isSelected = selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    selectedFilter = filter;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailsScreen(course: course),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.8),
                    Theme.of(context).primaryColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  _getCourseIcon(course.title),
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          course.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      _buildDifficultyChip(course.difficulty),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        course.estimatedTime,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.book, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${course.modules} modules',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${course.studentsEnrolled} students',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.question_answer, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${course.questionsAnswered} Q&A',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.work, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${course.studentProjects} projects',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Text(
                        '\$${course.price}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  if (course.progress > 0) ...[
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${(course.progress * 100).toInt()}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: course.progress,
                          backgroundColor: Colors.grey[300],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCourseIcon(String title) {
    if (title.contains('AI') || title.contains('Intelligence')) {
      return Icons.psychology;
    } else if (title.contains('Machine Learning')) {
      return Icons.memory;
    } else if (title.contains('Deep Learning')) {
      return Icons.hub;
    } else if (title.contains('Language')) {
      return Icons.translate;
    } else if (title.contains('Vision')) {
      return Icons.remove_red_eye;
    }
    return Icons.school;
  }

  Widget _buildDifficultyChip(String difficulty) {
    Color color;
    switch (difficulty) {
      case 'Beginner':
        color = Colors.green;
        break;
      case 'Intermediate':
        color = Colors.orange;
        break;
      case 'Advanced':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        difficulty,
        style: TextStyle(color: color, fontSize: 12),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.5)),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class Course {
  final String id;
  final String title;
  final String description;
  final double progress;
  final int modules;
  final int completedModules;
  final String difficulty;
  final String estimatedTime;
  final String imageUrl;
  final String? videoPreviewUrl;
  final int studentsEnrolled;
  final int studentProjects;
  final int questionsAnswered;
  final double price;
  final List<Module> modulesList;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.modules,
    required this.completedModules,
    required this.difficulty,
    required this.estimatedTime,
    required this.imageUrl,
    this.videoPreviewUrl,
    required this.studentsEnrolled,
    required this.studentProjects,
    required this.questionsAnswered,
    required this.price,
    required this.modulesList,
  });
}

class Module {
  final String id;
  final String title;
  final String description;
  final int lessons;
  final double price;
  final String? imageUrl;
  final String? videoPreviewUrl;
  final int studentsCompleted;
  final List<Lesson> lessonsList;
  final FinalProject? finalProject;

  Module({
    required this.id,
    required this.title,
    required this.description,
    required this.lessons,
    required this.price,
    this.imageUrl,
    this.videoPreviewUrl,
    required this.studentsCompleted,
    required this.lessonsList,
    this.finalProject,
  });
}

class Lesson {
  final String id;
  final String title;
  final String description;
  final double price;
  final String contentType;
  final String? contentUrl;
  final int? durationMinutes;
  final Homework? homework;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.contentType,
    this.contentUrl,
    this.durationMinutes,
    this.homework,
  });
}

class FinalProject {
  final String id;
  final String title;
  final String description;
  final double price;
  final int pointsReward;
  final List<String> requirements;
  final String submissionFormat;

  FinalProject({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.pointsReward,
    required this.requirements,
    required this.submissionFormat,
  });
}

class Homework {
  final String id;
  final String title;
  final String description;
  final int pointsReward;
  final List<String> requirements;
  final String submissionFormat;

  Homework({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsReward,
    required this.requirements,
    required this.submissionFormat,
  });
}