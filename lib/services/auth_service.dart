import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import '../models/user_registration_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await dotenv.load();
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> signUpWithExtendedProfile(UserRegistrationModel userData) async {
    try {
      String? avatarUrl;
      
      // Upload avatar if provided
      if (userData.avatarFile != null) {
        avatarUrl = await uploadAvatar(userData.avatarFile!);
      }
      
      final response = await client.auth.signUp(
        email: userData.email,
        password: userData.password,
        data: userData.toUserMetadata(avatarUrl: avatarUrl),
      );
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> uploadAvatar(File imageFile) async {
    try {
      final user = currentUser;
      if (user == null) return null;
      
      final fileName = '${user.id}.jpg';
      final path = 'avatars/$fileName';
      
      await client.storage.from('avatars').upload(
        path,
        imageFile,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );
      
      final publicUrl = client.storage.from('avatars').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('Avatar upload error: $e');
      return null;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        try {
          await client.from('users').update({
            'last_login_at': DateTime.now().toIso8601String(),
          }).eq('id', response.user!.id);
        } catch (e) {
          // Ignore database errors for now - user can still login
          print('Warning: Could not update last_login_at: $e');
        }
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  User? get currentUser => client.auth.currentUser;
  
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  bool get isAuthenticated => currentUser != null;
}