// models/question_model.dart

class QuestionModel {
  final int id;
  final String questionType;
  final String questionText;
  final List<String>? options;
  final List<String>? correctAnswers;
  final String? textAnswer;

  QuestionModel({
    required this.id,
    required this.questionType,
    required this.questionText,
    this.options,
    this.correctAnswers,
    this.textAnswer,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as int,
      questionType: json['question_type'] as String,
      questionText: json['question_text'] as String,
      options: json['options'] == null
          ? null
          : List<String>.from(json['options'] as List),
      correctAnswers: json['correct_answers'] == null
          ? null
          : List<String>.from(json['correct_answers'] as List),
      textAnswer: json['text_answer'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_type': questionType,
      'question_text': questionText,
      'options': options,
      'correct_answers': correctAnswers,
      'text_answer': textAnswer,
    };
  }
}
