import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static SupabaseClient get client => AuthService.client;
  
  // Helper method to get current user ID
  static String? get currentUserId => AuthService().currentUser?.id;
  
  // Helper method to check if user is authenticated
  static bool get isAuthenticated => AuthService().isAuthenticated;
  
  // Helper method for error handling
  static String getErrorMessage(dynamic error) {
    if (error is PostgrestException) {
      return error.message;
    } else if (error is StorageException) {
      return error.message;
    } else if (error is AuthException) {
      return error.message;
    } else {
      return error.toString();
    }
  }
  
  // Helper method for safe database operations
  static Future<T?> safeExecute<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      print('Database operation failed: ${getErrorMessage(e)}');
      return null;
    }
  }
  
  // Helper method for required user operations
  static Future<T?> requireAuth<T>(Future<T> Function(String userId) operation) async {
    if (!isAuthenticated || currentUserId == null) {
      throw Exception('User must be authenticated');
    }
    return await operation(currentUserId!);
  }
}