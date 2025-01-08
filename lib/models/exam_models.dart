// models/exam_model.dart
class ExamModel {
  final int id;
  final String title;
  final String? description;
  final int? grade; // класс
  final String? subject; // предмет
  final int? timeLimitMinutes; // таймер (мин)
  final List<ExamQuestionModel> questions;

  ExamModel({
    required this.id,
    required this.title,
    this.description,
    this.grade,
    this.subject,
    this.timeLimitMinutes,
    this.questions = const [],
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    final questionsJson = json['questions'] as List<dynamic>? ?? [];
    return ExamModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      grade: json['grade'] as int?,
      subject: json['subject'] as String?,
      timeLimitMinutes: json['time_limit_minutes'] as int?,
      questions: questionsJson
          .map((q) => ExamQuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExamQuestionModel {
  final int id;
  final String questionType;
  final String questionText;
  final List<String>? options;
  final List<String>? correctAnswers;
  final String? textAnswer;

  ExamQuestionModel({
    required this.id,
    required this.questionType,
    required this.questionText,
    this.options,
    this.correctAnswers,
    this.textAnswer,
  });

  factory ExamQuestionModel.fromJson(Map<String, dynamic> json) {
    return ExamQuestionModel(
      id: json['id'] as int,
      questionType: json['question_type'] as String,
      questionText: json['question_text'] as String,
      options:
          json['options'] == null ? null : List<String>.from(json['options']),
      correctAnswers: json['correct_answers'] == null
          ? null
          : List<String>.from(json['correct_answers']),
      textAnswer: json['text_answer'] as String?,
    );
  }
}
