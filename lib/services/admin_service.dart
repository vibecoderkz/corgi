import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  static SupabaseClient get _client => SupabaseService.client;

  // Check if current user is admin
  static Future<bool> isAdmin() async {
    return await SupabaseService.requireAuth((userId) async {
      final response = await _client
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();
      
      final userRole = response['role'] as String? ?? 'student';
      return userRole == 'admin';
    }) ?? false;
  }

  // Get current user's role
  static Future<String> getCurrentUserRole() async {
    return await SupabaseService.requireAuth((userId) async {
      final response = await _client
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      return response['role'] as String? ?? 'student';
    }) ?? 'student';
  }

  // =============================================
  // IMAGE UPLOAD MANAGEMENT
  // =============================================
  
  // Upload course image
  static Future<String?> uploadCourseImage({
    required File imageFile,
    required String courseId,
  }) async {
    try {
      final result = await SupabaseService.requireAuth<String?>((userId) async {
        // Check admin permissions
        if (!await isAdmin()) {
          return null;
        }

        final path = SupabaseService.generateStoragePath(
          prefix: 'courses',
          fileName: imageFile.path.split('/').last,
        );

        return await SupabaseService.uploadFile(
          bucket: 'courseimage',
          path: path,
          file: imageFile,
        );
      });
      return result;
    } catch (e) {
      print('Failed to upload course image: $e');
      return null;
    }
  }
  
  // Upload course image from bytes
  static Future<String?> uploadCourseImageBytes({
    required Uint8List imageBytes,
    required String courseId,
    required String fileName,
  }) async {
    try {
      final result = await SupabaseService.requireAuth<String?>((userId) async {
        // Check admin permissions
        if (!await isAdmin()) {
          return null;
        }

        final path = SupabaseService.generateStoragePath(
          prefix: 'courses',
          fileName: fileName,
        );

        return await SupabaseService.uploadBytes(
          bucket: 'courseimage',
          path: path,
          bytes: imageBytes,
        );
      });
      return result;
    } catch (e) {
      print('Failed to upload course image: $e');
      return null;
    }
  }
  
  // Upload module image
  static Future<String?> uploadModuleImage({
    required File imageFile,
    required String moduleId,
  }) async {
    try {
      final result = await SupabaseService.requireAuth<String?>((userId) async {
        // Check admin permissions
        if (!await isAdmin()) {
          return null;
        }

        final path = SupabaseService.generateStoragePath(
          prefix: 'modules',
          fileName: imageFile.path.split('/').last,
        );

        return await SupabaseService.uploadFile(
          bucket: 'courseimage',
          path: path,
          file: imageFile,
        );
      });
      return result;
    } catch (e) {
      print('Failed to upload module image: $e');
      return null;
    }
  }
  
  // Delete course image
  static Future<bool> deleteCourseImage(String imageUrl) async {
    try {
      final result = await SupabaseService.requireAuth<bool>((userId) async {
        // Check admin permissions
        if (!await isAdmin()) {
          return false;
        }

        // Extract path from URL
        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length < 3) return false;
        
        // Path should be like: storage/v1/object/public/courseimage/...
        final startIndex = pathSegments.indexOf('courseimage') + 1;
        if (startIndex == 0) return false;
        
        final path = pathSegments.sublist(startIndex).join('/');

        return await SupabaseService.deleteFile(
          bucket: 'courseimage',
          path: path,
        );
      });
      return result ?? false;
    } catch (e) {
      print('Failed to delete course image: $e');
      return false;
    }
  }

  // =============================================
  // COURSE MANAGEMENT
  // =============================================

  // Create a new course
  static Future<Map<String, dynamic>> createCourse({
    required String title,
    required String description,
    required double price,
    required String difficulty,
    required String estimatedTime,
    String? imageUrl,
    String? videoPreviewUrl,
  }) async {
    return await SupabaseService.requireAuth((userId) async {
      try {
        // Check admin permissions
        if (!await isAdmin()) {
          return {'success': false, 'message': 'Admin privileges required'};
        }

        final response = await _client
            .from('courses')
            .insert({
              'title': title,
              'description': description,
              'price': price,
              'difficulty': difficulty,
              'estimated_time': estimatedTime,
              'image_url': imageUrl,
              'video_preview_url': videoPreviewUrl,
              'is_active': true,
            })
            .select()
            .single();

        return {
          'success': true,
          'course': response,
          'message': 'Course created successfully',
        };
      } catch (e) {
        return {'success': false, 'message': 'Failed to create course: $e'};
      }
    }) ?? {'success': false, 'message': 'User not authenticated'};
  }

  // Update an existing course
  static Future<Map<String, dynamic>> updateCourse({
    required String courseId,
    String? title,
    String? description,
    double? price,
    String? difficulty,
    String? estimatedTime,
    String? imageUrl,
    String? videoPreviewUrl,
    bool? isActive,
  }) async {
    return await SupabaseService.requireAuth((userId) async {
      try {
        // Check admin permissions
        if (!await isAdmin()) {
          return {'success': false, 'message': 'Admin privileges required'};
        }

        final updateData = <String, dynamic>{};
        if (title != null) updateData['title'] = title;
        if (description != null) updateData['description'] = description;
        if (price != null) updateData['price'] = price;
        if (difficulty != null) updateData['difficulty'] = difficulty;
        if (estimatedTime != null) updateData['estimated_time'] = estimatedTime;
        if (imageUrl != null) updateData['image_url'] = imageUrl;
        if (videoPreviewUrl != null) updateData['video_preview_url'] = videoPreviewUrl;
        if (isActive != null) updateData['is_active'] = isActive;

        if (updateData.isEmpty) {
          return {'success': false, 'message': 'No data to update'};
        }

        updateData['updated_at'] = DateTime.now().toIso8601String();

        await _client
            .from('courses')
            .update(updateData)
            .eq('id', courseId);

        return {
          'success': true,
          'message': 'Course updated successfully',
        };
      } catch (e) {
        return {'success': false, 'message': 'Failed to update course: $e'};
      }
    }) ?? {'success': false, 'message': 'User not authenticated'};
  }

  // Delete a course
  static Future<Map<String, dynamic>> deleteCourse(String courseId) async {
    return await SupabaseService.requireAuth((userId) async {
      try {
        // Check admin permissions
        if (!await isAdmin()) {
          return {'success': false, 'message': 'Admin privileges required'};
        }

        // Soft delete by setting is_active to false
        await _client
            .from('courses')
            .update({'is_active': false})
            .eq('id', courseId);

        return {
          'success': true,
          'message': 'Course deleted successfully',
        };
      } catch (e) {
        return {'success': false, 'message': 'Failed to delete course: $e'};
      }
    }) ?? {'success': false, 'message': 'User not authenticated'};
  }

  // =============================================
  // MODULE MANAGEMENT
  // =============================================

  // Create a new module
  static Future<Map<String, dynamic>> createModule({
    required String courseId,
    required String title,
    required String description,
    required double price,
    required int orderIndex,
    String? imageUrl,
    String? videoPreviewUrl,
  }) async {
    return await SupabaseService.requireAuth((userId) async {
      try {
        // Check admin permissions
        if (!await isAdmin()) {
          return {'success': false, 'message': 'Admin privileges required'};
        }

        final response = await _client
            .from('modules')
            .insert({
              'course_id': courseId,
              'title': title,
              'description': description,
              'price': price,
              'order_index': orderIndex,
              'image_url': imageUrl,
              'video_preview_url': videoPreviewUrl,
              'is_active': true,
            })
            .select()
            .single();

        return {
          'success': true,
          'module': response,
          'message': 'Module created successfully',
        };
      } catch (e) {
        return {'success': false, 'message': 'Failed to create module: $e'};
      }
    }) ?? {'success': false, 'message': 'User not authenticated'};
  }

  // Update an existing module
  static Future<Map<String, dynamic>> updateModule({
    required String moduleId,
    String? title,
    String? description,
    double? price,
    int? orderIndex,
    String? imageUrl,
    String? videoPreviewUrl,
    bool? isActive,
  }) async {
    return await SupabaseService.requireAuth((userId) async {
      try {
        // Check admin permissions
        if (!await isAdmin()) {
          return {'success': false, 'message': 'Admin privileges required'};
        }

        final updateData = <String, dynamic>{};
        if (title != null) updateData['title'] = title;
        if (description != null) updateData['description'] = description;
        if (price != null) updateData['price'] = price;
        if (orderIndex != null) updateData['order_index'] = orderIndex;
        if (imageUrl != null) updateData['image_url'] = imageUrl;
        if (videoPreviewUrl != null) updateData['video_preview_url'] = videoPreviewUrl;
        if (isActive != null) updateData['is_active'] = isActive;

        if (updateData.isEmpty) {
          return {'success': false, 'message': 'No data to update'};
        }

        updateData['updated_at'] = DateTime.now().toIso8601String();

        await _client
            .from('modules')
            .update(updateData)
            .eq('id', moduleId);

        return {
          'success': true,
          'message': 'Module updated successfully',
        };
      } catch (e) {
        return {'success': false, 'message': 'Failed to update module: $e'};
      }
    }) ?? {'success': false, 'message': 'User not authenticated'};
  }

  // Delete a module
  static Future<Map<String, dynamic>> deleteModule(String moduleId) async {
    return await SupabaseService.requireAuth((userId) async {
      try {
        // Check admin permissions
        if (!await isAdmin()) {
          return {'success': false, 'message': 'Admin privileges required'};
        }

        // Soft delete by setting is_active to false
        await _client
            .from('modules')
            .update({'is_active': false})
            .eq('id', moduleId);

        return {
          'success': true,
          'message': 'Module deleted successfully',
        };
      } catch (e) {
        return {'success': false, 'message': 'Failed to delete module: $e'};
      }
    }) ?? {'success': false, 'message': 'User not authenticated'};
  }

  // =============================================
  // LESSON MANAGEMENT
  // =============================================

  // Create a new lesson
  static Future<Map<String, dynamic>> createLesson({
    required String moduleId,
    required String title,
    required String description,
    required double price,
    required int orderIndex,
    required String contentType,
    String? contentUrl,
    int? durationMinutes,
  }) async {
    return await SupabaseService.requireAuth((userId) async {
      try {
        // Check admin permissions
        if (!await isAdmin()) {
          return {'success': false, 'message': 'Admin privileges required'};
        }

        final response = await _client
            .from('lessons')
            .insert({
              'module_id': moduleId,
              'title': title,
              'description': description,
              'price': price,
              'order_index': orderIndex,
              'content_type': contentType,
              'content_url': contentUrl,
              'duration_minutes': durationMinutes,
              'is_active': true,
            })
            .select()
            .single();

        return {
          'success': true,
          'lesson': response,
          'message': 'Lesson created successfully',
        };
      } catch (e) {
        return {'success': false, 'message': 'Failed to create lesson: $e'};
      }
    }) ?? {'success': false, 'message': 'User not authenticated'};
  }

  // Update an existing lesson
  static Future<Map<String, dynamic>> updateLesson({
    required String lessonId,
    String? title,
    String? description,
    double? price,
    int? orderIndex,
    String? contentType,
    String? contentUrl,
    int? durationMinutes,
    bool? isActive,
  }) async {
    return await SupabaseService.requireAuth((userId) async {
      try {
        // Check admin permissions
        if (!await isAdmin()) {
          return {'success': false, 'message': 'Admin privileges required'};
        }

        final updateData = <String, dynamic>{};
        if (title != null) updateData['title'] = title;
        if (description != null) updateData['description'] = description;
        if (price != null) updateData['price'] = price;
        if (orderIndex != null) updateData['order_index'] = orderIndex;
        if (contentType != null) updateData['content_type'] = contentType;
        if (contentUrl != null) updateData['content_url'] = contentUrl;
        if (durationMinutes != null) updateData['duration_minutes'] = durationMinutes;
        if (isActive != null) updateData['is_active'] = isActive;

        if (updateData.isEmpty) {
          return {'success': false, 'message': 'No data to update'};
        }

        updateData['updated_at'] = DateTime.now().toIso8601String();

        await _client
            .from('lessons')
            .update(updateData)
            .eq('id', lessonId);

        return {
          'success': true,
          'message': 'Lesson updated successfully',
        };
      } catch (e) {
        return {'success': false, 'message': 'Failed to update lesson: $e'};
      }
    }) ?? {'success': false, 'message': 'User not authenticated'};
  }

  // Delete a lesson
  static Future<Map<String, dynamic>> deleteLesson(String lessonId) async {
    return await SupabaseService.requireAuth((userId) async {
      try {
        // Check admin permissions
        if (!await isAdmin()) {
          return {'success': false, 'message': 'Admin privileges required'};
        }

        // Soft delete by setting is_active to false
        await _client
            .from('lessons')
            .update({'is_active': false})
            .eq('id', lessonId);

        return {
          'success': true,
          'message': 'Lesson deleted successfully',
        };
      } catch (e) {
        return {'success': false, 'message': 'Failed to delete lesson: $e'};
      }
    }) ?? {'success': false, 'message': 'User not authenticated'};
  }

  // =============================================
  // HOMEWORK AND FINAL PROJECTS
  // =============================================

  // Create homework for a lesson
  static Future<Map<String, dynamic>> createHomework({
    required String lessonId,
    required String title,
    required String description,
    required int pointsReward,
    required List<String> requirements,
    required String submissionFormat,
  }) async {
    return await SupabaseService.requireAuth((userId) async {
      try {
        // Check admin permissions
        if (!await isAdmin()) {
          return {'success': false, 'message': 'Admin privileges required'};
        }

        final response = await _client
            .from('homework')
            .insert({
              'lesson_id': lessonId,
              'title': title,
              'description': description,
              'points_reward': pointsReward,
              'requirements': requirements,
              'submission_format': submissionFormat,
              'is_active': true,
            })
            .select()
            .single();

        return {
          'success': true,
          'homework': response,
          'message': 'Homework created successfully',
        };
      } catch (e) {
        return {'success': false, 'message': 'Failed to create homework: $e'};
      }
    }) ?? {'success': false, 'message': 'User not authenticated'};
  }

  // Create final project
  static Future<Map<String, dynamic>> createFinalProject({
    String? courseId,
    String? moduleId,
    required String title,
    required String description,
    required double price,
    required int pointsReward,
    required List<String> requirements,
    required String submissionFormat,
  }) async {
    return await SupabaseService.requireAuth((userId) async {
      try {
        // Check admin permissions
        if (!await isAdmin()) {
          return {'success': false, 'message': 'Admin privileges required'};
        }

        final response = await _client
            .from('final_projects')
            .insert({
              'course_id': courseId,
              'module_id': moduleId,
              'title': title,
              'description': description,
              'price': price,
              'points_reward': pointsReward,
              'requirements': requirements,
              'submission_format': submissionFormat,
              'is_active': true,
            })
            .select()
            .single();

        return {
          'success': true,
          'final_project': response,
          'message': 'Final project created successfully',
        };
      } catch (e) {
        return {'success': false, 'message': 'Failed to create final project: $e'};
      }
    }) ?? {'success': false, 'message': 'User not authenticated'};
  }

  // =============================================
  // ADMIN DASHBOARD DATA
  // =============================================

  // Get admin dashboard statistics
  static Future<Map<String, dynamic>> getAdminStats() async {
    return await SupabaseService.requireAuth((userId) async {
      try {
        // Check admin permissions
        if (!await isAdmin()) {
          return {'success': false, 'message': 'Admin privileges required'};
        }

        // Get counts for dashboard
        final coursesResponse = await _client
            .from('courses')
            .select('id')
            .eq('is_active', true);

        final modulesResponse = await _client
            .from('modules')
            .select('id')
            .eq('is_active', true);

        final lessonsResponse = await _client
            .from('lessons')
            .select('id')
            .eq('is_active', true);

        final usersResponse = await _client
            .from('users')
            .select('id');

        final purchasesResponse = await _client
            .from('purchases')
            .select('amount')
            .eq('payment_status', 'completed');

        final totalRevenue = purchasesResponse.fold<double>(
          0.0, 
          (sum, purchase) => sum + double.parse(purchase['amount'].toString())
        );

        return {
          'success': true,
          'stats': {
            'total_courses': coursesResponse.length,
            'total_modules': modulesResponse.length,
            'total_lessons': lessonsResponse.length,
            'total_users': usersResponse.length,
            'total_purchases': purchasesResponse.length,
            'total_revenue': totalRevenue,
          },
        };
      } catch (e) {
        return {'success': false, 'message': 'Failed to get admin stats: $e'};
      }
    }) ?? {'success': false, 'message': 'User not authenticated'};
  }

  // Get recent activity for admin dashboard
  static Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 10}) async {
    final result = await SupabaseService.requireAuth((userId) async {
      try {
        // Check admin permissions
        if (!await isAdmin()) {
          return <Map<String, dynamic>>[];
        }

        final response = await _client
            .from('purchases')
            .select('''
              id, amount, payment_status, purchased_at,
              users (id, full_name),
              courses (id, title),
              modules (id, title),
              lessons (id, title)
            ''')
            .order('purchased_at', ascending: false)
            .limit(limit);

        return List<Map<String, dynamic>>.from(response);
      } catch (e) {
        return <Map<String, dynamic>>[];
      }
    });
    
    return result ?? <Map<String, dynamic>>[];
  }
}