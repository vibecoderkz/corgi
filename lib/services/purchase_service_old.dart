import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/purchase_models.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  static SupabaseClient get _client => SupabaseService.client;

  // Check if user has access to a course
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

  // Legacy method for backward compatibility
  static Future<bool> hasAccessToCourseWithUserId(String userId, String courseId) async {
    final response = await _client
        .from('purchases')
        .select('id')
        .eq('user_id', userId)
        .eq('course_id', courseId)
        .eq('purchase_type', 'course')
        .eq('payment_status', 'completed')
        .maybeSingle();
    
    return response != null;
  }

  // Check if user has access to a module
  static Future<bool> hasAccessToModule(String userId, String moduleId) async {
    // Check if user purchased the module directly
    final moduleResponse = await _supabase
        .from('purchases')
        .select('id')
        .eq('user_id', userId)
        .eq('module_id', moduleId)
        .eq('purchase_type', 'module')
        .eq('payment_status', 'completed')
        .maybeSingle();
    
    if (moduleResponse != null) return true;

    // Check if user purchased the entire course
    final courseResponse = await _supabase
        .from('purchases')
        .select('id')
        .eq('user_id', userId)
        .eq('purchase_type', 'course')
        .eq('payment_status', 'completed')
        .single();
    
    if (courseResponse != null) {
      // Verify the module belongs to the purchased course
      final moduleInfo = await _supabase
          .from('modules')
          .select('course_id')
          .eq('id', moduleId)
          .single();
      
      final courseCheck = await _supabase
          .from('purchases')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', moduleInfo['course_id'])
          .eq('purchase_type', 'course')
          .eq('payment_status', 'completed')
          .maybeSingle();
      
      return courseCheck != null;
    }

    return false;
  }

  // Check if user has access to a lesson
  static Future<bool> hasAccessToLesson(String userId, String lessonId) async {
    // Check if user purchased the lesson directly
    final lessonResponse = await _supabase
        .from('purchases')
        .select('id')
        .eq('user_id', userId)
        .eq('lesson_id', lessonId)
        .eq('purchase_type', 'lesson')
        .eq('payment_status', 'completed')
        .maybeSingle();
    
    if (lessonResponse != null) return true;

    // Check if user purchased the module containing this lesson
    final lessonInfo = await _supabase
        .from('lessons')
        .select('module_id')
        .eq('id', lessonId)
        .single();
    
    final moduleAccess = await hasAccessToModule(userId, lessonInfo['module_id']);
    if (moduleAccess) return true;

    // Check if user purchased the entire course
    final moduleInfo = await _supabase
        .from('modules')
        .select('course_id')
        .eq('id', lessonInfo['module_id'])
        .single();
    
    return await hasAccessToCourse(userId, moduleInfo['course_id']);
  }

  // Purchase a course
  static Future<Map<String, dynamic>> purchaseCourse(
    String userId,
    String courseId,
    double amount,
    String paymentMethod,
  ) async {
    try {
      // Check if already purchased
      final existing = await _supabase
          .from('purchases')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .eq('purchase_type', 'course')
          .eq('payment_status', 'completed')
          .maybeSingle();
      
      if (existing != null) {
        return {'success': false, 'message': 'Course already purchased'};
      }

      // Create purchase record
      final response = await _supabase
          .from('purchases')
          .insert({
            'user_id': userId,
            'course_id': courseId,
            'purchase_type': 'course',
            'amount': amount,
            'payment_method': paymentMethod,
            'payment_status': 'completed', // In real app, this would be 'pending' until payment is confirmed
            'transaction_id': 'txn_${DateTime.now().millisecondsSinceEpoch}',
          })
          .select()
          .single();

      // Create discussion group access for the course
      await _createDiscussionGroupsForCourse(userId, courseId);

      return {
        'success': true,
        'message': 'Course purchased successfully',
        'purchase_id': response['id']
      };
    } catch (e) {
      return {'success': false, 'message': 'Purchase failed: $e'};
    }
  }

  // Purchase a module
  static Future<Map<String, dynamic>> purchaseModule(
    String userId,
    String moduleId,
    double amount,
    String paymentMethod,
  ) async {
    try {
      // Check if already purchased
      final existing = await _supabase
          .from('purchases')
          .select('id')
          .eq('user_id', userId)
          .eq('module_id', moduleId)
          .eq('purchase_type', 'module')
          .eq('payment_status', 'completed')
          .maybeSingle();
      
      if (existing != null) {
        return {'success': false, 'message': 'Module already purchased'};
      }

      // Check if user already has access through course purchase
      final hasAccess = await hasAccessToModule(userId, moduleId);
      if (hasAccess) {
        return {'success': false, 'message': 'You already have access to this module'};
      }

      // Create purchase record
      final response = await _supabase
          .from('purchases')
          .insert({
            'user_id': userId,
            'module_id': moduleId,
            'purchase_type': 'module',
            'amount': amount,
            'payment_method': paymentMethod,
            'payment_status': 'completed',
            'transaction_id': 'txn_${DateTime.now().millisecondsSinceEpoch}',
          })
          .select()
          .single();

      // Create discussion group access for the module
      await _createDiscussionGroupsForModule(userId, moduleId);

      return {
        'success': true,
        'message': 'Module purchased successfully',
        'purchase_id': response['id']
      };
    } catch (e) {
      return {'success': false, 'message': 'Purchase failed: $e'};
    }
  }

  // Purchase a lesson
  static Future<Map<String, dynamic>> purchaseLesson(
    String userId,
    String lessonId,
    double amount,
    String paymentMethod,
  ) async {
    try {
      // Check if already purchased
      final existing = await _supabase
          .from('purchases')
          .select('id')
          .eq('user_id', userId)
          .eq('lesson_id', lessonId)
          .eq('purchase_type', 'lesson')
          .eq('payment_status', 'completed')
          .maybeSingle();
      
      if (existing != null) {
        return {'success': false, 'message': 'Lesson already purchased'};
      }

      // Check if user already has access through module/course purchase
      final hasAccess = await hasAccessToLesson(userId, lessonId);
      if (hasAccess) {
        return {'success': false, 'message': 'You already have access to this lesson'};
      }

      // Create purchase record
      final response = await _supabase
          .from('purchases')
          .insert({
            'user_id': userId,
            'lesson_id': lessonId,
            'purchase_type': 'lesson',
            'amount': amount,
            'payment_method': paymentMethod,
            'payment_status': 'completed',
            'transaction_id': 'txn_${DateTime.now().millisecondsSinceEpoch}',
          })
          .select()
          .single();

      // Create discussion group access for the lesson
      await _createDiscussionGroupsForLesson(userId, lessonId);

      return {
        'success': true,
        'message': 'Lesson purchased successfully',
        'purchase_id': response['id']
      };
    } catch (e) {
      return {'success': false, 'message': 'Purchase failed: $e'};
    }
  }

  // Get accessible discussion groups for a user
  static Future<List<Map<String, dynamic>>> getAccessibleDiscussionGroups(String userId) async {
    final groups = <Map<String, dynamic>>[];

    // Get course-level discussions
    final coursePurchases = await _supabase
        .from('purchases')
        .select('''
          course_id,
          courses (
            id,
            title,
            discussion_groups (
              id,
              name,
              description,
              course_id,
              module_id,
              lesson_id
            )
          )
        ''')
        .eq('user_id', userId)
        .eq('purchase_type', 'course')
        .eq('payment_status', 'completed');

    for (final purchase in coursePurchases) {
      final course = purchase['courses'];
      if (course != null && course['discussion_groups'] != null) {
        for (final group in course['discussion_groups']) {
          groups.add({
            ...group,
            'access_level': 'course',
            'parent_title': course['title'],
          });
        }
      }
    }

    // Get module-level discussions
    final modulePurchases = await _supabase
        .from('purchases')
        .select('''
          module_id,
          modules (
            id,
            title,
            discussion_groups (
              id,
              name,
              description,
              course_id,
              module_id,
              lesson_id
            )
          )
        ''')
        .eq('user_id', userId)
        .eq('purchase_type', 'module')
        .eq('payment_status', 'completed');

    for (final purchase in modulePurchases) {
      final module = purchase['modules'];
      if (module != null && module['discussion_groups'] != null) {
        for (final group in module['discussion_groups']) {
          groups.add({
            ...group,
            'access_level': 'module',
            'parent_title': module['title'],
          });
        }
      }
    }

    // Get lesson-level discussions
    final lessonPurchases = await _supabase
        .from('purchases')
        .select('''
          lesson_id,
          lessons (
            id,
            title,
            discussion_groups (
              id,
              name,
              description,
              course_id,
              module_id,
              lesson_id
            )
          )
        ''')
        .eq('user_id', userId)
        .eq('purchase_type', 'lesson')
        .eq('payment_status', 'completed');

    for (final purchase in lessonPurchases) {
      final lesson = purchase['lessons'];
      if (lesson != null && lesson['discussion_groups'] != null) {
        for (final group in lesson['discussion_groups']) {
          groups.add({
            ...group,
            'access_level': 'lesson',
            'parent_title': lesson['title'],
          });
        }
      }
    }

    return groups;
  }

  // Helper method to create discussion groups for course
  static Future<void> _createDiscussionGroupsForCourse(String userId, String courseId) async {
    // This would typically be done when the course is created, not on purchase
    // But here's the logic for reference
    final course = await _supabase
        .from('courses')
        .select('title')
        .eq('id', courseId)
        .single();

    // Check if course discussion group exists
    final existingGroup = await _supabase
        .from('discussion_groups')
        .select('id')
        .eq('course_id', courseId)
        .maybeSingle();

    if (existingGroup == null) {
      await _supabase
          .from('discussion_groups')
          .insert({
            'course_id': courseId,
            'name': '${course['title']} - Course Discussion',
            'description': 'General discussion for the entire course',
          });
    }
  }

  // Helper method to create discussion groups for module
  static Future<void> _createDiscussionGroupsForModule(String userId, String moduleId) async {
    final module = await _supabase
        .from('modules')
        .select('title')
        .eq('id', moduleId)
        .single();

    final existingGroup = await _supabase
        .from('discussion_groups')
        .select('id')
        .eq('module_id', moduleId)
        .maybeSingle();

    if (existingGroup == null) {
      await _supabase
          .from('discussion_groups')
          .insert({
            'module_id': moduleId,
            'name': '${module['title']} - Module Discussion',
            'description': 'Discussion for this module',
          });
    }
  }

  // Helper method to create discussion groups for lesson
  static Future<void> _createDiscussionGroupsForLesson(String userId, String lessonId) async {
    final lesson = await _supabase
        .from('lessons')
        .select('title')
        .eq('id', lessonId)
        .single();

    final existingGroup = await _supabase
        .from('discussion_groups')
        .select('id')
        .eq('lesson_id', lessonId)
        .maybeSingle();

    if (existingGroup == null) {
      await _supabase
          .from('discussion_groups')
          .insert({
            'lesson_id': lessonId,
            'name': '${lesson['title']} - Lesson Discussion',
            'description': 'Discussion for this lesson',
          });
    }
  }

  // Get user's purchases
  static Future<List<Map<String, dynamic>>> getUserPurchases(String userId) async {
    return await _supabase
        .from('purchases')
        .select('''
          *,
          courses (id, title, price),
          modules (id, title, price),
          lessons (id, title, price)
        ''')
        .eq('user_id', userId)
        .eq('payment_status', 'completed')
        .order('purchased_at', ascending: false);
  }

  // Get user's total spending
  static Future<double> getUserTotalSpending(String userId) async {
    final response = await _supabase
        .from('purchases')
        .select('amount')
        .eq('user_id', userId)
        .eq('payment_status', 'completed');

    double total = 0;
    for (final purchase in response) {
      total += purchase['amount'];
    }
    return total;
  }
}