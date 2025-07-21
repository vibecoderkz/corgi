class UserProgress {
  final String? currentCourse;
  final String? currentModule;
  final String? nextLesson;
  final double progressPercentage;
  final bool hasActiveCourse;

  UserProgress({
    this.currentCourse,
    this.currentModule,
    this.nextLesson,
    this.progressPercentage = 0.0,
    this.hasActiveCourse = false,
  });

  static UserProgress mock() {
    return UserProgress(
      currentCourse: "Основы машинного обучения",
      currentModule: "Модуль 2: Supervised Learning",
      nextLesson: "Урок 3: Линейная регрессия",
      progressPercentage: 65.0,
      hasActiveCourse: true,
    );
  }
}

class WeeklyGoal {
  final String title;
  final String description;
  final int currentProgress;
  final int targetProgress;
  final bool isCompleted;

  WeeklyGoal({
    required this.title,
    required this.description,
    required this.currentProgress,
    required this.targetProgress,
    this.isCompleted = false,
  });

  double get progressPercentage => 
      (currentProgress / targetProgress * 100).clamp(0, 100);

  static List<WeeklyGoal> mockGoals() {
    return [
      WeeklyGoal(
        title: "Пройти 2 урока",
        description: "Завершить 2 урока в текущей неделе",
        currentProgress: 1,
        targetProgress: 2,
      ),
      WeeklyGoal(
        title: "Заработать 100 баллов",
        description: "Получить 100 баллов за активность",
        currentProgress: 75,
        targetProgress: 100,
      ),
    ];
  }
}

class Course {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double rating;
  final int lessonsCount;
  final String difficulty;
  final bool isEnrolled;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.lessonsCount,
    required this.difficulty,
    this.isEnrolled = false,
  });

  static List<Course> mockCourses() {
    return [
      Course(
        id: "1",
        title: "ChatGPT для начинающих",
        description: "Изучите основы работы с ChatGPT",
        imageUrl: "https://via.placeholder.com/150",
        rating: 4.8,
        lessonsCount: 12,
        difficulty: "Начинающий",
      ),
      Course(
        id: "2",
        title: "Создание изображений с DALL-E",
        description: "Генерация изображений с помощью ИИ",
        imageUrl: "https://via.placeholder.com/150",
        rating: 4.6,
        lessonsCount: 8,
        difficulty: "Средний",
      ),
      Course(
        id: "3",
        title: "Автоматизация с помощью ИИ",
        description: "Автоматизируйте рутинные задачи",
        imageUrl: "https://via.placeholder.com/150",
        rating: 4.9,
        lessonsCount: 15,
        difficulty: "Продвинутый",
      ),
    ];
  }
}

class NewsItem {
  final String id;
  final String title;
  final String summary;
  final String url;
  final DateTime publishedAt;
  final String source;

  NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.url,
    required this.publishedAt,
    required this.source,
  });

  static List<NewsItem> mockNews() {
    return [
      NewsItem(
        id: "1",
        title: "OpenAI представила GPT-5",
        summary: "Новая модель показывает значительные улучшения в понимании контекста",
        url: "https://example.com/news/1",
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
        source: "TechCrunch",
      ),
      NewsItem(
        id: "2",
        title: "Google запустил Gemini 2.0",
        summary: "Обновленная модель превосходит предыдущие версии",
        url: "https://example.com/news/2",
        publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
        source: "The Verge",
      ),
      NewsItem(
        id: "3",
        title: "ИИ в медицине: новые достижения",
        summary: "Искусственный интеллект помогает в диагностике заболеваний",
        url: "https://example.com/news/3",
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        source: "MIT Technology Review",
      ),
    ];
  }
}

class CommunityProject {
  final String id;
  final String title;
  final String authorName;
  final String authorAvatar;
  final String previewImage;
  final int likesCount;
  final String category;

  CommunityProject({
    required this.id,
    required this.title,
    required this.authorName,
    required this.authorAvatar,
    required this.previewImage,
    required this.likesCount,
    required this.category,
  });

  static List<CommunityProject> mockProjects() {
    return [
      CommunityProject(
        id: "1",
        title: "Чат-бот для кофейни",
        authorName: "Анна К.",
        authorAvatar: "https://via.placeholder.com/40",
        previewImage: "https://via.placeholder.com/200",
        likesCount: 24,
        category: "ChatGPT",
      ),
      CommunityProject(
        id: "2",
        title: "Генератор логотипов",
        authorName: "Максим П.",
        authorAvatar: "https://via.placeholder.com/40",
        previewImage: "https://via.placeholder.com/200",
        likesCount: 31,
        category: "DALL-E",
      ),
      CommunityProject(
        id: "3",
        title: "Анализ данных продаж",
        authorName: "Елена М.",
        authorAvatar: "https://via.placeholder.com/40",
        previewImage: "https://via.placeholder.com/200",
        likesCount: 18,
        category: "Аналитика",
      ),
    ];
  }
}

class UserStats {
  final int coursesCompleted;
  final int totalCourses;
  final int lessonsCompleted;
  final int modulesCompleted;
  final int totalModules;
  final int totalLearningMinutes;
  final int userRank;
  final int streak;

  UserStats({
    required this.coursesCompleted,
    required this.totalCourses,
    required this.lessonsCompleted,
    required this.modulesCompleted,
    required this.totalModules,
    required this.totalLearningMinutes,
    required this.userRank,
    required this.streak,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      coursesCompleted: json['courses_count'] ?? 0,
      totalCourses: json['total_courses'] ?? 0,
      lessonsCompleted: json['lessons_completed'] ?? 0,
      modulesCompleted: json['modules_completed'] ?? 0,
      totalModules: json['total_modules'] ?? 0,
      totalLearningMinutes: json['total_learning_minutes'] ?? 0,
      userRank: json['user_rank'] ?? 0,
      streak: json['streak'] ?? 0,
    );
  }

  static UserStats defaultStats() {
    return UserStats(
      coursesCompleted: 0,
      totalCourses: 0,
      lessonsCompleted: 0,
      modulesCompleted: 0,
      totalModules: 0,
      totalLearningMinutes: 0,
      userRank: 0,
      streak: 0,
    );
  }
}

class LeaderboardEntry {
  final String userId;
  final String userName;
  final String userAvatar;
  final int points;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.points,
    required this.rank,
  });

  static List<LeaderboardEntry> mockLeaderboard() {
    return [
      LeaderboardEntry(
        userId: "1",
        userName: "Александр И.",
        userAvatar: "https://via.placeholder.com/40",
        points: 2450,
        rank: 1,
      ),
      LeaderboardEntry(
        userId: "2",
        userName: "Мария С.",
        userAvatar: "https://via.placeholder.com/40",
        points: 2200,
        rank: 2,
      ),
      LeaderboardEntry(
        userId: "3",
        userName: "Дмитрий К.",
        userAvatar: "https://via.placeholder.com/40",
        points: 1980,
        rank: 3,
      ),
    ];
  }
}