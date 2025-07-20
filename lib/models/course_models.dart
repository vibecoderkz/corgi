class Module {
  final String id;
  final String title;
  final String description;
  final int lessons;
  final double price;
  final String? imageUrl;
  final String? videoPreviewUrl;
  final int studentsCompleted;
  final List<Lesson> lessonsList;
  final FinalProject? finalProject;

  Module({
    required this.id,
    required this.title,
    required this.description,
    required this.lessons,
    required this.price,
    this.imageUrl,
    this.videoPreviewUrl,
    required this.studentsCompleted,
    required this.lessonsList,
    this.finalProject,
  });
}

class Lesson {
  final String id;
  final String title;
  final String description;
  final double price;
  final String contentType;
  final String? contentUrl;
  final int? durationMinutes;
  final Homework? homework;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.contentType,
    this.contentUrl,
    this.durationMinutes,
    this.homework,
  });
}

class Homework {
  final String id;
  final String title;
  final String description;
  final String type;
  final Map<String, dynamic>? questions;
  final Map<String, dynamic>? settings;

  Homework({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.questions,
    this.settings,
  });
}

class FinalProject {
  final String id;
  final String title;
  final String description;
  final String requirements;
  final int estimatedHours;
  final Map<String, dynamic>? rubric;
  final double price;

  FinalProject({
    required this.id,
    required this.title,
    required this.description,
    required this.requirements,
    required this.estimatedHours,
    this.rubric,
    required this.price,
  });
}

class Course {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double price;
  final int duration;
  final String level;
  final String instructor;
  final double rating;
  final int studentsEnrolled;
  final int studentsCompleted;
  final List<Module> modules;
  final String difficulty;
  final String estimatedTime;
  final String? videoPreviewUrl;
  final int studentProjects;
  final int questionsAnswered;
  final List<Module> modulesList;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.duration,
    required this.level,
    required this.instructor,
    required this.rating,
    required this.studentsEnrolled,
    required this.studentsCompleted,
    required this.modules,
    required this.difficulty,
    required this.estimatedTime,
    this.videoPreviewUrl,
    required this.studentProjects,
    required this.questionsAnswered,
    required this.modulesList,
  });
}