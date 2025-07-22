import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/purchase_models.dart';
import 'user_service.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  static SupabaseClient get _client => SupabaseService.client;

  // Get user's purchases
  static Future<List<Purchase>> getUserPurchases() async {
    return await SupabaseService.requireAuth((userId) async {
      final response = await _client
          .from('purchases')
          .select('''
            id, user_id, purchase_type, course_id, module_id, lesson_id,
            amount, payment_method, payment_status, transaction_id,
            purchased_at, expires_at,
            courses (id, title, price),
            modules (id, title, price),
            lessons (id, title, price)
          ''')
          .eq('user_id', userId)
          .eq('payment_status', 'completed')
          .order('purchased_at', ascending: false);

      return response.map((item) => Purchase.fromJson(item)).toList();
    }) ?? [];
  }

  // Create a new purchase
  static Future<String?> createPurchase({
    required PurchaseType purchaseType,
    String? courseId,
    String? moduleId,
    String? lessonId,
    required double amount,
    required String paymentMethod,
    String? transactionId,
  }) async {
    return await SupabaseService.requireAuth((userId) async {
      final purchaseData = {
        'user_id': userId,
        'purchase_type': purchaseType.name,
        'amount': amount,
        'payment_method': paymentMethod,
        'payment_status': 'pending',
        'purchased_at': DateTime.now().toIso8601String(),
      };

      // Add the appropriate ID based on purchase type
      switch (purchaseType) {
        case PurchaseType.course:
          if (courseId != null) purchaseData['course_id'] = courseId;
          break;
        case PurchaseType.module:
          if (moduleId != null) purchaseData['module_id'] = moduleId;
          break;
        case PurchaseType.lesson:
          if (lessonId != null) purchaseData['lesson_id'] = lessonId;
          break;
      }

      if (transactionId != null) {
        purchaseData['transaction_id'] = transactionId;
      }

      final response = await _client
          .from('purchases')
          .insert(purchaseData)
          .select('id')
          .single();

      return response['id'] as String;
    });
  }

  // Complete purchase (update status to completed)
  static Future<bool> completePurchase(String purchaseId, String? transactionId) async {
    return await SupabaseService.safeExecute(() async {
      final updateData = {
        'payment_status': 'completed',
        'purchased_at': DateTime.now().toIso8601String(),
      };

      if (transactionId != null) {
        updateData['transaction_id'] = transactionId;
      }

      await _client
          .from('purchases')
          .update(updateData)
          .eq('id', purchaseId);

      return true;
    }) ?? false;
  }

  // Check if user has access to specific content using database functions
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


  // Purchase a course
  static Future<Map<String, dynamic>> purchaseCourse(
    String courseId,
    double amount,
    String paymentMethod,
  ) async {
    return await SupabaseService.requireAuth((userId) async {
      try {
        // Check if already purchased
        final existing = await _client
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
        final response = await _client
            .from('purchases')
            .insert({
              'user_id': userId,
              'course_id': courseId,
              'purchase_type': 'course',
              'amount': amount,
              'payment_method': paymentMethod,
              'payment_status': 'completed',
              'transaction_id': 'txn_${DateTime.now().millisecondsSinceEpoch}',
            })
            .select()
            .single();


        return {
          'success': true,
          'message': 'Course purchased successfully',
          'purchase_id': response['id'],
          'amount': amount,
        };
      } catch (e) {
        return {'success': false, 'message': 'Purchase failed: $e'};
      }
    }) ?? {'success': false, 'message': 'User not authenticated'};
  }

  // Purchase a module
  static Future<Map<String, dynamic>> purchaseModule(
    String moduleId,
    double amount,
    String paymentMethod,
  ) async {
    return await SupabaseService.requireAuth((userId) async {
      try {
        // Check if already purchased or has access
        final hasAccess = await hasAccessToModule(moduleId);
        if (hasAccess) {
          return {'success': false, 'message': 'You already have access to this module'};
        }

        // Create purchase record
        final response = await _client
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

        return {
          'success': true,
          'message': 'Module purchased successfully',
          'purchase_id': response['id'],
          'amount': amount,
        };
      } catch (e) {
        return {'success': false, 'message': 'Purchase failed: $e'};
      }
    }) ?? {'success': false, 'message': 'User not authenticated'};
  }

  // Purchase a lesson
  static Future<Map<String, dynamic>> purchaseLesson(
    String lessonId,
    double amount,
    String paymentMethod,
  ) async {
    return await SupabaseService.requireAuth((userId) async {
      try {
        // Check if already has access
        final hasAccess = await hasAccessToLesson(lessonId);
        if (hasAccess) {
          return {'success': false, 'message': 'You already have access to this lesson'};
        }

        // Create purchase record
        final response = await _client
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

        return {
          'success': true,
          'message': 'Lesson purchased successfully',
          'purchase_id': response['id'],
          'amount': amount,
        };
      } catch (e) {
        return {'success': false, 'message': 'Purchase failed: $e'};
      }
    }) ?? {'success': false, 'message': 'User not authenticated'};
  }

  // Get user's progress summary
  static Future<UserProgressSummary?> getUserProgressSummary() async {
    return await SupabaseService.requireAuth((userId) async {
      final result = await _client
          .rpc('get_user_progress_summary', params: {
            'user_uuid': userId,
          });

      if (result != null && result.isNotEmpty) {
        return UserProgressSummary.fromJson(result[0]);
      }
      return UserProgressSummary(
        totalCoursesPurchased: 0,
        totalModulesPurchased: 0,
        totalLessonsPurchased: 0,
        totalLessonsCompleted: 0,
        totalHomeworkCompleted: 0,
        totalFinalProjectsCompleted: 0,
        totalPoints: 0,
        totalUsefulPosts: 0,
      );
    });
  }


  // Get content pricing
  static Future<Map<String, double>> getContentPricing({
    String? courseId,
    String? moduleId,
    String? lessonId,
  }) async {
    return await SupabaseService.safeExecute(() async {
      final pricing = <String, double>{};

      if (courseId != null) {
        final response = await _client
            .from('courses')
            .select('price')
            .eq('id', courseId)
            .single();
        pricing['course'] = double.parse(response['price'].toString());
      }

      if (moduleId != null) {
        final response = await _client
            .from('modules')
            .select('price')
            .eq('id', moduleId)
            .single();
        pricing['module'] = double.parse(response['price'].toString());
      }

      if (lessonId != null) {
        final response = await _client
            .from('lessons')
            .select('price')
            .eq('id', lessonId)
            .single();
        pricing['lesson'] = double.parse(response['price'].toString());
      }

      return pricing;
    }) ?? {};
  }

  // Get total spent by user
  static Future<double> getTotalSpent() async {
    return await SupabaseService.requireAuth((userId) async {
      final response = await _client
          .from('purchases')
          .select('amount')
          .eq('user_id', userId)
          .eq('payment_status', 'completed');

      double total = 0;
      for (final purchase in response) {
        total += double.parse(purchase['amount'].toString());
      }

      return total;
    }) ?? 0.0;
  }
}