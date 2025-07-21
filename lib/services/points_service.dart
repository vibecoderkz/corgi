import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/purchase_models.dart';

class PointsService {
  static final PointsService _instance = PointsService._internal();
  factory PointsService() => _instance;
  PointsService._internal();

  static SupabaseClient get _client => SupabaseService.client;

  // Get user's total points
  static Future<int> getUserTotalPoints() async {
    return await SupabaseService.requireAuth((userId) async {
      final response = await _client
          .from('users')
          .select('total_points')
          .eq('id', userId)
          .single();

      return response['total_points'] ?? 0;
    }) ?? 0;
  }

  // Get user's points summary with breakdown
  static Future<PointsSummary> getUserPointsSummary() async {
    return await SupabaseService.requireAuth((userId) async {
      // Get total points from user
      final userResponse = await _client
          .from('users')
          .select('total_points')
          .eq('id', userId)
          .single();

      final totalPoints = userResponse['total_points'] ?? 0;

      // Get points breakdown by transaction type
      final transactionsResponse = await _client
          .from('points_transactions')
          .select('transaction_type, points')
          .eq('user_id', userId);

      final breakdown = <String, int>{};
      for (final transaction in transactionsResponse) {
        final type = transaction['transaction_type'] as String;
        final points = transaction['points'] as int;
        breakdown[type] = (breakdown[type] ?? 0) + points;
      }

      // Get recent transactions
      final recentResponse = await _client
          .from('points_transactions')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(10);

      final recentTransactions = recentResponse
          .map((item) => PointsTransaction.fromJson(item))
          .toList();

      return PointsSummary(
        totalPoints: totalPoints,
        breakdown: breakdown,
        recentTransactions: recentTransactions,
      );
    }) ?? PointsSummary(
      totalPoints: 0,
      breakdown: {},
      recentTransactions: [],
    );
  }

  // Award points for homework completion
  static Future<Map<String, dynamic>> awardHomeworkPoints(
    String homeworkId,
    String lessonId,
  ) async {
    return await SupabaseService.requireAuth((userId) async {
      try {
      // Get homework details
      final homework = await _client
          .from('homework')
          .select('points_reward, title')
          .eq('id', homeworkId)
          .single();

      // Check if points already awarded
      final existingTransaction = await _client
          .from('points_transactions')
          .select('id')
          .eq('user_id', userId)
          .eq('reference_id', homeworkId)
          .eq('transaction_type', 'homework_completed')
          .maybeSingle();

      if (existingTransaction != null) {
        return {'success': false, 'message': 'Points already awarded for this homework'};
      }

      // Award points
      await _client
          .from('points_transactions')
          .insert({
            'user_id': userId,
            'points': homework['points_reward'],
            'transaction_type': 'homework_completed',
            'reference_id': homeworkId,
            'description': 'Completed homework: ${homework['title']}',
          });

      // Update user progress
      await _client
          .from('user_progress')
          .insert({
            'user_id': userId,
            'lesson_id': lessonId,
            'progress_type': 'homework_submitted',
            'progress_percentage': 100,
            'points_earned': homework['points_reward'],
            'completed_at': DateTime.now().toIso8601String(),
          });

      return {
        'success': true,
        'points_awarded': homework['points_reward'],
        'message': 'Homework completed! You earned ${homework['points_reward']} points.'
      };
      } catch (e) {
        return {'success': false, 'message': 'Failed to award points: $e'};
      }
    }) ?? {'success': false, 'message': 'User not authenticated'};
  }

  // Award points for final project completion
  static Future<Map<String, dynamic>> awardFinalProjectPoints(
    String userId,
    String finalProjectId,
    String? courseId,
    String? moduleId,
  ) async {
    try {
      // Get final project details
      final finalProject = await _client
          .from('final_projects')
          .select('points_reward, title')
          .eq('id', finalProjectId)
          .single();

      // Check if points already awarded
      final existingTransaction = await _client
          .from('points_transactions')
          .select('id')
          .eq('user_id', userId)
          .eq('reference_id', finalProjectId)
          .eq('transaction_type', 'final_project_completed')
          .maybeSingle();

      if (existingTransaction != null) {
        return {'success': false, 'message': 'Points already awarded for this final project'};
      }

      // Award points
      await _client
          .from('points_transactions')
          .insert({
            'user_id': userId,
            'points': finalProject['points_reward'],
            'transaction_type': 'final_project_completed',
            'reference_id': finalProjectId,
            'description': 'Completed final project: ${finalProject['title']}',
          });

      // Update user progress
      await _client
          .from('user_progress')
          .insert({
            'user_id': userId,
            'course_id': courseId,
            'module_id': moduleId,
            'progress_type': 'final_project_submitted',
            'progress_percentage': 100,
            'points_earned': finalProject['points_reward'],
            'completed_at': DateTime.now().toIso8601String(),
          });

      return {
        'success': true,
        'points_awarded': finalProject['points_reward'],
        'message': 'Final project completed! You earned ${finalProject['points_reward']} points.'
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to award points: $e'};
    }
  }

  // Award points for useful post
  static Future<Map<String, dynamic>> awardUsefulPostPoints(
    String userId,
    String postId,
    String voterId,
  ) async {
    try {
      // Check if voter already voted on this post
      final existingVote = await _client
          .from('post_votes')
          .select('id, is_useful')
          .eq('post_id', postId)
          .eq('user_id', voterId)
          .maybeSingle();

      if (existingVote != null) {
        if (existingVote['is_useful'] == true) {
          return {'success': false, 'message': 'You already marked this post as useful'};
        } else {
          // Update existing vote
          await _client
              .from('post_votes')
              .update({'is_useful': true})
              .eq('id', existingVote['id']);
        }
      } else {
        // Create new vote
        await _client
            .from('post_votes')
            .insert({
              'post_id': postId,
              'user_id': voterId,
              'is_useful': true,
            });
      }

      // The trigger will automatically award points to the post author
      return {
        'success': true,
        'message': 'Post marked as useful! The author earned 5 points.'
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to mark post as useful: $e'};
    }
  }

  // Remove useful post points
  static Future<Map<String, dynamic>> removeUsefulPostPoints(
    String userId,
    String postId,
    String voterId,
  ) async {
    try {
      // Update or remove vote
      await _client
          .from('post_votes')
          .update({'is_useful': false})
          .eq('post_id', postId)
          .eq('user_id', voterId);

      // The trigger will automatically deduct points from the post author
      return {
        'success': true,
        'message': 'Useful marking removed.'
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to remove useful marking: $e'};
    }
  }


  // Get leaderboard
  static Future<List<Map<String, dynamic>>> getLeaderboard({
    int limit = 100,
    String period = 'all_time',
  }) async {
    String query = '''
      id,
      full_name,
      avatar_url,
      total_points
    ''';

    // For different time periods, we might want to calculate points differently
    if (period == 'all_time') {
      return await _client
          .from('users')
          .select(query)
          .order('total_points', ascending: false)
          .limit(limit);
    } else {
      // For specific periods (today, this_week, this_month), calculate from transactions
      DateTime startDate;
      switch (period) {
        case 'today':
          startDate = DateTime.now().subtract(const Duration(days: 1));
          break;
        case 'this_week':
          startDate = DateTime.now().subtract(const Duration(days: 7));
          break;
        case 'this_month':
          startDate = DateTime.now().subtract(const Duration(days: 30));
          break;
        default:
          startDate = DateTime.now().subtract(const Duration(days: 365));
      }

      // Get points for the period
      final response = await _client
          .rpc('get_leaderboard_for_period', params: {
            'start_date': startDate.toIso8601String(),
            'limit_count': limit,
          });

      return List<Map<String, dynamic>>.from(response);
    }
  }

  // Check if user completed all lessons in a module
  static Future<bool> isModuleCompleted(String userId, String moduleId) async {
    // Get all lessons in the module
    final lessonsResponse = await _client
        .from('lessons')
        .select('id')
        .eq('module_id', moduleId)
        .eq('is_active', true);

    // Get completed lessons
    final completedLessons = await _client
        .from('user_progress')
        .select('lesson_id')
        .eq('user_id', userId)
        .eq('progress_type', 'lesson_completed')
        .inFilter('lesson_id', lessonsResponse.map((l) => l['id']).toList());

    return completedLessons.length == lessonsResponse.length;
  }

  // Check if user completed all modules in a course
  static Future<bool> isCourseCompleted(String userId, String courseId) async {
    // Get all modules in the course
    final modulesResponse = await _client
        .from('modules')
        .select('id')
        .eq('course_id', courseId)
        .eq('is_active', true);

    // Check if all modules are completed
    for (final module in modulesResponse) {
      final isCompleted = await isModuleCompleted(userId, module['id']);
      if (!isCompleted) return false;
    }

    return true;
  }

  // Award course completion points
  static Future<Map<String, dynamic>> awardCourseCompletionPoints(
    String userId,
    String courseId,
  ) async {
    try {
      // Check if course is actually completed
      final isCompleted = await isCourseCompleted(userId, courseId);
      if (!isCompleted) {
        return {'success': false, 'message': 'Course not yet completed'};
      }

      // Check if points already awarded
      final existingTransaction = await _client
          .from('points_transactions')
          .select('id')
          .eq('user_id', userId)
          .eq('reference_id', courseId)
          .eq('transaction_type', 'course_completed')
          .maybeSingle();

      if (existingTransaction != null) {
        return {'success': false, 'message': 'Course completion points already awarded'};
      }

      // Award bonus points for course completion (e.g., 100 points)
      const courseCompletionBonus = 100;
      
      await _client
          .from('points_transactions')
          .insert({
            'user_id': userId,
            'points': courseCompletionBonus,
            'transaction_type': 'course_completed',
            'reference_id': courseId,
            'description': 'Course completion bonus',
          });

      // Update user progress
      await _client
          .from('user_progress')
          .insert({
            'user_id': userId,
            'course_id': courseId,
            'progress_type': 'course_completed',
            'progress_percentage': 100,
            'points_earned': courseCompletionBonus,
            'completed_at': DateTime.now().toIso8601String(),
          });

      // Award achievement
      await _client
          .from('user_achievements')
          .insert({
            'user_id': userId,
            'achievement_type': 'course_completion',
            'achievement_name': 'Course Graduate',
            'description': 'Completed an entire course',
            'points_awarded': courseCompletionBonus,
          });

      return {
        'success': true,
        'points_awarded': courseCompletionBonus,
        'message': 'Congratulations! You completed the course and earned $courseCompletionBonus points!'
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to award course completion points: $e'};
    }
  }

  // Mark lesson as completed
  static Future<Map<String, dynamic>> markLessonCompleted(
    String userId,
    String lessonId,
  ) async {
    try {
      // Check if already completed
      final existingProgress = await _client
          .from('user_progress')
          .select('id')
          .eq('user_id', userId)
          .eq('lesson_id', lessonId)
          .eq('progress_type', 'lesson_completed')
          .maybeSingle();

      if (existingProgress != null) {
        return {'success': false, 'message': 'Lesson already completed'};
      }

      // Mark as completed
      await _client
          .from('user_progress')
          .insert({
            'user_id': userId,
            'lesson_id': lessonId,
            'progress_type': 'lesson_completed',
            'progress_percentage': 100,
            'completed_at': DateTime.now().toIso8601String(),
          });

      // Check if module is now completed
      final lessonInfo = await _client
          .from('lessons')
          .select('module_id')
          .eq('id', lessonId)
          .single();

      final moduleCompleted = await isModuleCompleted(userId, lessonInfo['module_id']);
      if (moduleCompleted) {
        // Award module completion points
        await _awardModuleCompletionPoints(userId, lessonInfo['module_id']);
      }

      // Check if course is now completed
      final moduleInfo = await _client
          .from('modules')
          .select('course_id')
          .eq('id', lessonInfo['module_id'])
          .single();

      final courseCompleted = await isCourseCompleted(userId, moduleInfo['course_id']);
      if (courseCompleted) {
        // Award course completion points
        await awardCourseCompletionPoints(userId, moduleInfo['course_id']);
      }

      return {
        'success': true,
        'message': 'Lesson completed!',
        'module_completed': moduleCompleted,
        'course_completed': courseCompleted,
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to mark lesson as completed: $e'};
    }
  }

  // Private method to award module completion points
  static Future<void> _awardModuleCompletionPoints(String userId, String moduleId) async {
    // Check if points already awarded
    final existingTransaction = await _client
        .from('points_transactions')
        .select('id')
        .eq('user_id', userId)
        .eq('reference_id', moduleId)
        .eq('transaction_type', 'module_completed')
        .maybeSingle();

    if (existingTransaction != null) return;

    // Award bonus points for module completion (e.g., 50 points)
    const moduleCompletionBonus = 50;
    
    await _client
        .from('points_transactions')
        .insert({
          'user_id': userId,
          'points': moduleCompletionBonus,
          'transaction_type': 'module_completed',
          'reference_id': moduleId,
          'description': 'Module completion bonus',
        });

    // Update user progress
    await _client
        .from('user_progress')
        .insert({
          'user_id': userId,
          'module_id': moduleId,
          'progress_type': 'module_completed',
          'progress_percentage': 100,
          'points_earned': moduleCompletionBonus,
          'completed_at': DateTime.now().toIso8601String(),
        });
  }
}