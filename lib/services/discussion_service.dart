import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/discussion_models.dart';

class DiscussionService {
  static final DiscussionService _instance = DiscussionService._internal();
  factory DiscussionService() => _instance;
  DiscussionService._internal();

  static SupabaseClient get _client => SupabaseService.client;

  // Get discussion groups the user has access to
  static Future<List<DiscussionGroup>> getAccessibleDiscussionGroups() async {
    return await SupabaseService.requireAuth((userId) async {
      final groups = <DiscussionGroup>[];

      // Get course-level discussions using database function
      final coursePurchases = await _client
          .from('purchases')
          .select('course_id')
          .eq('user_id', userId)
          .eq('purchase_type', 'course')
          .eq('payment_status', 'completed');

      for (final purchase in coursePurchases) {
        final courseGroups = await _client
            .from('discussion_groups')
            .select('*')
            .eq('course_id', purchase['course_id'])
            .eq('is_active', true);

        for (final groupData in courseGroups) {
          groups.add(DiscussionGroup.fromJson({
            ...groupData,
            'access_level': 'course',
            'parent_info': {'id': purchase['course_id'], 'type': 'course'},
          }));
        }
      }

      // Get module-level discussions
      final modulePurchases = await _client
          .from('purchases')
          .select('module_id')
          .eq('user_id', userId)
          .eq('purchase_type', 'module')
          .eq('payment_status', 'completed');

      for (final purchase in modulePurchases) {
        final moduleGroups = await _client
            .from('discussion_groups')
            .select('*')
            .eq('module_id', purchase['module_id'])
            .eq('is_active', true);

        for (final groupData in moduleGroups) {
          groups.add(DiscussionGroup.fromJson({
            ...groupData,
            'access_level': 'module',
            'parent_info': {'id': purchase['module_id'], 'type': 'module'},
          }));
        }
      }

      // Get lesson-level discussions
      final lessonPurchases = await _client
          .from('purchases')
          .select('lesson_id')
          .eq('user_id', userId)
          .eq('purchase_type', 'lesson')
          .eq('payment_status', 'completed');

      for (final purchase in lessonPurchases) {
        final lessonGroups = await _client
            .from('discussion_groups')
            .select('*')
            .eq('lesson_id', purchase['lesson_id'])
            .eq('is_active', true);

        for (final groupData in lessonGroups) {
          groups.add(DiscussionGroup.fromJson({
            ...groupData,
            'access_level': 'lesson',
            'parent_info': {'id': purchase['lesson_id'], 'type': 'lesson'},
          }));
        }
      }

      return groups;
    }) ?? [];
  }

  // Check if user has access to a discussion group using database functions
  static Future<bool> hasAccessToDiscussionGroup(String groupId) async {
    return await SupabaseService.requireAuth((userId) async {
      // Get the discussion group info
      final group = await _client
          .from('discussion_groups')
          .select('course_id, module_id, lesson_id')
          .eq('id', groupId)
          .single();

      // Check access based on type using database functions
      if (group['course_id'] != null) {
        final result = await _client
            .rpc('user_has_course_access', params: {
              'user_uuid': userId,
              'course_uuid': group['course_id'],
            });
        return result ?? false;
      } else if (group['module_id'] != null) {
        final result = await _client
            .rpc('user_has_module_access', params: {
              'user_uuid': userId,
              'module_uuid': group['module_id'],
            });
        return result ?? false;
      } else if (group['lesson_id'] != null) {
        final result = await _client
            .rpc('user_has_lesson_access', params: {
              'user_uuid': userId,
              'lesson_uuid': group['lesson_id'],
            });
        return result ?? false;
      }

      return false;
    }) ?? false;
  }

  // Get posts for a discussion group
  static Future<List<DiscussionPost>> getDiscussionPosts(
    String groupId, {
    int limit = 20,
    int offset = 0,
    bool includeReplies = true,
  }) async {
    // Check access first
    final hasAccess = await hasAccessToDiscussionGroup(groupId);
    if (!hasAccess) {
      return [];
    }

    return await SupabaseService.safeExecute(() async {
      var query = _client
          .from('discussion_posts')
          .select('''
            id, discussion_group_id, user_id, parent_post_id, title, content,
            is_question, is_answer, is_pinned, useful_votes, created_at, updated_at,
            users (id, full_name, avatar_url),
            post_votes (id, user_id, is_useful, created_at)
          ''')
          .eq('discussion_group_id', groupId);

      if (!includeReplies) {
        query = query.is_('parent_post_id', null);
      }

      final response = await query
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((item) => DiscussionPost.fromJson(item)).toList();
    }) ?? [];
  }

  // Get replies for a specific post
  static Future<List<DiscussionPost>> getPostReplies(String postId) async {
    return await SupabaseService.safeExecute(() async {
      final response = await _client
          .from('discussion_posts')
          .select('''
            id, discussion_group_id, user_id, parent_post_id, title, content,
            is_question, is_answer, is_pinned, useful_votes, created_at, updated_at,
            users (id, full_name, avatar_url),
            post_votes (id, user_id, is_useful, created_at)
          ''')
          .eq('parent_post_id', postId)
          .order('created_at', ascending: true);

      return response.map((item) => DiscussionPost.fromJson(item)).toList();
    }) ?? [];
  }

  // Create a new post
  static Future<String?> createPost(CreatePostRequest request) async {
    return await SupabaseService.requireAuth((userId) async {
      // Check if user has access to the discussion group
      final hasAccess = await hasAccessToDiscussionGroup(request.discussionGroupId);
      if (!hasAccess) {
        throw Exception('You do not have access to this discussion group');
      }

      final response = await _client
          .from('discussion_posts')
          .insert({
            'discussion_group_id': request.discussionGroupId,
            'user_id': userId,
            'parent_post_id': request.parentPostId,
            'title': request.title,
            'content': request.content,
            'is_question': request.isQuestion,
            'is_answer': request.parentPostId != null && !request.isQuestion,
          })
          .select('id')
          .single();

      return response['id'] as String;
    });
  }

  // Update a post
  static Future<bool> updatePost(String postId, UpdatePostRequest request) async {
    return await SupabaseService.requireAuth((userId) async {
      await _client
          .from('discussion_posts')
          .update(request.toJson())
          .eq('id', postId)
          .eq('user_id', userId); // Ensure user owns the post

      return true;
    }) ?? false;
  }

  // Delete a post
  static Future<bool> deletePost(String postId) async {
    return await SupabaseService.requireAuth((userId) async {
      await _client
          .from('discussion_posts')
          .delete()
          .eq('id', postId)
          .eq('user_id', userId); // Ensure user owns the post

      return true;
    }) ?? false;
  }

  // Vote on a post (mark as useful or not)
  static Future<bool> voteOnPost(String postId, bool isUseful) async {
    return await SupabaseService.requireAuth((userId) async {
      // Check if user already voted
      final existingVote = await _client
          .from('post_votes')
          .select('id, is_useful')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingVote != null) {
        // Update existing vote
        await _client
            .from('post_votes')
            .update({'is_useful': isUseful})
            .eq('id', existingVote['id']);
      } else {
        // Create new vote
        await _client
            .from('post_votes')
            .insert({
              'post_id': postId,
              'user_id': userId,
              'is_useful': isUseful,
            });
      }

      return true;
    }) ?? false;
  }

  // Remove vote from a post
  static Future<bool> removeVote(String postId) async {
    return await SupabaseService.requireAuth((userId) async {
      await _client
          .from('post_votes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);

      return true;
    }) ?? false;
  }

  // Search discussions
  static Future<DiscussionSearchResult> searchDiscussions(
    String query, {
    int limit = 20,
  }) async {
    return await SupabaseService.requireAuth((userId) async {
      // Get accessible groups first
      final accessibleGroups = await getAccessibleDiscussionGroups();
      final groupIds = accessibleGroups.map((g) => g.id).toList();

      if (groupIds.isEmpty) {
        return DiscussionSearchResult(
          posts: [],
          query: query,
          totalResults: 0,
        );
      }

      // Search posts in accessible groups
      final response = await _client
          .from('discussion_posts')
          .select('''
            id, discussion_group_id, user_id, parent_post_id, title, content,
            is_question, is_answer, is_pinned, useful_votes, created_at, updated_at,
            users (id, full_name, avatar_url),
            discussion_groups (id, name)
          ''')
          .inFilter('discussion_group_id', groupIds)
          .or('title.ilike.%$query%,content.ilike.%$query%')
          .order('created_at', ascending: false)
          .limit(limit);

      final posts = response.map((item) => DiscussionPost.fromJson(item)).toList();

      return DiscussionSearchResult(
        posts: posts,
        query: query,
        totalResults: posts.length,
      );
    }) ?? DiscussionSearchResult(
      posts: [],
      query: query,
      totalResults: 0,
    );
  }

  // Get user's own posts
  static Future<List<DiscussionPost>> getUserPosts({int limit = 20}) async {
    return await SupabaseService.requireAuth((userId) async {
      final response = await _client
          .from('discussion_posts')
          .select('''
            id, discussion_group_id, user_id, parent_post_id, title, content,
            is_question, is_answer, is_pinned, useful_votes, created_at, updated_at,
            discussion_groups (id, name),
            post_votes (id, user_id, is_useful, created_at)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((item) => DiscussionPost.fromJson(item)).toList();
    }) ?? [];
  }
}