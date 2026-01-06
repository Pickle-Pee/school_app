import 'package:flutter/material.dart';
import 'package:school_test_app/features/common/models/assignment.dart';
import 'package:school_test_app/features/common/models/subject.dart';
import 'package:school_test_app/features/common/models/theory_material.dart';
import 'package:school_test_app/features/common/models/topic.dart';
import 'package:school_test_app/features/student/subject/student_assignment_detail_screen.dart';
import 'package:school_test_app/features/student/subject/student_subject_service.dart';
import 'package:school_test_app/theme/app_theme.dart';

class StudentSubjectScreen extends StatefulWidget {
  const StudentSubjectScreen({super.key});

  @override
  State<StudentSubjectScreen> createState() => _StudentSubjectScreenState();
}

class _StudentSubjectScreenState extends State<StudentSubjectScreen>
    with SingleTickerProviderStateMixin {
  final StudentSubjectService _service = StudentSubjectService();
  List<Subject> _subjects = [];
  List<Topic> _topics = [];
  Subject? _selectedSubject;
  Topic? _selectedTopic;
  String _assignmentType = 'practice';
  late final TabController _tabController;
  Future<List<TheoryMaterial>>? _theoryFuture;
  Future<List<Assignment>>? _assignmentsFuture;
  bool _subjectsLoading = false;
  bool _topicsLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSubjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    setState(() => _subjectsLoading = true);
    try {
      final subjects = await _service.fetchSubjects();
      setState(() {
        _subjects = subjects;
        _selectedSubject = subjects.isNotEmpty ? subjects.first : null;
        _topics = [];
        _selectedTopic = null;
      });
      await _loadTopics();
    } catch (e) {
      _showError('Не удалось загрузить предметы: $e');
    } finally {
      if (mounted) {
        setState(() => _subjectsLoading = false);
      }
    }
  }

  Future<void> _loadTopics() async {
    if (_selectedSubject == null) {
      return;
    }
    setState(() => _topicsLoading = true);
    try {
      final topics =
          await _service.fetchTopics(subject: _selectedSubject!.name);
      setState(() {
        _topics = topics;
        _selectedTopic = topics.isNotEmpty ? topics.first : null;
      });
      _loadTheory();
      _loadAssignments();
    } catch (e) {
      _showError('Не удалось загрузить темы: $e');
    } finally {
      if (mounted) {
        setState(() => _topicsLoading = false);
      }
    }
  }

  void _loadTheory() {
    if (_selectedSubject == null) {
      return;
    }
    setState(() {
      _theoryFuture = _service.fetchTheory(
        subject: _selectedSubject!.name,
        topicId: _selectedTopic?.id,
      );
    });
  }

  void _loadAssignments() {
    if (_selectedSubject == null) {
      return;
    }
    setState(() {
      _assignmentsFuture = _service.fetchAssignments(
        subject: _selectedSubject!.name,
        type: _assignmentType,
        topicId: _selectedTopic?.id,
      );
    });
  }

  Future<void> _showGradesDialog() async {
    if (_selectedSubject == null) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Оценки · ${_selectedSubject!.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _service.fetchGrades(subject: _selectedSubject!.name),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Ошибка: ${snapshot.error}');
              }
              final grades = snapshot.data ?? [];
              if (grades.isEmpty) {
                return const Text('Оценок пока нет.');
              }
              return ListView.separated(
                shrinkWrap: true,
                itemCount: grades.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = grades[index];
                  return ListTile(
                    title: Text(item['title']?.toString() ?? 'Работа'),
                    subtitle: Text(
                      'Оценка: ${item['grade'] ?? item['score'] ?? '-'}',
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppTheme.primaryColor.withOpacity(0.12),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _subjectsLoading ? null : _loadSubjects,
                      icon: _subjectsLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text('Обновить предметы'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_subjectsLoading) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                  ],
                  DropdownButtonFormField<Subject>(
                    value: _selectedSubject,
                    decoration: const InputDecoration(labelText: 'Предмет'),
                    items: _subjects
                        .map(
                          (subject) => DropdownMenuItem(
                            value: subject,
                            child: Text(subject.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedSubject = value);
                      _loadTopics();
                    },
                  ),
                  if (_subjects.isEmpty && !_subjectsLoading) ...[
                    const SizedBox(height: 12),
                    const Text('Предметы пока недоступны.'),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Topic>(
                    value: _selectedTopic,
                    decoration: const InputDecoration(labelText: 'Тема'),
                    items: _topics
                        .map(
                          (topic) => DropdownMenuItem(
                            value: topic,
                            child: Text(topic.title),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedTopic = value);
                      _loadTheory();
                      _loadAssignments();
                    },
                  ),
                  if (_topicsLoading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  if (_selectedSubject != null &&
                      _topics.isEmpty &&
                      !_topicsLoading) ...[
                    const SizedBox(height: 12),
                    const Text('Темы пока недоступны.'),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed:
                        _selectedSubject == null ? null : _showGradesDialog,
                    icon: const Icon(Icons.bar_chart_rounded),
                    label: const Text('Посмотреть оценки'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Теория'),
              Tab(text: 'Практика'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TheoryTab(future: _theoryFuture),
                _PracticeTab(
                  future: _assignmentsFuture,
                  assignmentType: _assignmentType,
                  onTypeChanged: (value) {
                    setState(() => _assignmentType = value);
                    _loadAssignments();
                  },
                  onAssignmentTap: (assignment) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentAssignmentDetailScreen(
                          assignmentId: assignment.id,
                          assignmentTitle: assignment.title,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TheoryTab extends StatelessWidget {
  const _TheoryTab({required this.future});

  final Future<List<TheoryMaterial>>? future;

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return const Center(child: Text('Выберите предмет и тему.'));
    }
    return FutureBuilder<List<TheoryMaterial>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('Материалов пока нет.'));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
              ),
              child: ListTile(
                title: Text(item.title),
                subtitle: Text(
                  item.content ?? item.fileUrl ?? 'Без описания',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PracticeTab extends StatelessWidget {
  const _PracticeTab({
    required this.future,
    required this.assignmentType,
    required this.onTypeChanged,
    required this.onAssignmentTap,
  });

  final Future<List<Assignment>>? future;
  final String assignmentType;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<Assignment> onAssignmentTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: assignmentType,
          decoration: const InputDecoration(labelText: 'Тип работы'),
          items: const [
            DropdownMenuItem(value: 'practice', child: Text('Практика')),
            DropdownMenuItem(value: 'homework', child: Text('ДЗ')),
          ],
          onChanged: (value) => onTypeChanged(value ?? 'practice'),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: future == null
              ? const Center(child: Text('Выберите предмет и тему.'))
              : FutureBuilder<List<Assignment>>(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Ошибка: ${snapshot.error}'));
                    }
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return const Center(child: Text('Работ нет.'));
                    }
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                            ),
                          ),
                          child: ListTile(
                            title: Text(item.title),
                            subtitle: Text(
                              item.description ??
                                  'Попытки: ${item.maxAttempts ?? '-'}',
                            ),
                            onTap: () => onAssignmentTap(item),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
