import 'package:flutter/material.dart';
import 'package:school_test_app/models/exam_models.dart';
import 'package:school_test_app/services/exam_service.dart';
import 'package:school_test_app/config.dart';

class TakeExamScreen extends StatefulWidget {
  final int examId;
  const TakeExamScreen({Key? key, required this.examId}) : super(key: key);

  @override
  State<TakeExamScreen> createState() => _TakeExamScreenState();
}

class _TakeExamScreenState extends State<TakeExamScreen> {
  late final ExamsService _examsService;
  late Future<ExamModel> _futureExam;

  /// Храним ответы ученика для каждого вопроса.
  /// Ключ: questionId, Значение:
  ///    - для text_input: String
  ///    - для multiple_choice: Set<String>
  ///    - для single_choice: String
  Map<int, dynamic> userAnswers = {};

  @override
  void initState() {
    super.initState();
    _examsService = ExamsService(Config.baseUrl);
    _loadExam();
  }

  void _loadExam() {
    setState(() {
      _futureExam = _examsService.getExamById(widget.examId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Прохождение экзамена"),
      ),
      body: FutureBuilder<ExamModel>(
        future: _futureExam,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Ошибка: ${snapshot.error}"));
          }
          final exam = snapshot.data;
          if (exam == null) {
            return const Center(child: Text("Экзамен не найден"));
          }
          final questions = exam.questions;
          if (questions.isEmpty) {
            return const Center(child: Text("В экзамене нет вопросов"));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    return _buildQuestionItem(question);
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _onSubmitAnswers,
                child: const Text("Отправить экзамен"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuestionItem(ExamQuestionModel question) {
    // В зависимости от questionType рендерим разные виджеты
    switch (question.questionType) {
      case 'text_input':
        return _buildTextInputQuestion(question);
      case 'multiple_choice':
        return _buildMultipleChoiceQuestion(question);
      case 'single_choice':
        return _buildSingleChoiceQuestion(question);
      default:
        return ListTile(
          title: Text("Неизвестный тип вопроса: ${question.questionType}"),
        );
    }
  }

  Widget _buildTextInputQuestion(ExamQuestionModel question) {
    final controller = TextEditingController();
    controller.addListener(() {
      userAnswers[question.id] = controller.text;
    });

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.questionText,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Введите ответ",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceQuestion(ExamQuestionModel question) {
    final currentAnswer = userAnswers[question.id] as Set<String>? ?? {};
    final options = question.options ?? [];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.questionText,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ...options.map((opt) {
            final isSelected = currentAnswer.contains(opt);
            return CheckboxListTile(
              title: Text(opt),
              value: isSelected,
              onChanged: (val) {
                final updated = Set<String>.from(currentAnswer);
                if (val == true) {
                  updated.add(opt);
                } else {
                  updated.remove(opt);
                }
                setState(() {
                  userAnswers[question.id] = updated;
                });
              },
            );
          }).toList()
        ],
      ),
    );
  }

  Widget _buildSingleChoiceQuestion(ExamQuestionModel question) {
    final currentAnswer = userAnswers[question.id] as String?; // single string
    final options = question.options ?? [];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.questionText,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ...options.map((opt) {
            return RadioListTile<String>(
              title: Text(opt),
              value: opt,
              groupValue: currentAnswer,
              onChanged: (val) {
                setState(() {
                  userAnswers[question.id] = val;
                });
              },
            );
          }).toList()
        ],
      ),
    );
  }

  Future<void> _onSubmitAnswers() async {
    final answersData = userAnswers.entries.map((entry) {
      final questionId = entry.key;
      final answerValue = entry.value;

      if (answerValue is Set<String>) {
        return {
          "question_id": questionId,
          "answer": answerValue.toList(),
        };
      } else if (answerValue is String) {
        return {
          "question_id": questionId,
          "answer": answerValue,
        };
      } else {
        return {
          "question_id": questionId,
          "answer": null,
        };
      }
    }).toList();

    final body = {
      "exam_id": widget.examId,
      "answers": answersData,
    };

    try {
      // Логируем перед отправкой
      debugPrint('Submitting exam with body: $body');

      await _examsService.submitExam(body);

      // Логируем успешный результат
      debugPrint('Exam submitted successfully.');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Экзамен отправлен!")),
      );
      Navigator.pop(context, true);
    } catch (e, stackTrace) {
      // Логируем ошибку
      debugPrint('Error while submitting exam: $e');
      debugPrint('Stack trace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка отправки: $e")),
      );
    }
  }
}
