import 'package:flutter/material.dart';
import '../models/course_models.dart';

class FinalProjectScreen extends StatelessWidget {
  final FinalProject? finalProject;
  final Map<String, dynamic>? finalProjectData;

  const FinalProjectScreen({
    super.key,
    this.finalProject,
    this.finalProjectData,
  }) : assert(finalProject != null || finalProjectData != null, 'Either finalProject or finalProjectData must be provided');

  // Helper method to get data from either source
  dynamic _getFinalProjectData(String key) {
    if (finalProjectData != null) {
      return finalProjectData![key];
    } else if (finalProject != null) {
      switch (key) {
        case 'title': return finalProject!.title;
        case 'description': return finalProject!.description;
        case 'price': return finalProject!.price;
        case 'requirements': return finalProject!.requirements;
        case 'estimatedHours': return finalProject!.estimatedHours;
        case 'rubric': return finalProject!.rubric;
        default: return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Final Project'),
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
            _buildProjectHeader(context),
            _buildProjectDetails(context),
            _buildProjectRequirements(context),
            _buildProjectSubmission(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getFinalProjectData('title') ?? 'Final Project',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${_getFinalProjectData('price') ?? '0'}',
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
            _getFinalProjectData('description') ?? 'No description available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildDetailCard(
            context,
            'Duration',
            '2-3 weeks',
            Icons.schedule,
            Colors.blue,
          ),
          _buildDetailCard(
            context,
            'Difficulty',
            'Intermediate',
            Icons.trending_up,
            Colors.orange,
          ),
          _buildDetailCard(
            context,
            'Submission Format',
            'Code + Documentation',
            Icons.description,
            Colors.green,
          ),
          _buildDetailCard(
            context,
            'Evaluation',
            'Peer Review + Instructor',
            Icons.rate_review,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  Widget _buildProjectRequirements(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requirements',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildRequirementItem(
            context,
            'Complete all module lessons',
            true,
          ),
          _buildRequirementItem(
            context,
            'Submit project proposal',
            false,
          ),
          _buildRequirementItem(
            context,
            'Implement core functionality',
            false,
          ),
          _buildRequirementItem(
            context,
            'Write comprehensive documentation',
            false,
          ),
          _buildRequirementItem(
            context,
            'Present project to peers',
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(
    BuildContext context,
    String requirement,
    bool isCompleted,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isCompleted ? Colors.green : Colors.grey,
        ),
        title: Text(
          requirement,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? Colors.grey : null,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectSubmission(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Submission',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_upload, color: Colors.blue),
                      const SizedBox(width: 12),
                      Text(
                        'Upload Project Files',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Upload your project files, documentation, and any additional resources.',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Upload project files
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Choose Files'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Submit project
              },
              icon: const Icon(Icons.send),
              label: const Text('Submit Project'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}