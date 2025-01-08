import 'package:flutter/material.dart';
import 'package:school_test_app/config.dart';
import 'package:school_test_app/models/test_model.dart';
import 'package:school_test_app/screens/practice/student/take_test_screen.dart';
import 'package:school_test_app/services/test_service.dart';
import 'package:school_test_app/services/auth_service.dart';
import 'create_test_screen.dart';
import 'questions_screen.dart';

class TestsScreen extends StatefulWidget {
  const TestsScreen({Key? key}) : super(key: key);

  @override
  _TestsScreenState createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  late final TestsService _testsService;
  late Future<List<TestModel>> _futureTests;

  bool _isTeacher = false;

  @override
  void initState() {
    super.initState();
    _testsService = TestsService(Config.baseUrl);

    _checkUserType();
    _fetchTests();
  }

  Future<void> _checkUserType() async {
    final role = await AuthService.getUserType();
    setState(() {
      _isTeacher = (role == 'teacher');
    });
  }

  void _fetchTests() {
    setState(() {
      _futureTests = _testsService
          .getMyTests(); // или getTestsForStudent(), если разделили эндпоинты
    });
  }

  void _onCreateTest() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTestScreen()),
    );
    if (created == true) {
      _fetchTests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Задачи и упражнения'),
      ),
      body: FutureBuilder<List<TestModel>>(
        future: _futureTests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          final tests = snapshot.data ?? [];
          if (tests.isEmpty) {
            return const Center(child: Text('Пока нет задач.'));
          }
          return ListView.builder(
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index];
              return ListTile(
                title: Text(test.title),
                subtitle: Text(test.description ?? ''),
                onTap: () {
                  if (_isTeacher) {
                    // Учитель → редактирование
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuestionsScreen(testId: test.id),
                      ),
                    );
                  } else {
                    // Ученик → прохождение
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TakeTestScreen(testId: test.id),
                      ),
                    );
                  }
                },
                trailing: _isTeacher
                    ? IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          try {
                            await _testsService.deleteTest(test.id);
                            _fetchTests();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Ошибка удаления: $e')),
                            );
                          }
                        },
                      )
                    : null,
              );
            },
          );
        },
      ),
      floatingActionButton: _isTeacher
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: _onCreateTest,
            )
          : null,
    );
  }
}
