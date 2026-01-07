// models/question_model.dart

class QuestionModel {
  final int id;
  final String type;
  final String prompt;
  final List<String>? options;
  final bool required;
  final int points;
  final dynamic correctAnswer;

  QuestionModel({
    required this.id,
    required this.type,
    required this.prompt,
    this.options,
    required this.required,
    required this.points,
    this.correctAnswer,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? json['question_type']) as String? ?? 'text';
    final prompt = (json['prompt'] ?? json['question_text']) as String? ?? '';
    final optionsRaw = json['options'];
    final requiredValue = json['required'] as bool? ?? true;
    final pointsValue = json['points'] as int? ?? 1;
    dynamic correctAnswer = json['correct_answer'];
    correctAnswer ??= json['correct_answers'];
    correctAnswer ??= json['text_answer'];

    return QuestionModel(
      id: json['id'] as int? ?? 0,
      type: type,
      prompt: prompt,
      options: optionsRaw == null
          ? null
          : List<String>.from(optionsRaw as List),
      required: requiredValue,
      points: pointsValue,
      correctAnswer: correctAnswer,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'prompt': prompt,
      'options': options,
      'required': required,
      'points': points,
      'correct_answer': correctAnswer,
    };
  }
}
