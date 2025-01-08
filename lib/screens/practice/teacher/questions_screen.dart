import 'package:flutter/material.dart';
import 'package:school_test_app/config.dart';
import 'package:school_test_app/models/test_model.dart';
import 'package:school_test_app/services/test_service.dart';
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
      appBar: AppBar(
        title: const Text('Вопросы теста'),
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
            return const Center(child: Text('Тест не найден'));
          }

          final questions = test.questions;
          if (questions.isEmpty) {
            return const Center(child: Text('Нет вопросов'));
          }

          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              return ListTile(
                title: Text(question.questionText),
                subtitle: Text('Тип: ${question.questionType}'),
                onTap: () async {
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
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    try {
                      await _testsService.deleteQuestion(test.id, question.id);
                      _fetchTest();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ошибка: $e')),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _onAddQuestion,
      ),
    );
  }
}
