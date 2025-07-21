import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'supabase_service.dart';
import '../models/main_page_models.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static SupabaseClient get _client => SupabaseService.client;

  // Get current user profile data
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    return await SupabaseService.requireAuth((userId) async {
      final response = await _client
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();
      
      return response;
    });
  }

  // Get comprehensive user statistics
  static Future<UserStats> getUserStats() async {
    return await SupabaseService.requireAuth((userId) async {
      try {
        // Get all courses count
        final totalCoursesResponse = await _client
            .from('courses')
            .select('id')
            .eq('is_active', true);
        final totalCourses = totalCoursesResponse.length;

        // Get user's completed courses
        final completedCoursesResponse = await _client
            .from('user_progress')
            .select('course_id')
            .eq('user_id', userId)
            .eq('progress_type', 'course_completed');
        final coursesCompleted = completedCoursesResponse.length;

        // Get all modules count
        final totalModulesResponse = await _client
            .from('modules')
            .select('id')
            .eq('is_active', true);
        final totalModules = totalModulesResponse.length;

        // Get user's completed modules
        final completedModulesResponse = await _client
            .from('user_progress')
            .select('module_id')
            .eq('user_id', userId)
            .eq('progress_type', 'module_completed');
        final modulesCompleted = completedModulesResponse.length;

        // Get user's completed lessons
        final completedLessonsResponse = await _client
            .from('user_progress')
            .select('lesson_id')
            .eq('user_id', userId)
            .eq('progress_type', 'lesson_completed');
        final lessonsCompleted = completedLessonsResponse.length;

        // Get user's current streak
        int streak = 0;
        try {
          final streakResponse = await _client
              .from('user_streaks')
              .select('current_streak')
              .eq('user_id', userId)
              .single();
          streak = streakResponse['current_streak'] ?? 0;
        } catch (e) {
          // Streak table might not exist, use default
          streak = 0;
        }

        return UserStats(
          coursesCompleted: coursesCompleted,
          totalCourses: totalCourses,
          lessonsCompleted: lessonsCompleted,
          modulesCompleted: modulesCompleted,
          totalModules: totalModules,
          totalLearningMinutes: 0, // Placeholder - implement based on your tracking
          userRank: 0, // Placeholder - implement based on your ranking logic
          streak: streak,
        );
      } catch (e) {
        // Return default stats if error occurs
        return UserStats.defaultStats();
      }
    }) ?? UserStats.defaultStats();
  }

  // Get user's current points
  static Future<int> getUserPoints() async {
    return await SupabaseService.requireAuth((userId) async {
      final response = await _client
          .from('users')
          .select('total_points')
          .eq('id', userId)
          .single();
      
      return response['total_points'] ?? 0;
    }) ?? 0;
  }

  // Get user's skill progress
  static Future<List<Map<String, dynamic>>> getUserSkillProgress(String userId) async {
    try {
      final response = await _client
          .from('user_skills')
          .select('skill_name, progress_percentage')
          .eq('user_id', userId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Return default skills if none exist
      return [
        {'skill_name': 'Machine Learning', 'progress_percentage': 0.0},
        {'skill_name': 'Deep Learning', 'progress_percentage': 0.0},
        {'skill_name': 'Natural Language Processing', 'progress_percentage': 0.0},
        {'skill_name': 'Computer Vision', 'progress_percentage': 0.0},
      ];
    }
  }

  // Get user's achievements
  static Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    try {
      final response = await _client
          .from('user_achievements')
          .select('achievement_name, achievement_icon, earned_at')
          .eq('user_id', userId)
          .order('earned_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Return default achievements if none exist
      return [
        {'achievement_name': 'First Steps', 'achievement_icon': 'flag', 'earned_at': DateTime.now().toIso8601String()},
        {'achievement_name': 'Quick Learner', 'achievement_icon': 'speed', 'earned_at': DateTime.now().toIso8601String()},
      ];
    }
  }

  // Get user's certificates
  static Future<List<Map<String, dynamic>>> getUserCertificates(String userId) async {
    try {
      final response = await _client
          .from('certificates')
          .select('id, course_title, completion_date, certificate_url')
          .eq('user_id', userId)
          .order('completion_date', ascending: false)
          .limit(5);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Return empty list if no certificates
      return [];
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? name,
    String? city,
    DateTime? birthDate,
    String? avatarUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (city != null) updateData['city'] = city;
      if (birthDate != null) updateData['birth_date'] = birthDate.toIso8601String();
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

      if (updateData.isEmpty) {
        return {'success': false, 'message': 'No data to update'};
      }

      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _client
          .from('users')
          .update(updateData)
          .eq('id', userId);

      return {'success': true, 'message': 'Profile updated successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update profile: $e'};
    }
  }

  // Upload profile image
  static Future<Map<String, dynamic>> uploadProfileImage(
    String userId,
    dynamic imageFile, // Can be File or Uint8List
    String fileName,
  ) async {
    try {
      // Create file path with user ID folder
      final filePath = '$userId/$fileName';
      
      // Upload to Supabase Storage
      String? uploadPath;
      if (imageFile is File) {
        uploadPath = await _client.storage
            .from('avatars')
            .upload(filePath, imageFile);
      } else if (imageFile is Uint8List) {
        uploadPath = await _client.storage
            .from('avatars')
            .uploadBinary(filePath, imageFile);
      } else {
        throw Exception('Unsupported file type');
      }
      
      // Get public URL
      final publicUrl = _client.storage
          .from('avatars')
          .getPublicUrl(filePath);
      
      // Update user profile with new avatar URL
      await updateUserProfile(
        userId: userId,
        avatarUrl: publicUrl,
      );
      
      return {
        'success': true, 
        'message': 'Profile image uploaded successfully',
        'url': publicUrl
      };
    } catch (e) {
      return {
        'success': false, 
        'message': 'Failed to upload profile image: $e'
      };
    }
  }

  // Delete profile image
  static Future<Map<String, dynamic>> deleteProfileImage(String userId, String fileName) async {
    try {
      final filePath = '$userId/$fileName';
      
      // Delete from storage
      await _client.storage
          .from('avatars')
          .remove([filePath]);
      
      // Update user profile to remove avatar URL
      await updateUserProfile(
        userId: userId,
        avatarUrl: null,
      );
      
      return {'success': true, 'message': 'Profile image deleted successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete profile image: $e'};
    }
  }
}