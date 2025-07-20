class DiscussionGroup {
  final String id;
  final String? courseId;
  final String? moduleId;
  final String? lessonId;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final String accessLevel;
  final Map<String, dynamic>? parentInfo;

  DiscussionGroup({
    required this.id,
    this.courseId,
    this.moduleId,
    this.lessonId,
    required this.name,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.accessLevel,
    this.parentInfo,
  });

  factory DiscussionGroup.fromJson(Map<String, dynamic> json) {
    return DiscussionGroup(
      id: json['id'],
      courseId: json['course_id'],
      moduleId: json['module_id'],
      lessonId: json['lesson_id'],
      name: json['name'],
      description: json['description'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      accessLevel: json['access_level'] ?? 'unknown',
      parentInfo: json['parent_info'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'module_id': moduleId,
      'lesson_id': lessonId,
      'name': name,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'access_level': accessLevel,
      'parent_info': parentInfo,
    };
  }
}

class DiscussionPost {
  final String id;
  final String discussionGroupId;
  final String userId;
  final String? parentPostId;
  final String? title;
  final String content;
  final bool isQuestion;
  final bool isAnswer;
  final bool isPinned;
  final int usefulVotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final UserInfo? user;
  final List<PostVote>? votes;
  final List<DiscussionPost>? replies;
  final DiscussionGroup? discussionGroup;

  DiscussionPost({
    required this.id,
    required this.discussionGroupId,
    required this.userId,
    this.parentPostId,
    this.title,
    required this.content,
    required this.isQuestion,
    required this.isAnswer,
    required this.isPinned,
    required this.usefulVotes,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.votes,
    this.replies,
    this.discussionGroup,
  });

  factory DiscussionPost.fromJson(Map<String, dynamic> json) {
    return DiscussionPost(
      id: json['id'],
      discussionGroupId: json['discussion_group_id'],
      userId: json['user_id'],
      parentPostId: json['parent_post_id'],
      title: json['title'],
      content: json['content'],
      isQuestion: json['is_question'] ?? false,
      isAnswer: json['is_answer'] ?? false,
      isPinned: json['is_pinned'] ?? false,
      usefulVotes: json['useful_votes'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['users'] != null ? UserInfo.fromJson(json['users']) : null,
      votes: json['post_votes'] != null
          ? (json['post_votes'] as List)
              .map((item) => PostVote.fromJson(item))
              .toList()
          : null,
      replies: json['replies'] != null
          ? (json['replies'] as List)
              .map((item) => DiscussionPost.fromJson(item))
              .toList()
          : null,
      discussionGroup: json['discussion_groups'] != null
          ? DiscussionGroup.fromJson(json['discussion_groups'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'discussion_group_id': discussionGroupId,
      'user_id': userId,
      'parent_post_id': parentPostId,
      'title': title,
      'content': content,
      'is_question': isQuestion,
      'is_answer': isAnswer,
      'is_pinned': isPinned,
      'useful_votes': usefulVotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isTopLevelPost => parentPostId == null;
  bool get hasReplies => replies != null && replies!.isNotEmpty;
  
  PostVote? getUserVote(String userId) {
    return votes?.firstWhere(
      (vote) => vote.userId == userId,
      orElse: () => PostVote(
        id: '',
        postId: id,
        userId: userId,
        isUseful: false,
        createdAt: DateTime.now(),
      ),
    );
  }
}

class PostVote {
  final String id;
  final String postId;
  final String userId;
  final bool isUseful;
  final DateTime createdAt;

  PostVote({
    required this.id,
    required this.postId,
    required this.userId,
    required this.isUseful,
    required this.createdAt,
  });

  factory PostVote.fromJson(Map<String, dynamic> json) {
    return PostVote(
      id: json['id'],
      postId: json['post_id'],
      userId: json['user_id'],
      isUseful: json['is_useful'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'is_useful': isUseful,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class UserInfo {
  final String id;
  final String fullName;
  final String? avatarUrl;

  UserInfo({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
    };
  }
}

class TrendingDiscussion {
  final String discussionGroupId;
  final String groupName;
  final int postsCount;
  final DateTime recentActivity;

  TrendingDiscussion({
    required this.discussionGroupId,
    required this.groupName,
    required this.postsCount,
    required this.recentActivity,
  });

  factory TrendingDiscussion.fromJson(Map<String, dynamic> json) {
    return TrendingDiscussion(
      discussionGroupId: json['discussion_group_id'],
      groupName: json['group_name'],
      postsCount: json['posts_count'],
      recentActivity: DateTime.parse(json['recent_activity']),
    );
  }
}

class DiscussionSearchResult {
  final List<DiscussionPost> posts;
  final String query;
  final int totalResults;

  DiscussionSearchResult({
    required this.posts,
    required this.query,
    required this.totalResults,
  });

  factory DiscussionSearchResult.fromJson(Map<String, dynamic> json) {
    return DiscussionSearchResult(
      posts: (json['posts'] as List)
          .map((item) => DiscussionPost.fromJson(item))
          .toList(),
      query: json['query'],
      totalResults: json['total_results'],
    );
  }
}

// Enum for discussion post types
enum PostType {
  discussion,
  question,
  announcement,
  answer,
}

// Enum for discussion access levels
enum AccessLevel {
  course,
  module,
  lesson,
}

// Helper class for creating new posts
class CreatePostRequest {
  final String discussionGroupId;
  final String title;
  final String content;
  final bool isQuestion;
  final String? parentPostId;

  CreatePostRequest({
    required this.discussionGroupId,
    required this.title,
    required this.content,
    required this.isQuestion,
    this.parentPostId,
  });

  Map<String, dynamic> toJson() {
    return {
      'discussion_group_id': discussionGroupId,
      'title': title,
      'content': content,
      'is_question': isQuestion,
      'parent_post_id': parentPostId,
    };
  }
}

// Helper class for updating posts
class UpdatePostRequest {
  final String content;
  final String? title;

  UpdatePostRequest({
    required this.content,
    this.title,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      if (title != null) 'title': title,
    };
  }
}

// Helper class for discussion statistics
class DiscussionStats {
  final int totalPosts;
  final int totalQuestions;
  final int totalAnswers;
  final int totalUsefulVotes;
  final int activeUsers;
  final DateTime lastActivity;

  DiscussionStats({
    required this.totalPosts,
    required this.totalQuestions,
    required this.totalAnswers,
    required this.totalUsefulVotes,
    required this.activeUsers,
    required this.lastActivity,
  });

  factory DiscussionStats.fromJson(Map<String, dynamic> json) {
    return DiscussionStats(
      totalPosts: json['total_posts'],
      totalQuestions: json['total_questions'],
      totalAnswers: json['total_answers'],
      totalUsefulVotes: json['total_useful_votes'],
      activeUsers: json['active_users'],
      lastActivity: DateTime.parse(json['last_activity']),
    );
  }
}

// Helper class for creating new discussion groups
class CreateDiscussionGroupRequest {
  final String? courseId;
  final String? moduleId;
  final String? lessonId;
  final String name;
  final String? description;

  CreateDiscussionGroupRequest({
    this.courseId,
    this.moduleId,
    this.lessonId,
    required this.name,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'module_id': moduleId,
      'lesson_id': lessonId,
      'name': name,
      'description': description,
    };
  }
}

// Helper class for updating discussion groups
class UpdateDiscussionGroupRequest {
  final String? name;
  final String? description;
  final bool? isActive;

  UpdateDiscussionGroupRequest({
    this.name,
    this.description,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (isActive != null) 'is_active': isActive,
    };
  }
}

// Helper class for content items (courses, modules, lessons)
class ContentItem {
  final String id;
  final String title;
  final String type; // 'course', 'module', 'lesson'

  ContentItem({
    required this.id,
    required this.title,
    required this.type,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'],
      title: json['title'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
    };
  }
}

// Discussion filter options
class DiscussionFilter {
  final String? contentType;
  final String? contentId;
  final bool questionsOnly;
  final String? sortBy; // 'recent', 'popular', 'helpful'

  DiscussionFilter({
    this.contentType,
    this.contentId,
    this.questionsOnly = false,
    this.sortBy = 'recent',
  });
}