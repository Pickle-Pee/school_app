import 'package:flutter/material.dart';
import 'package:school_test_app/config.dart';
import 'package:school_test_app/models/test_model.dart';
import 'package:school_test_app/services/test_service.dart';
import 'package:school_test_app/theme/app_theme.dart';
import 'create_question_screen.dart';

class QuestionsScreen extends StatefulWidget {
  final int testId;

  const QuestionsScreen({Key? key, required this.testId}) : super(key: key);

  @override
  _QuestionsScreenState createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  late final TestsService _testsService;
  late Future<TestModel> _futureTest;

  @override
  void initState() {
    super.initState();
    _testsService = TestsService(Config.baseUrl);
    _fetchTest();
  }

  void _fetchTest() {
    setState(() {
      _futureTest = _testsService.getTestById(widget.testId);
    });
  }

  void _onAddQuestion() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateQuestionScreen(testId: widget.testId),
      ),
    );
    if (updated == true) {
      _fetchTest();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Row(
                  children: const [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.quiz_rounded, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Вопросы теста',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: FutureBuilder<TestModel>(
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
                        return const Center(child: Text('Тест не найден'));
                      }

                      final questions = test.questions;
                      if (questions.isEmpty) {
                        return _EmptyQuestions(onAddQuestion: _onAddQuestion);
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          final question = questions[index];
                          return _QuestionCard(
                            index: index,
                            questionText: question.questionText,
                            type: question.questionType,
                            onEdit: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreateQuestionScreen(
                                    testId: test.id,
                                    question: question,
                                  ),
                                ),
                              );
                              if (updated == true) {
                                _fetchTest();
                              }
                            },
                            onDelete: () async {
                              try {
                                await _testsService.deleteQuestion(
                                    test.id, question.id);
                                _fetchTest();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ошибка: $e')),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddQuestion,
        icon: const Icon(Icons.add),
        label: const Text('Добавить вопрос'),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final String questionText;
  final String type;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.index,
    required this.questionText,
    required this.type,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      questionText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Chip(
                    avatar: const Icon(Icons.category_rounded,
                        size: 18, color: AppTheme.primaryColor),
                    backgroundColor: AppTheme.accentColor.withOpacity(0.18),
                    label: Text(
                      _typeLabel(type),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Редактировать'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon:
                        const Icon(Icons.delete_outline, color: Colors.redAccent),
                    label: const Text(
                      'Удалить',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              )
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

class _EmptyQuestions extends StatelessWidget {
  final VoidCallback onAddQuestion;

  const _EmptyQuestions({required this.onAddQuestion});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.help_center_outlined,
                color: AppTheme.primaryColor, size: 64),
            const SizedBox(height: 12),
            Text(
              'Добавьте вопросы, чтобы ученики могли приступать к тесту.',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Используйте разные типы вопросов: текст, единичный или множественный выбор.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onAddQuestion,
              icon: const Icon(Icons.add),
              label: const Text('Добавить первый вопрос'),
            )
          ],
        ),
      ),
    );
  }
}
