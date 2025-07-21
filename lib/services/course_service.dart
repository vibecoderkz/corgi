import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class CourseService {
  static final CourseService _instance = CourseService._internal();
  factory CourseService() => _instance;
  CourseService._internal();

  static SupabaseClient get _client => SupabaseService.client;

  // Get all courses with basic info
  static Future<List<Map<String, dynamic>>> getAllCourses() async {
    return await SupabaseService.safeExecute(() async {
      final response = await _client
          .from('courses')
          .select('''
            id, title, description, price, difficulty, estimated_time,
            image_url, video_preview_url, is_active, created_at, updated_at
          ''')
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    }) ?? [];
  }

  // Get course with full details including modules and lessons
  static Future<Map<String, dynamic>?> getCourseDetails(String courseId) async {
    return await SupabaseService.safeExecute(() async {
      final response = await _client
          .from('courses')
          .select('''
            id, title, description, price, difficulty, estimated_time,
            image_url, video_preview_url, is_active, created_at, updated_at,
            modules!modules_course_id_fkey (
              id, title, description, price, order_index, image_url, video_preview_url, is_active,
              lessons (
                id, title, description, price, order_index, content_type, 
                content_url, duration_minutes, is_active,
                homework (
                  id, title, description, points_reward, requirements, submission_format
                )
              ),
              final_projects (
                id, title, description, price, points_reward, requirements, submission_format
              )
            ),
            final_projects!final_projects_course_id_fkey (
              id, title, description, price, points_reward, requirements, submission_format
            )
          ''')
          .eq('id', courseId)
          .eq('is_active', true)
          .single();
      
      return response;
    });
  }

  // Get course statistics (students enrolled, projects, Q&A)
  static Future<Map<String, dynamic>> getCourseStats(String courseId) async {
    return await SupabaseService.safeExecute(() async {
      // Get students enrolled count
      final studentsResponse = await _client
          .from('purchases')
          .select('id')
          .eq('course_id', courseId)
          .eq('payment_status', 'completed');

      // Get student projects count (final projects completed)
      final projectsResponse = await _client
          .from('user_progress')
          .select('id')
          .eq('course_id', courseId)
          .eq('progress_type', 'final_project_submitted');

      // Get Q&A count (discussion posts in course groups)
      final discussionGroups = await _client
          .from('discussion_groups')
          .select('id')
          .eq('course_id', courseId);

      int questionsCount = 0;
      if (discussionGroups.isNotEmpty) {
        final groupIds = discussionGroups.map((g) => g['id']).toList();
        final questionsResponse = await _client
            .from('discussion_posts')
            .select('id')
            .inFilter('discussion_group_id', groupIds);
        questionsCount = questionsResponse.length;
      }

      return {
        'students_enrolled': studentsResponse.length,
        'student_projects': projectsResponse.length,
        'questions_answered': questionsCount,
      };
    }) ?? {
      'students_enrolled': 0,
      'student_projects': 0,
      'questions_answered': 0,
    };
  }

  // Get user's course progress
  static Future<Map<String, dynamic>> getUserCourseProgress(String courseId) async {
    return await SupabaseService.requireAuth((userId) async {
      // Check if user has access to course
      final hasAccess = await _client
          .rpc('user_has_course_access', params: {
            'user_uuid': userId,
            'course_uuid': courseId,
          });

      if (!hasAccess) {
        return {
          'has_access': false,
          'progress': 0.0,
          'completed_modules': 0,
          'total_modules': 0,
        };
      }

      // Get total modules count
      final modulesResponse = await _client
          .from('modules')
          .select('id')
          .eq('course_id', courseId)
          .eq('is_active', true);
      
      final totalModules = modulesResponse.length;

      // Get completed modules count
      final completedModulesResponse = await _client
          .from('user_progress')
          .select('module_id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .eq('progress_type', 'module_completed');

      final completedModules = completedModulesResponse.length;
      final progress = totalModules > 0 ? completedModules / totalModules : 0.0;

      return {
        'has_access': true,
        'progress': progress,
        'completed_modules': completedModules,
        'total_modules': totalModules,
      };
    }) ?? {
      'has_access': false,
      'progress': 0.0,
      'completed_modules': 0,
      'total_modules': 0,
    };
  }

  // Get modules for a specific course
  static Future<List<Map<String, dynamic>>> getCourseModules(String courseId) async {
    return await SupabaseService.safeExecute(() async {
      final response = await _client
          .from('modules')
          .select('''
            id, course_id, title, description, price, order_index, 
            image_url, video_preview_url, is_active, created_at, updated_at
          ''')
          .eq('course_id', courseId)
          .eq('is_active', true)
          .order('order_index', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    }) ?? [];
  }

  // Get module details
  static Future<Map<String, dynamic>?> getModuleDetails(String moduleId) async {
    return await SupabaseService.safeExecute(() async {
      final response = await _client
          .from('modules')
          .select('''
            id, course_id, title, description, price, order_index, 
            image_url, video_preview_url, is_active, created_at, updated_at,
            courses (
              id, title, price
            ),
            lessons (
              id, title, description, price, order_index, content_type, 
              content_url, duration_minutes, is_active,
              homework (
                id, title, description, points_reward, requirements, submission_format
              )
            ),
            final_projects (
              id, title, description, price, points_reward, requirements, submission_format
            )
          ''')
          .eq('id', moduleId)
          .eq('is_active', true)
          .single();
      
      return response;
    });
  }

  // Get module statistics
  static Future<Map<String, dynamic>> getModuleStats(String moduleId) async {
    return await SupabaseService.safeExecute(() async {
      // Get students completed count
      final completedResponse = await _client
          .from('user_progress')
          .select('id')
          .eq('module_id', moduleId)
          .eq('progress_type', 'module_completed');

      return {
        'students_completed': completedResponse.length,
      };
    }) ?? {
      'students_completed': 0,
    };
  }

  // Get lesson details
  static Future<Map<String, dynamic>?> getLessonDetails(String lessonId) async {
    return await SupabaseService.safeExecute(() async {
      final response = await _client
          .from('lessons')
          .select('''
            id, module_id, title, description, price, order_index, 
            content_type, content_url, duration_minutes, is_active,
            modules (
              id, title, price, course_id,
              courses (
                id, title, price
              )
            ),
            homework (
              id, title, description, points_reward, requirements, submission_format
            )
          ''')
          .eq('id', lessonId)
          .eq('is_active', true)
          .single();
      
      return response;
    });
  }

  // Check user access to content
  static Future<bool> hasAccessToCourse(String courseId) async {
    return await SupabaseService.requireAuth((userId) async {
      final result = await _client
          .rpc('user_has_course_access', params: {
            'user_uuid': userId,
            'course_uuid': courseId,
          });
      return result ?? false;
    }) ?? false;
  }

  static Future<bool> hasAccessToModule(String moduleId) async {
    return await SupabaseService.requireAuth((userId) async {
      final result = await _client
          .rpc('user_has_module_access', params: {
            'user_uuid': userId,
            'module_uuid': moduleId,
          });
      return result ?? false;
    }) ?? false;
  }

  static Future<bool> hasAccessToLesson(String lessonId) async {
    return await SupabaseService.requireAuth((userId) async {
      final result = await _client
          .rpc('user_has_lesson_access', params: {
            'user_uuid': userId,
            'lesson_uuid': lessonId,
          });
      return result ?? false;
    }) ?? false;
  }

  // Check if lesson is completed
  static Future<bool> isLessonCompleted(String lessonId) async {
    return await SupabaseService.requireAuth((userId) async {
      final result = await _client
          .from('user_progress')
          .select('id')
          .eq('user_id', userId)
          .eq('lesson_id', lessonId)
          .eq('progress_type', 'lesson_completed')
          .maybeSingle();

      return result != null;
    }) ?? false;
  }

  // Mark lesson as completed
  static Future<bool> markLessonCompleted(String lessonId) async {
    return await SupabaseService.requireAuth((userId) async {
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
          return true; // Already completed
        }

        // Get lesson and module info
        final lesson = await getLessonDetails(lessonId);
        if (lesson == null) return false;

        final moduleId = lesson['module_id'];
        final courseId = lesson['modules']['course_id'];

        // Award points for lesson completion
        final pointsResult = await _client.rpc('award_activity_points', params: {
          'p_user_id': userId,
          'p_activity_type': 'lesson_completed',
          'p_reference_id': lessonId,
          'p_description': 'Lesson completed: ${lesson['title'] ?? 'Unknown'}',
        });

        final pointsEarned = pointsResult ?? 0;

        // Insert progress record
        await _client.from('user_progress').insert({
          'user_id': userId,
          'lesson_id': lessonId,
          'module_id': moduleId,
          'course_id': courseId,
          'progress_type': 'lesson_completed',
          'progress_percentage': 100.0,
          'points_earned': pointsEarned,
          'completed_at': DateTime.now().toIso8601String(),
        });

        // Check if module is now completed
        final isModuleComplete = await _isModuleCompleted(userId, moduleId);
        if (isModuleComplete) {
          // Award module completion points
          await _client.rpc('award_activity_points', params: {
            'p_user_id': userId,
            'p_activity_type': 'module_completed',
            'p_reference_id': moduleId,
            'p_description': 'Module completed: ${lesson['modules']['title'] ?? 'Unknown'}',
          });

          // Check if course is now completed
          final isCourseComplete = await _isCourseCompleted(userId, courseId);
          if (isCourseComplete) {
            // Award course completion points
            await _client.rpc('award_activity_points', params: {
              'p_user_id': userId,
              'p_activity_type': 'course_completed',
              'p_reference_id': courseId,
              'p_description': 'Course completed: ${lesson['modules']['courses']['title'] ?? 'Unknown'}',
            });
          }
        }

        return true;
      } catch (e) {
        print('Error marking lesson completed: $e');
        return false;
      }
    }) ?? false;
  }

  // Helper method to check if module is completed
  static Future<bool> _isModuleCompleted(String userId, String moduleId) async {
    // Get all lessons in the module
    final lessonsResponse = await _client
        .from('lessons')
        .select('id')
        .eq('module_id', moduleId)
        .eq('is_active', true);

    if (lessonsResponse.isEmpty) return false;

    // Get completed lessons
    final completedLessons = await _client
        .from('user_progress')
        .select('lesson_id')
        .eq('user_id', userId)
        .eq('progress_type', 'lesson_completed')
        .inFilter('lesson_id', lessonsResponse.map((l) => l['id']).toList());

    return completedLessons.length == lessonsResponse.length;
  }

  // Helper method to check if course is completed
  static Future<bool> _isCourseCompleted(String userId, String courseId) async {
    // Get all modules in the course
    final modulesResponse = await _client
        .from('modules')
        .select('id')
        .eq('course_id', courseId)
        .eq('is_active', true);

    if (modulesResponse.isEmpty) return false;

    // Check if all modules are completed
    for (final module in modulesResponse) {
      final isCompleted = await _isModuleCompleted(userId, module['id']);
      if (!isCompleted) return false;
    }

    return true;
  }

  // Submit homework
  static Future<bool> submitHomework(String homeworkId, String lessonId) async {
    return await SupabaseService.requireAuth((userId) async {
      // Get lesson info
      final lesson = await getLessonDetails(lessonId);
      if (lesson == null) return false;

      final moduleId = lesson['module_id'];
      final courseId = lesson['modules']['course_id'];
      
      // Get homework points
      final homework = lesson['homework'];
      final points = homework?['points_reward'] ?? 0;

      // Insert progress record
      await _client.from('user_progress').insert({
        'user_id': userId,
        'lesson_id': lessonId,
        'module_id': moduleId,
        'course_id': courseId,
        'progress_type': 'homework_submitted',
        'progress_percentage': 100.0,
        'points_earned': points,
        'completed_at': DateTime.now().toIso8601String(),
      });

      // Insert points transaction
      await _client.from('points_transactions').insert({
        'user_id': userId,
        'points': points,
        'transaction_type': 'homework_completed',
        'reference_id': homeworkId,
        'description': 'Homework completed: ${homework?['title'] ?? 'Unknown'}',
      });

      return true;
    }) ?? false;
  }

  // Submit final project
  static Future<bool> submitFinalProject(String projectId, String? courseId, String? moduleId) async {
    return await SupabaseService.requireAuth((userId) async {
      // Get project details
      String tableName = 'final_projects';
      final projectResponse = await _client
          .from(tableName)
          .select('title, points_reward, course_id, module_id')
          .eq('id', projectId)
          .single();

      final points = projectResponse['points_reward'] ?? 0;
      final finalCourseId = courseId ?? projectResponse['course_id'];
      final finalModuleId = moduleId ?? projectResponse['module_id'];

      // Insert progress record
      await _client.from('user_progress').insert({
        'user_id': userId,
        'course_id': finalCourseId,
        'module_id': finalModuleId,
        'progress_type': 'final_project_submitted',
        'progress_percentage': 100.0,
        'points_earned': points,
        'completed_at': DateTime.now().toIso8601String(),
      });

      // Insert points transaction
      await _client.from('points_transactions').insert({
        'user_id': userId,
        'points': points,
        'transaction_type': 'final_project_completed',
        'reference_id': projectId,
        'description': 'Final project completed: ${projectResponse['title']}',
      });

      return true;
    }) ?? false;
  }
}