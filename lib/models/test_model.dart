// models/test_model.dart

import 'question_model.dart';

class TestModel {
  final int id;
  final String title;
  final String? description;
  final List<QuestionModel> questions;

  /// Новые поля (если нужно хранить класс и предмет)
  final int? grade;
  final String? subject;

  TestModel({
    required this.id,
    required this.title,
    this.description,
    required this.questions,
    this.grade,
    this.subject,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) {
    // Безопасно достаём список вопросов
    final questionsJson = json['questions'] as List<dynamic>? ?? [];

    return TestModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      questions: questionsJson
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),

      // Если на бэкенде есть поля 'grade' и 'subject'
      grade: json['grade'] as int?,
      subject: json['subject'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),

      // Если нужно отправлять grade/subject
      'grade': grade,
      'subject': subject,
    };
  }
}
