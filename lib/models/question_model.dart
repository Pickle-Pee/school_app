class QuestionModel {
  final int id;
  final String questionType;
  final String questionText;
  final String type;
  final String prompt;
  final List<String>? options;
  final List<String>? correctAnswers;
  final String? textAnswer;
  final bool required;
  final int points;
  final dynamic correctAnswer;

  QuestionModel({
    required this.id,
    required this.questionType,
    required this.questionText,
    required this.type,
    required this.prompt,
    this.options,
    this.correctAnswers,
    this.textAnswer,
    required this.required,
    required this.points,
    this.correctAnswer,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? json['question_type']) as String? ?? 'text';
    final prompt =
        (json['prompt'] ?? json['question_text']) as String? ?? '';

    final optionsRaw = json['options'];
    final correctAnswersRaw = json['correct_answers'];

    final requiredValue = json['required'] as bool? ?? true;
    final pointsValue = json['points'] as int? ?? 1;

    dynamic correctAnswer = json['correct_answer'] ??
        json['correct_answers'] ??
        json['text_answer'];

    return QuestionModel(
      id: json['id'] as int? ?? 0,
      questionType: json['question_type'] as String? ?? '',
      questionText: json['question_text'] as String? ?? '',
      type: type,
      prompt: prompt,
      options: optionsRaw == null
          ? null
          : List<String>.from(optionsRaw as List),
      correctAnswers: correctAnswersRaw == null
          ? null
          : List<String>.from(correctAnswersRaw as List),
      textAnswer: json['text_answer'] as String?,
      required: requiredValue,
      points: pointsValue,
      correctAnswer: correctAnswer,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_type': questionType,
      'question_text': questionText,
      'type': type,
      'prompt': prompt,
      'options': options,
      'correct_answers': correctAnswers,
      'text_answer': textAnswer,
      'required': required,
      'points': points,
      'correct_answer': correctAnswer,
    };
  }
}
