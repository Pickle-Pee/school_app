import 'package:flutter/material.dart';
import 'package:school_test_app/config.dart';
import 'package:school_test_app/models/test_model.dart';
import 'package:school_test_app/screens/practice/student/take_test_screen.dart';
import 'package:school_test_app/services/test_service.dart';
import 'package:school_test_app/services/auth_service.dart';
import 'package:school_test_app/theme/app_theme.dart';
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(isTeacher: _isTeacher),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: FutureBuilder<List<TestModel>>(
                    future: _futureTests,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Ошибка: ${snapshot.error}'),
                        );
                      }
                      final tests = snapshot.data ?? [];
                      if (tests.isEmpty) {
                        return _EmptyState(
                          isTeacher: _isTeacher,
                          onCreate: _isTeacher ? _onCreateTest : null,
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                        itemCount: tests.length,
                        itemBuilder: (context, index) {
                          final test = tests[index];
                          return _TestCard(
                            test: test,
                            isTeacher: _isTeacher,
                            onDelete: _isTeacher
                                ? () async {
                                    try {
                                      await _testsService.deleteTest(test.id);
                                      _fetchTests();
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text('Ошибка удаления: $e')),
                                      );
                                    }
                                  }
                                : null,
                            onTap: () {
                              if (_isTeacher) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QuestionsScreen(testId: test.id),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TakeTestScreen(testId: test.id),
                                  ),
                                );
                              }
                            },
                            onEdit: _isTeacher
                                ? () async {
                                    final updated = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CreateTestScreen(
                                          existingTest: test,
                                        ),
                                      ),
                                    );
                                    if (updated == true) {
                                      _fetchTests();
                                    }
                                  }
                                : null,
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
      floatingActionButton: _isTeacher
          ? FloatingActionButton.extended(
              onPressed: _onCreateTest,
              icon: const Icon(Icons.add),
              label: const Text('Создать тест'),
            )
          : null,
    );
  }
}

class _Header extends StatelessWidget {
  final bool isTeacher;

  const _Header({required this.isTeacher});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: Icon(Icons.code_rounded, color: Colors.white),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Практика и тесты',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isTeacher
                ? 'Создавайте задания, редактируйте вопросы и отслеживайте прогресс класса.'
                : 'Решайте задачи и проходите тесты по информатике в удобном формате.',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isTeacher;
  final VoidCallback? onCreate;

  const _EmptyState({required this.isTeacher, this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              size: 52,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isTeacher
                ? 'Добавьте первый тест для своего класса.'
                : 'Пока нет активных заданий.',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isTeacher
                ? 'Создайте тест и наполните его задачами по теме урока.'
                : 'Сообщите преподавателю, что вы готовы приступить к работе.',
            style: const TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (isTeacher)
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Создать тест'),
            ),
        ],
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  final TestModel test;
  final bool isTeacher;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _TestCard({
    required this.test,
    required this.isTeacher,
    required this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.assignment_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            test.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            test.description ?? 'Практика по информатике',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _InfoChip(
                                icon: Icons.school_rounded,
                                label: test.grade != null
                                    ? '${test.grade} класс'
                                    : 'Любой класс',
                              ),
                              _InfoChip(
                                icon: Icons.code,
                                label: test.subject ?? 'Информатика',
                              ),
                              _InfoChip(
                                icon: Icons.help_outline,
                                label:
                                    '${test.questions.length} ${_questionWord(test.questions.length)}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isTeacher)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit' && onEdit != null) onEdit!();
                          if (value == 'delete' && onDelete != null) onDelete!();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Редактировать'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Удалить'),
                          ),
                        ],
                      )
                    else
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.black38),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: onTap,
                      child: Text(isTeacher ? 'Редактировать вопросы' : 'Пройти'),
                    ),
                    const SizedBox(width: 10),
                    if (isTeacher && onEdit != null)
                      OutlinedButton(
                        onPressed: onEdit,
                        child: const Text('Параметры теста'),
                      )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _questionWord(int count) {
    if (count == 1) return 'вопрос';
    if (count >= 2 && count <= 4) return 'вопроса';
    return 'вопросов';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: AppTheme.accentColor.withOpacity(0.14),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      avatar: Icon(icon, size: 18, color: AppTheme.primaryColor),
      label: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
