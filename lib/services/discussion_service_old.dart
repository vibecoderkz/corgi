import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/discussion_models.dart';

class DiscussionService {
  static final DiscussionService _instance = DiscussionService._internal();
  factory DiscussionService() => _instance;
  DiscussionService._internal();

  static SupabaseClient get _client => SupabaseService.client;

  // Check if user has access to a discussion group
  static Future<bool> hasAccessToDiscussionGroup(String userId, String groupId) async {
    final group = await _supabase
        .from('discussion_groups')
        .select('course_id, module_id, lesson_id')
        .eq('id', groupId)
        .single();

    // Check access based on group type
    if (group['course_id'] != null) {
      return await PurchaseService.hasAccessToCourse(userId, group['course_id']);
    } else if (group['module_id'] != null) {
      return await PurchaseService.hasAccessToModule(userId, group['module_id']);
    } else if (group['lesson_id'] != null) {
      return await PurchaseService.hasAccessToLesson(userId, group['lesson_id']);
    }

    return false;
  }

  // Get discussion groups accessible to user
  static Future<List<Map<String, dynamic>>> getAccessibleDiscussionGroups(String userId) async {
    final accessibleGroups = <Map<String, dynamic>>[];

    // Get course-level groups
    final coursePurchases = await _supabase
        .from('purchases')
        .select('course_id')
        .eq('user_id', userId)
        .eq('purchase_type', 'course')
        .eq('payment_status', 'completed');

    for (final purchase in coursePurchases) {
      final courseGroups = await _supabase
          .from('discussion_groups')
          .select('''
            *,
            courses (title, id)
          ''')
          .eq('course_id', purchase['course_id'])
          .eq('is_active', true);

      for (final group in courseGroups) {
        accessibleGroups.add({
          ...group,
          'access_level': 'course',
          'parent_info': group['courses'],
        });
      }

      // Also get all module and lesson groups for purchased courses
      final modules = await _supabase
          .from('modules')
          .select('id')
          .eq('course_id', purchase['course_id'])
          .eq('is_active', true);

      for (final module in modules) {
        final moduleGroups = await _supabase
            .from('discussion_groups')
            .select('''
              *,
              modules (title, id)
            ''')
            .eq('module_id', module['id'])
            .eq('is_active', true);

        for (final group in moduleGroups) {
          accessibleGroups.add({
            ...group,
            'access_level': 'module',
            'parent_info': group['modules'],
          });
        }

        // Get lesson groups for this module
        final lessons = await _supabase
            .from('lessons')
            .select('id')
            .eq('module_id', module['id'])
            .eq('is_active', true);

        for (final lesson in lessons) {
          final lessonGroups = await _supabase
              .from('discussion_groups')
              .select('''
                *,
                lessons (title, id)
              ''')
              .eq('lesson_id', lesson['id'])
              .eq('is_active', true);

          for (final group in lessonGroups) {
            accessibleGroups.add({
              ...group,
              'access_level': 'lesson',
              'parent_info': group['lessons'],
            });
          }
        }
      }
    }

    // Get module-level groups (purchased individually)
    final modulePurchases = await _supabase
        .from('purchases')
        .select('module_id')
        .eq('user_id', userId)
        .eq('purchase_type', 'module')
        .eq('payment_status', 'completed');

    for (final purchase in modulePurchases) {
      final moduleGroups = await _supabase
          .from('discussion_groups')
          .select('''
            *,
            modules (title, id)
          ''')
          .eq('module_id', purchase['module_id'])
          .eq('is_active', true);

      for (final group in moduleGroups) {
        // Check if not already added through course purchase
        final alreadyAdded = accessibleGroups.any((g) => g['id'] == group['id']);
        if (!alreadyAdded) {
          accessibleGroups.add({
            ...group,
            'access_level': 'module',
            'parent_info': group['modules'],
          });
        }
      }

      // Get lesson groups for this module
      final lessons = await _supabase
          .from('lessons')
          .select('id')
          .eq('module_id', purchase['module_id'])
          .eq('is_active', true);

      for (final lesson in lessons) {
        final lessonGroups = await _supabase
            .from('discussion_groups')
            .select('''
              *,
              lessons (title, id)
            ''')
            .eq('lesson_id', lesson['id'])
            .eq('is_active', true);

        for (final group in lessonGroups) {
          final alreadyAdded = accessibleGroups.any((g) => g['id'] == group['id']);
          if (!alreadyAdded) {
            accessibleGroups.add({
              ...group,
              'access_level': 'lesson',
              'parent_info': group['lessons'],
            });
          }
        }
      }
    }

    // Get lesson-level groups (purchased individually)
    final lessonPurchases = await _supabase
        .from('purchases')
        .select('lesson_id')
        .eq('user_id', userId)
        .eq('purchase_type', 'lesson')
        .eq('payment_status', 'completed');

    for (final purchase in lessonPurchases) {
      final lessonGroups = await _supabase
          .from('discussion_groups')
          .select('''
            *,
            lessons (title, id)
          ''')
          .eq('lesson_id', purchase['lesson_id'])
          .eq('is_active', true);

      for (final group in lessonGroups) {
        final alreadyAdded = accessibleGroups.any((g) => g['id'] == group['id']);
        if (!alreadyAdded) {
          accessibleGroups.add({
            ...group,
            'access_level': 'lesson',
            'parent_info': group['lessons'],
          });
        }
      }
    }

    return accessibleGroups;
  }

  // Get posts in a discussion group
  static Future<List<Map<String, dynamic>>> getDiscussionPosts(
    String userId,
    String groupId, {
    int limit = 20,
    int offset = 0,
  }) async {
    // Check access first
    final hasAccess = await hasAccessToDiscussionGroup(userId, groupId);
    if (!hasAccess) {
      throw Exception('Access denied to this discussion group');
    }

    return await _supabase
        .from('discussion_posts')
        .select('''
          *,
          users (id, full_name, avatar_url),
          post_votes (user_id, is_useful)
        ''')
        .eq('discussion_group_id', groupId)
        .is_('parent_post_id', null) // Only top-level posts
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
  }

  // Get replies to a post
  static Future<List<Map<String, dynamic>>> getPostReplies(
    String userId,
    String postId,
  ) async {
    // Get the post to check discussion group access
    final post = await _supabase
        .from('discussion_posts')
        .select('discussion_group_id')
        .eq('id', postId)
        .single();

    final hasAccess = await hasAccessToDiscussionGroup(userId, post['discussion_group_id']);
    if (!hasAccess) {
      throw Exception('Access denied to this discussion');
    }

    return await _supabase
        .from('discussion_posts')
        .select('''
          *,
          users (id, full_name, avatar_url),
          post_votes (user_id, is_useful)
        ''')
        .eq('parent_post_id', postId)
        .order('created_at', ascending: true);
  }

  // Create a new discussion post
  static Future<Map<String, dynamic>> createPost(
    String userId,
    String groupId,
    String title,
    String content, {
    bool isQuestion = false,
    String? parentPostId,
  }) async {
    try {
      // Check access
      final hasAccess = await hasAccessToDiscussionGroup(userId, groupId);
      if (!hasAccess) {
        return {'success': false, 'message': 'Access denied to this discussion group'};
      }

      final response = await _supabase
          .from('discussion_posts')
          .insert({
            'discussion_group_id': groupId,
            'user_id': userId,
            'parent_post_id': parentPostId,
            'title': parentPostId == null ? title : null, // Only top-level posts have titles
            'content': content,
            'is_question': isQuestion,
            'is_answer': parentPostId != null && isQuestion, // Reply to question could be answer
          })
          .select()
          .single();

      return {
        'success': true,
        'post': response,
        'message': parentPostId == null ? 'Post created successfully' : 'Reply posted successfully'
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to create post: $e'};
    }
  }

  // Update a post
  static Future<Map<String, dynamic>> updatePost(
    String userId,
    String postId,
    String content, {
    String? title,
  }) async {
    try {
      // Check if user owns the post
      final post = await _supabase
          .from('discussion_posts')
          .select('user_id, discussion_group_id')
          .eq('id', postId)
          .single();

      if (post['user_id'] != userId) {
        return {'success': false, 'message': 'You can only edit your own posts'};
      }

      // Check access to discussion group
      final hasAccess = await hasAccessToDiscussionGroup(userId, post['discussion_group_id']);
      if (!hasAccess) {
        return {'success': false, 'message': 'Access denied'};
      }

      final updateData = <String, dynamic>{'content': content};
      if (title != null) updateData['title'] = title;

      await _supabase
          .from('discussion_posts')
          .update(updateData)
          .eq('id', postId);

      return {'success': true, 'message': 'Post updated successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update post: $e'};
    }
  }

  // Delete a post
  static Future<Map<String, dynamic>> deletePost(
    String userId,
    String postId,
  ) async {
    try {
      // Check if user owns the post
      final post = await _supabase
          .from('discussion_posts')
          .select('user_id, discussion_group_id')
          .eq('id', postId)
          .single();

      if (post['user_id'] != userId) {
        return {'success': false, 'message': 'You can only delete your own posts'};
      }

      // Check access to discussion group
      final hasAccess = await hasAccessToDiscussionGroup(userId, post['discussion_group_id']);
      if (!hasAccess) {
        return {'success': false, 'message': 'Access denied'};
      }

      await _supabase
          .from('discussion_posts')
          .delete()
          .eq('id', postId);

      return {'success': true, 'message': 'Post deleted successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete post: $e'};
    }
  }

  // Vote on a post (mark as useful)
  static Future<Map<String, dynamic>> voteOnPost(
    String userId,
    String postId,
    bool isUseful,
  ) async {
    try {
      // Get the post to check discussion group access
      final post = await _supabase
          .from('discussion_posts')
          .select('discussion_group_id, user_id')
          .eq('id', postId)
          .single();

      // Check access to discussion group
      final hasAccess = await hasAccessToDiscussionGroup(userId, post['discussion_group_id']);
      if (!hasAccess) {
        return {'success': false, 'message': 'Access denied'};
      }

      // Users cannot vote on their own posts
      if (post['user_id'] == userId) {
        return {'success': false, 'message': 'You cannot vote on your own post'};
      }

      // Check if user already voted
      final existingVote = await _supabase
          .from('post_votes')
          .select('id, is_useful')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingVote != null) {
        if (existingVote['is_useful'] == isUseful) {
          return {'success': false, 'message': 'You already voted this way'};
        }
        
        // Update existing vote
        await _supabase
            .from('post_votes')
            .update({'is_useful': isUseful})
            .eq('id', existingVote['id']);
      } else {
        // Create new vote
        await _supabase
            .from('post_votes')
            .insert({
              'post_id': postId,
              'user_id': userId,
              'is_useful': isUseful,
            });
      }

      return {
        'success': true,
        'message': isUseful ? 'Post marked as useful' : 'Post marked as not useful'
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to vote on post: $e'};
    }
  }

  // Get user's vote on a post
  static Future<bool?> getUserVoteOnPost(String userId, String postId) async {
    try {
      final vote = await _supabase
          .from('post_votes')
          .select('is_useful')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      return vote?['is_useful'];
    } catch (e) {
      return null;
    }
  }

  // Search posts in accessible discussion groups
  static Future<List<Map<String, dynamic>>> searchPosts(
    String userId,
    String query, {
    int limit = 20,
  }) async {
    // Get accessible discussion groups
    final accessibleGroups = await getAccessibleDiscussionGroups(userId);
    final groupIds = accessibleGroups.map((g) => g['id']).toList();

    if (groupIds.isEmpty) return [];

    return await _supabase
        .from('discussion_posts')
        .select('''
          *,
          users (id, full_name, avatar_url),
          discussion_groups (name, course_id, module_id, lesson_id)
        ''')
        .in_('discussion_group_id', groupIds)
        .or('title.ilike.%$query%,content.ilike.%$query%')
        .order('created_at', ascending: false)
        .limit(limit);
  }

  // Get popular posts (most useful votes)
  static Future<List<Map<String, dynamic>>> getPopularPosts(
    String userId, {
    int limit = 10,
  }) async {
    // Get accessible discussion groups
    final accessibleGroups = await getAccessibleDiscussionGroups(userId);
    final groupIds = accessibleGroups.map((g) => g['id']).toList();

    if (groupIds.isEmpty) return [];

    return await _supabase
        .from('discussion_posts')
        .select('''
          *,
          users (id, full_name, avatar_url),
          discussion_groups (name, course_id, module_id, lesson_id)
        ''')
        .in_('discussion_group_id', groupIds)
        .gte('useful_votes', 1)
        .order('useful_votes', ascending: false)
        .limit(limit);
  }

  // Get user's posts
  static Future<List<Map<String, dynamic>>> getUserPosts(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    return await _supabase
        .from('discussion_posts')
        .select('''
          *,
          discussion_groups (name, course_id, module_id, lesson_id)
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
  }

  // Pin/unpin a post (admin function)
  static Future<Map<String, dynamic>> pinPost(
    String userId,
    String postId,
    bool isPinned,
  ) async {
    try {
      // In a real app, you'd check if user has admin privileges
      // For now, we'll allow any user to pin their own posts
      final post = await _supabase
          .from('discussion_posts')
          .select('user_id')
          .eq('id', postId)
          .single();

      if (post['user_id'] != userId) {
        return {'success': false, 'message': 'You can only pin your own posts'};
      }

      await _supabase
          .from('discussion_posts')
          .update({'is_pinned': isPinned})
          .eq('id', postId);

      return {
        'success': true,
        'message': isPinned ? 'Post pinned' : 'Post unpinned'
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to pin post: $e'};
    }
  }
}