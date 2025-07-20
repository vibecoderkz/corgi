class Purchase {
  final String id;
  final String userId;
  final PurchaseType purchaseType;
  final String? courseId;
  final String? moduleId;
  final String? lessonId;
  final double amount;
  final String paymentMethod;
  final String paymentStatus;
  final String? transactionId;
  final DateTime purchasedAt;
  final DateTime? expiresAt;

  // Related data
  final CourseInfo? course;
  final ModuleInfo? module;
  final LessonInfo? lesson;

  Purchase({
    required this.id,
    required this.userId,
    required this.purchaseType,
    this.courseId,
    this.moduleId,
    this.lessonId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.transactionId,
    required this.purchasedAt,
    this.expiresAt,
    this.course,
    this.module,
    this.lesson,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'],
      userId: json['user_id'],
      purchaseType: PurchaseType.values.firstWhere(
        (e) => e.name == json['purchase_type'],
      ),
      courseId: json['course_id'],
      moduleId: json['module_id'],
      lessonId: json['lesson_id'],
      amount: double.parse(json['amount'].toString()),
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
      transactionId: json['transaction_id'],
      purchasedAt: DateTime.parse(json['purchased_at']),
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'])
          : null,
      course: json['courses'] != null 
          ? CourseInfo.fromJson(json['courses'])
          : null,
      module: json['modules'] != null 
          ? ModuleInfo.fromJson(json['modules'])
          : null,
      lesson: json['lessons'] != null 
          ? LessonInfo.fromJson(json['lessons'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'purchase_type': purchaseType.name,
      'course_id': courseId,
      'module_id': moduleId,
      'lesson_id': lessonId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'transaction_id': transactionId,
      'purchased_at': purchasedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}

enum PurchaseType { course, module, lesson }

class CourseInfo {
  final String id;
  final String title;
  final double price;

  CourseInfo({
    required this.id,
    required this.title,
    required this.price,
  });

  factory CourseInfo.fromJson(Map<String, dynamic> json) {
    return CourseInfo(
      id: json['id'],
      title: json['title'],
      price: double.parse(json['price'].toString()),
    );
  }
}

class ModuleInfo {
  final String id;
  final String title;
  final double price;

  ModuleInfo({
    required this.id,
    required this.title,
    required this.price,
  });

  factory ModuleInfo.fromJson(Map<String, dynamic> json) {
    return ModuleInfo(
      id: json['id'],
      title: json['title'],
      price: double.parse(json['price'].toString()),
    );
  }
}

class LessonInfo {
  final String id;
  final String title;
  final double price;

  LessonInfo({
    required this.id,
    required this.title,
    required this.price,
  });

  factory LessonInfo.fromJson(Map<String, dynamic> json) {
    return LessonInfo(
      id: json['id'],
      title: json['title'],
      price: double.parse(json['price'].toString()),
    );
  }
}

class UserProgress {
  final String id;
  final String userId;
  final String? lessonId;
  final String? moduleId;
  final String? courseId;
  final String progressType;
  final double progressPercentage;
  final int pointsEarned;
  final DateTime? completedAt;
  final DateTime createdAt;

  UserProgress({
    required this.id,
    required this.userId,
    this.lessonId,
    this.moduleId,
    this.courseId,
    required this.progressType,
    required this.progressPercentage,
    required this.pointsEarned,
    this.completedAt,
    required this.createdAt,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      id: json['id'],
      userId: json['user_id'],
      lessonId: json['lesson_id'],
      moduleId: json['module_id'],
      courseId: json['course_id'],
      progressType: json['progress_type'],
      progressPercentage: double.parse(json['progress_percentage'].toString()),
      pointsEarned: json['points_earned'],
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class PointsTransaction {
  final String id;
  final String userId;
  final int points;
  final String transactionType;
  final String? referenceId;
  final String? description;
  final DateTime createdAt;

  PointsTransaction({
    required this.id,
    required this.userId,
    required this.points,
    required this.transactionType,
    this.referenceId,
    this.description,
    required this.createdAt,
  });

  factory PointsTransaction.fromJson(Map<String, dynamic> json) {
    return PointsTransaction(
      id: json['id'],
      userId: json['user_id'],
      points: json['points'],
      transactionType: json['transaction_type'],
      referenceId: json['reference_id'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class UserAchievement {
  final String id;
  final String userId;
  final String achievementType;
  final String achievementName;
  final String? description;
  final int pointsAwarded;
  final DateTime earnedAt;

  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementType,
    required this.achievementName,
    this.description,
    required this.pointsAwarded,
    required this.earnedAt,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'],
      userId: json['user_id'],
      achievementType: json['achievement_type'],
      achievementName: json['achievement_name'],
      description: json['description'],
      pointsAwarded: json['points_awarded'],
      earnedAt: DateTime.parse(json['earned_at']),
    );
  }
}

class PointsSummary {
  final int totalPoints;
  final Map<String, int> breakdown;
  final List<PointsTransaction> recentTransactions;

  PointsSummary({
    required this.totalPoints,
    required this.breakdown,
    required this.recentTransactions,
  });

  factory PointsSummary.fromJson(Map<String, dynamic> json) {
    return PointsSummary(
      totalPoints: json['total_points'],
      breakdown: Map<String, int>.from(json['breakdown']),
      recentTransactions: (json['recent_transactions'] as List)
          .map((item) => PointsTransaction.fromJson(item))
          .toList(),
    );
  }
}

class UserProgressSummary {
  final int totalCoursesPurchased;
  final int totalModulesPurchased;
  final int totalLessonsPurchased;
  final int totalLessonsCompleted;
  final int totalHomeworkCompleted;
  final int totalFinalProjectsCompleted;
  final int totalPoints;
  final int totalUsefulPosts;

  UserProgressSummary({
    required this.totalCoursesPurchased,
    required this.totalModulesPurchased,
    required this.totalLessonsPurchased,
    required this.totalLessonsCompleted,
    required this.totalHomeworkCompleted,
    required this.totalFinalProjectsCompleted,
    required this.totalPoints,
    required this.totalUsefulPosts,
  });

  factory UserProgressSummary.fromJson(Map<String, dynamic> json) {
    return UserProgressSummary(
      totalCoursesPurchased: json['total_courses_purchased'],
      totalModulesPurchased: json['total_modules_purchased'],
      totalLessonsPurchased: json['total_lessons_purchased'],
      totalLessonsCompleted: json['total_lessons_completed'],
      totalHomeworkCompleted: json['total_homework_completed'],
      totalFinalProjectsCompleted: json['total_final_projects_completed'],
      totalPoints: json['total_points'],
      totalUsefulPosts: json['total_useful_posts'],
    );
  }
}