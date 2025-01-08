import 'package:flutter/material.dart';
import 'package:school_test_app/models/question_model.dart';
import 'package:school_test_app/services/test_service.dart';
import 'package:school_test_app/models/test_model.dart';
import 'package:school_test_app/config.dart';

class TakeTestScreen extends StatefulWidget {
  final int testId;

  const TakeTestScreen({Key? key, required this.testId}) : super(key: key);

  @override
  _TakeTestScreenState createState() => _TakeTestScreenState();
}

class _TakeTestScreenState extends State<TakeTestScreen> {
  late final TestsService _testsService;
  late Future<TestModel> _futureTest;

  // Храним выбранные ответы юзера
  // (например, Map<questionId, List<String>> или Map<int, dynamic> ... )
  Map<int, dynamic> userAnswers = {};

  @override
  void initState() {
    super.initState();
    _testsService = TestsService(Config.baseUrl);
    _loadTest();
  }

  void _loadTest() {
    setState(() {
      _futureTest = _testsService.getTestById(widget.testId);
    });
  }

  // Отправляем на бэкенд
  Future<void> _submitAnswers() async {
    // Сформировать структуру для /student/submit-test
    // Например: { test_id: 123, answers: [ {question_id: 1, answer: [...]}, ...] }
    final List<Map<String, dynamic>> answersList =
        userAnswers.entries.map((entry) {
      final questionId = entry.key;
      final userAnswer = entry.value;
      // userAnswer может быть List<String>, или String
      // допустим, у вас schemas.StudentTestSubmit(answers=List[AnswerItem]) c poljami question_id i answer
      return {
        "question_id": questionId,
        "answer": userAnswer,
      };
    }).toList();

    final body = {
      "test_id": widget.testId,
      "answers": answersList,
    };

    try {
      // Допустим, у TestsService есть метод submitTest(body)
      // Или вы сделаете отдельный service (StudentService)
      await _testsService.submitTest(body);
      // Показать результат, вернуться, etc
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Тест отправлен!")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка отправки: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Пройти тест"),
      ),
      body: FutureBuilder<TestModel>(
        future: _futureTest,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          final test = snapshot.data;
          if (test == null) {
            return const Center(child: Text("Тест не найден"));
          }

          final questions = test.questions;
          if (questions.isEmpty) {
            return const Center(child: Text("В тесте нет вопросов"));
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
                onPressed: _submitAnswers,
                child: const Text("Отправить ответы"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuestionItem(QuestionModel question) {
    // Пример: если questionType == 'multiple_choice', отобразить чекбоксы,
    // если 'single_choice', RadioList, если 'text_input' => TextField
    // В конце сохраняем ответ в userAnswers[question.id]

    if (question.questionType == 'text_input') {
      // Текстовый ответ
      final controller = TextEditingController();
      controller.addListener(() {
        userAnswers[question.id] = controller.text;
      });
      return ListTile(
        title: Text(question.questionText),
        subtitle: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Введите ответ"),
        ),
      );
    } else if (question.questionType == 'multiple_choice') {
      // Для упрощения, сделаем CheckboxListTile
      // (на практике нужно хранить userAnswers[question.id] как List<String>)
      final options = question.options ?? [];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.questionText,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          ...options
              .map((opt) => _buildCheckboxOption(question.id, opt))
              .toList(),
        ],
      );
    } else if (question.questionType == 'single_choice') {
      // RadioListTile
      final options = question.options ?? [];
      // ...
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.questionText,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          ...options.map((opt) => _buildRadioOption(question.id, opt)).toList(),
        ],
      );
    } else {
      return ListTile(
        title: Text("Неизвестный тип вопроса: ${question.questionType}"),
      );
    }
  }

  Widget _buildCheckboxOption(int questionId, String option) {
    // suppose we store userAnswers[questionId] as a Set<String>
    final currentAnswer = userAnswers[questionId] as Set<String>? ?? {};
    final isSelected = currentAnswer.contains(option);

    return CheckboxListTile(
      value: isSelected,
      title: Text(option),
      onChanged: (bool? val) {
        final updated = Set<String>.from(currentAnswer);
        if (val == true) {
          updated.add(option);
        } else {
          updated.remove(option);
        }
        setState(() {
          userAnswers[questionId] = updated;
        });
      },
    );
  }

  Widget _buildRadioOption(int questionId, String option) {
    final currentAnswer = userAnswers[questionId] as String?; // single string
    return RadioListTile<String>(
      value: option,
      groupValue: currentAnswer,
      title: Text(option),
      onChanged: (val) {
        setState(() {
          userAnswers[questionId] = val;
        });
      },
    );
  }
}
