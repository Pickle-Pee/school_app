import 'package:flutter/material.dart';
import 'package:school_test_app/models/question_model.dart';
import 'package:school_test_app/services/test_service.dart';
import 'package:school_test_app/models/test_model.dart';
import 'package:school_test_app/config.dart';
import 'package:school_test_app/theme/app_theme.dart';

class TakeTestScreen extends StatefulWidget {
  final int testId;

  const TakeTestScreen({Key? key, required this.testId}) : super(key: key);

  @override
  _TakeTestScreenState createState() => _TakeTestScreenState();
}

class _TakeTestScreenState extends State<TakeTestScreen> {
  late final TestsService _testsService;
  late Future<TestModel> _futureTest;
  List<QuestionModel> _questions = [];

  // Храним выбранные ответы юзера
  // (например, Map<questionId, List<String>> или Map<int, dynamic> ... )
  Map<int, dynamic> userAnswers = {};
  final Map<int, TextEditingController> _textControllers = {};

  @override
  void initState() {
    super.initState();
    _testsService = TestsService(Config.baseUrl);
    _loadTest();
  }

  void _loadTest() {
    final future = _testsService.getTestById(widget.testId);
    setState(() {
      _futureTest = future;
    });
    future.then((test) {
      if (!mounted) return;
      setState(() => _questions = test.questions);
    });
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Отправляем на бэкенд
  Future<void> _submitAnswers() async {
    if (!_validateAnswers()) {
      return;
    }
    // Сформировать структуру для /student/submit-test
    // Например: { test_id: 123, answers: [ {question_id: 1, answer: [...]}, ...] }
    final List<Map<String, dynamic>> answersList =
        userAnswers.entries.map((entry) {
      final questionId = entry.key;
      final userAnswer = entry.value;
      final answerToSubmit =
          (userAnswer is Set) ? userAnswer.toList() : userAnswer;
      return {
        "question_id": questionId,
        "answer": answerToSubmit,
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
        const SnackBar(content: Text("Практика отправлена!")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка отправки: $e")),
      );
    }
  }

  bool _validateAnswers() {
    for (final question in _questions) {
      final answer = userAnswers[question.id];
      if (question.questionType == 'text_input') {
        final text = (answer is String) ? answer.trim() : '';
        if (text.isEmpty) {
          _showValidationError('Ответьте на вопрос "${question.questionText}".');
          return false;
        }
      } else if (question.questionType == 'multiple_choice') {
        final values = answer is Set ? answer : <String>{};
        if (values.isEmpty) {
          _showValidationError('Выберите вариант(ы) для "${question.questionText}".');
          return false;
        }
      } else if (question.questionType == 'single_choice') {
        if (answer == null || (answer is String && answer.trim().isEmpty)) {
          _showValidationError('Выберите вариант для "${question.questionText}".');
          return false;
        }
      }
    }
    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            return const Center(child: Text("Практика не найдена"));
          }

          final questions = test.questions;
          if (questions.isEmpty) {
            return const Center(child: Text("В практике нет вопросов"));
          }

          return Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _TestHero(test: test),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          final question = questions[index];
                          return _buildQuestionItem(question, index + 1);
                        },
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: _submitAnswers,
                          label: const Text("Отправить ответы"),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionItem(QuestionModel question, int position) {
    // Пример: если questionType == 'multiple_choice', отобразить чекбоксы,
    // если 'single_choice', RadioList, если 'text_input' => TextField
    // В конце сохраняем ответ в userAnswers[question.id]

    if (question.questionType == 'text_input') {
      // Текстовый ответ
      final controller = _textControllers.putIfAbsent(
        question.id,
        () => TextEditingController(text: userAnswers[question.id] as String?),
      );

      return _QuestionCard(
        position: position,
        question: question,
        child: TextField(
          controller: controller,
          onChanged: (value) => userAnswers[question.id] = value,
          decoration: const InputDecoration(
            hintText: "Введите ответ",
            filled: true,
            fillColor: Color(0xFFF5F7FB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      );
    } else if (question.questionType == 'multiple_choice') {
      // Для упрощения, сделаем CheckboxListTile
      // (на практике нужно хранить userAnswers[question.id] как List<String>)
      final options = question.options ?? [];
      return _QuestionCard(
        position: position,
        question: question,
        child: Column(
          children:
              options.map((opt) => _buildCheckboxOption(question.id, opt)).toList(),
        ),
      );
    } else if (question.questionType == 'single_choice') {
      // RadioListTile
      final options = question.options ?? [];
      // ...
      return _QuestionCard(
        position: position,
        question: question,
        child: Column(
          children:
              options.map((opt) => _buildRadioOption(question.id, opt)).toList(),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Неизвестный тип вопроса: ${question.questionType}"),
          ),
        ),
      );
    }
  }

  Widget _buildCheckboxOption(int questionId, String option) {
    // suppose we store userAnswers[questionId] as a Set<String>
    final currentAnswer = userAnswers[questionId] as Set<String>? ?? {};
    final isSelected = currentAnswer.contains(option);

    return CheckboxListTile(
      value: isSelected,
      activeColor: AppTheme.primaryColor,
      title: Text(option),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      activeColor: AppTheme.primaryColor,
      title: Text(option),
      onChanged: (val) {
        setState(() {
          userAnswers[questionId] = val;
        });
      },
    );
  }
}

class _TestHero extends StatelessWidget {
  final TestModel test;

  const _TestHero({required this.test});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),
              const SizedBox(width: 6),
              const Text(
                'Практика по предмету',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            test.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _HeroChip(
                icon: Icons.school_rounded,
                label: test.grade != null ? '${test.grade} класс' : 'Без класса',
              ),
              const SizedBox(width: 8),
              _HeroChip(
                icon: Icons.code_rounded,
                label: test.subject ?? 'Предмет',
              ),
            ],
          ),
          if ((test.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              test.description ?? '',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          )
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int position;
  final QuestionModel question;
  final Widget child;

  const _QuestionCard({
    required this.position,
    required this.question,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.accentColor.withOpacity(0.15),
                    child: Text(
                      position.toString(),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      question.questionText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _typeLabel(question.questionType),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'Множественный выбор';
      case 'single_choice':
        return 'Одиночный выбор';
      default:
        return 'Свободный ответ';
    }
  }
}
