import 'dart:io';
import 'dart:typed_data';
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
  
  // Storage helper methods
  static Future<String?> uploadFile({
    required String bucket,
    required String path,
    required File file,
  }) async {
    return await safeExecute(() async {
      await client.storage.from(bucket).upload(path, file);
      return getPublicUrl(bucket: bucket, path: path);
    });
  }
  
  static Future<String?> uploadBytes({
    required String bucket,
    required String path,
    required Uint8List bytes,
  }) async {
    return await safeExecute(() async {
      await client.storage.from(bucket).uploadBinary(path, bytes);
      return getPublicUrl(bucket: bucket, path: path);
    });
  }
  
  static String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return client.storage.from(bucket).getPublicUrl(path);
  }
  
  static Future<bool> deleteFile({
    required String bucket,
    required String path,
  }) async {
    final result = await safeExecute(() async {
      await client.storage.from(bucket).remove([path]);
      return true;
    });
    return result ?? false;
  }
  
  static String generateStoragePath({
    required String prefix,
    required String fileName,
    String? userId,
  }) {
    final user = userId ?? currentUserId ?? 'anonymous';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = fileName.split('.').last;
    return '$prefix/$user/$timestamp.$extension';
  }
}