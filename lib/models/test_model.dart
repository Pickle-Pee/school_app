// models/test_model.dart

import 'question_model.dart';

class TestModel {
  final int id;
  final String title;
  final String? description;
  final List<QuestionModel> questions;

  /// Доп. поля
  final int? grade;
  final int? classId;
  final String? subject;
  final int? topicId;
  final String? type;
  final int? maxAttempts;
  final bool? published;
  final int? attemptsUsed;
  final int? attemptsLeft;
  final int? lastGrade;

  TestModel({
    required this.id,
    required this.title,
    this.description,
    required this.questions,
    this.grade,
    this.classId,
    this.subject,
    this.topicId,
    this.type,
    this.maxAttempts,
    this.published,
    this.attemptsUsed,
    this.attemptsLeft,
    this.lastGrade,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) {
    final questionsJson = (json['questions'] as List<dynamic>?) ?? [];

    return TestModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      questions: questionsJson
          .whereType<Map<String, dynamic>>()
          .map(QuestionModel.fromJson)
          .toList(),

      grade: json['grade'] as int?,

      // поддержка snake_case и camelCase
      classId: json['class_id'] as int? ?? json['classId'] as int?,
      subject: json['subject'] as String?,
      topicId: json['topic_id'] as int? ?? json['topicId'] as int?,
      type: json['type'] as String?,

      maxAttempts:
          json['max_attempts'] as int? ?? json['maxAttempts'] as int?,
      published: json['published'] as bool?,

      attemptsUsed:
          json['attempts_used'] as int? ?? json['attemptsUsed'] as int?,
      attemptsLeft:
          json['attempts_left'] as int? ?? json['attemptsLeft'] as int?,
      lastGrade: json['last_grade'] as int? ?? json['lastGrade'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),

      'grade': grade,
      'class_id': classId,
      'subject': subject,
      'topic_id': topicId,
      'type': type,
      'max_attempts': maxAttempts,
      'published': published,
      'attempts_used': attemptsUsed,
      'attempts_left': attemptsLeft,
      'last_grade': lastGrade,
    };
  }
}
