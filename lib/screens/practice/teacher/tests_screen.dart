import 'package:flutter/material.dart';
import 'package:school_test_app/config.dart';
import 'package:school_test_app/models/education_models.dart';
import 'package:school_test_app/models/profile_models.dart';
import 'package:school_test_app/models/test_model.dart';
import 'package:school_test_app/screens/practice/student/take_test_screen.dart';
import 'package:school_test_app/services/test_service.dart';
import 'package:school_test_app/services/auth_service.dart';
import 'package:school_test_app/services/education_service.dart';
import 'package:school_test_app/services/profile_service.dart';
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
  late final EducationService _educationService;
  late final ProfileService _profileService;
  late Future<List<TestModel>> _futureTests;

  bool _isTeacher = false;
  List<ClassItem> _classes = [];
  List<TopicItem> _topics = [];
  List<SubjectItem> _subjects = [];
  int? _selectedClassId;
  int? _selectedTopicId;
  String? _selectedSubject;
  final TextEditingController _teacherSubjectController =
      TextEditingController();
  String _type = 'practice';

  @override
  void initState() {
    super.initState();
    _testsService = TestsService(Config.baseUrl);
    _educationService = EducationService();
    _profileService = ProfileService();
    _futureTests = Future.value([]);

    _checkUserType();
  }

  @override
  void dispose() {
    _teacherSubjectController.dispose();
    super.dispose();
  }

  Future<void> _checkUserType() async {
    final role = await AuthService.getUserType();
    setState(() {
      _isTeacher = (role == 'teacher');
    });
    await _loadFilters();
    _fetchTests();
  }

  Future<void> _loadFilters() async {
    if (_isTeacher) {
      final classes = await _educationService.getTeacherClasses();
      ProfileView? profile;
      try {
        profile = await _profileService.getProfile();
      } catch (_) {
        profile = null;
      }
      setState(() {
        _classes = classes;
        _selectedClassId = classes.isNotEmpty ? classes.first.id : null;
        _selectedSubject = profile?.subject ?? _selectedSubject;
        _teacherSubjectController.text = _selectedSubject ?? '';
      });
      await _loadTopics();
    } else {
      final subjects = await _educationService.getStudentSubjects();
      setState(() {
        _subjects = subjects;
        _selectedSubject = subjects.isNotEmpty ? subjects.first.name : null;
      });
      await _loadTopics();
    }
  }

  Future<void> _loadTopics() async {
    if (_selectedSubject == null || _selectedSubject!.isEmpty) {
      setState(() {
        _topics = [];
        _selectedTopicId = null;
      });
      return;
    }
    if (_isTeacher) {
      if (_selectedClassId == null) return;
      final topics = await _educationService.getTeacherTopics(
        classId: _selectedClassId!,
        subject: _selectedSubject!,
      );
      setState(() {
        _topics = topics;
        _selectedTopicId = topics.isNotEmpty ? topics.first.id : null;
      });
    } else {
      final topics = await _educationService.getStudentTopics(
        subject: _selectedSubject!,
      );
      setState(() {
        _topics = topics;
        _selectedTopicId = topics.isNotEmpty ? topics.first.id : null;
      });
    }
  }

  void _fetchTests() {
    final subject = _selectedSubject;
    final classId = _selectedClassId;
    final topicId = _selectedTopicId;
    if (subject == null || subject.isEmpty || (_isTeacher && classId == null)) {
      setState(() {
        _futureTests = Future.value([]);
      });
      return;
    }

    setState(() {
      _futureTests = _isTeacher
          ? _testsService.getTeacherAssignments(
              classId: classId ?? 0,
              subject: subject,
              type: _type,
            )
          : _testsService.getStudentAssignments(
              subject: subject,
              type: _type,
              topicId: topicId,
            );
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
              _Filters(
                isTeacher: _isTeacher,
                classes: _classes,
                subjects: _subjects,
                topics: _topics,
                selectedClassId: _selectedClassId,
                selectedSubject: _selectedSubject,
                selectedTopicId: _selectedTopicId,
                teacherSubjectController: _teacherSubjectController,
                onClassChanged: (value) async {
                  setState(() {
                    _selectedClassId = value;
                  });
                  await _loadTopics();
                },
                onSubjectChanged: (value) async {
                  setState(() {
                    _selectedSubject = value;
                  });
                  await _loadTopics();
                },
                onTopicChanged: (value) {
                  setState(() {
                    _selectedTopicId = value;
                  });
                },
                type: _type,
                onTypeChanged: (value) {
                  setState(() {
                    _type = value;
                  });
                },
                onApply: _fetchTests,
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
                                      await _testsService
                                          .deleteAssignment(test.id);
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
              label: const Text('Создать работу'),
            )
          : null,
    );
  }
}

class _Filters extends StatelessWidget {
  final bool isTeacher;
  final List<ClassItem> classes;
  final List<SubjectItem> subjects;
  final List<TopicItem> topics;
  final int? selectedClassId;
  final String? selectedSubject;
  final int? selectedTopicId;
  final TextEditingController teacherSubjectController;
  final ValueChanged<int?> onClassChanged;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<int?> onTopicChanged;
  final String type;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onApply;

  const _Filters({
    required this.isTeacher,
    required this.classes,
    required this.subjects,
    required this.topics,
    required this.selectedClassId,
    required this.selectedSubject,
    required this.selectedTopicId,
    required this.teacherSubjectController,
    required this.onClassChanged,
    required this.onSubjectChanged,
    required this.onTopicChanged,
    required this.type,
    required this.onTypeChanged,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              if (isTeacher)
                DropdownButtonFormField<int>(
                  value: selectedClassId,
                  decoration: const InputDecoration(
                    labelText: 'Класс',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: classes
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name.isNotEmpty
                              ? item.name
                              : '${item.grade}${item.letter}'),
                        ),
                      )
                      .toList(),
                  onChanged: onClassChanged,
                ),
              if (isTeacher) const SizedBox(height: 12),
              isTeacher
                  ? TextField(
                      controller: teacherSubjectController,
                      decoration: const InputDecoration(
                        labelText: 'Предмет',
                        prefixIcon: Icon(Icons.menu_book_rounded),
                      ),
                      onChanged: onSubjectChanged,
                    )
                  : DropdownButtonFormField<String>(
                      value: selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Предмет',
                        prefixIcon: Icon(Icons.menu_book_rounded),
                      ),
                      items: subjects
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.name,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: onSubjectChanged,
                    ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: selectedTopicId,
                decoration: const InputDecoration(
                  labelText: 'Тема',
                  prefixIcon: Icon(Icons.topic_outlined),
                ),
                items: topics
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.title),
                      ),
                    )
                    .toList(),
                onChanged: onTopicChanged,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(
                  labelText: 'Тип работы',
                  prefixIcon: Icon(Icons.assignment_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'practice', child: Text('Практика')),
                  DropdownMenuItem(value: 'homework', child: Text('Домашняя')),
                ],
                onChanged: (value) => onTypeChanged(value ?? 'practice'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onApply,
                  icon: const Icon(Icons.search),
                  label: const Text('Показать работы'),
                ),
              ),
            ],
          ),
        ),
      ),
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
                  'Практика',
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
                : 'Решайте задачи и проходите практику в удобном формате.',
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
                ? 'Добавьте первую работу для своего класса.'
                : 'Пока нет активных заданий.',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isTeacher
                ? 'Создайте работу и наполните её задачами по теме урока.'
                : 'Сообщите преподавателю, что вы готовы приступить к работе.',
            style: const TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (isTeacher)
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Создать работу'),
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
                            test.description ?? 'Практика по предмету',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _InfoChip(
                                icon: Icons.school_rounded,
                                label: test.classId != null
                                    ? 'Класс ${test.classId}'
                                    : 'Любой класс',
                              ),
                              _InfoChip(
                                icon: Icons.code,
                                label: test.subject ?? 'Предмет',
                              ),
                              if (test.type != null)
                                _InfoChip(
                                  icon: Icons.assignment_outlined,
                                  label: test.type == 'homework'
                                      ? 'Домашняя'
                                      : 'Практика',
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
                        child: const Text('Параметры работы'),
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
