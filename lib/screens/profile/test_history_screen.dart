import 'package:flutter/material.dart';
import 'package:school_test_app/models/education_models.dart';
import 'package:school_test_app/models/profile_models.dart';
import 'package:school_test_app/services/auth_service.dart';
import 'package:school_test_app/services/education_service.dart';
import 'package:school_test_app/services/grades_service.dart';
import 'package:school_test_app/services/profile_service.dart';
import 'package:school_test_app/widgets/app_navigator.dart';

class TestHistoryScreen extends StatefulWidget {
  const TestHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TestHistoryScreen> createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  late final GradesService _gradesService;
  late final EducationService _educationService;
  late final ProfileService _profileService;
  late Future<Map<String, dynamic>> _futureData;

  bool _isTeacher = false;
  List<ClassItem> _classes = [];
  List<TopicItem> _topics = [];
  List<SubjectItem> _subjects = [];
  int? _selectedClassId;
  int? _selectedTopicId;
  String? _selectedSubject;
  String _type = 'practice';
  final TextEditingController _teacherSubjectController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _gradesService = GradesService();
    _educationService = EducationService();
    _profileService = ProfileService();
    _futureData = Future.value({});

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
    _loadHistory();
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

  void _loadHistory() {
    final subject = _selectedSubject;
    final classId = _selectedClassId;
    final topicId = _selectedTopicId;
    if (subject == null ||
        subject.isEmpty ||
        (_isTeacher && (classId == null || topicId == null))) {
      setState(() {
        _futureData = Future.value({});
      });
      return;
    }

    setState(() {
      _futureData = _isTeacher
          ? _gradesService.getTeacherGradesByTopic(
              classId: classId ?? 0,
              topicId: topicId ?? 0,
              type: _type,
            )
          : _gradesService.getStudentGrades(subject: subject);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appHeader(_isTeacher ? 'История работ класса' : 'История работ'),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MessageCard(text: 'Ошибка: ${snapshot.error}');
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _FiltersCard(
                isTeacher: _isTeacher,
                classes: _classes,
                subjects: _subjects,
                topics: _topics,
                selectedClassId: _selectedClassId,
                selectedSubject: _selectedSubject,
                selectedTopicId: _selectedTopicId,
                type: _type,
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
                onTypeChanged: (value) {
                  setState(() {
                    _type = value;
                  });
                },
                onApply: _loadHistory,
              ),
              const SizedBox(height: 16),
              _HistoryList(
                isTeacher: _isTeacher,
                data: snapshot.data ?? const {},
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FiltersCard extends StatelessWidget {
  final bool isTeacher;
  final List<ClassItem> classes;
  final List<SubjectItem> subjects;
  final List<TopicItem> topics;
  final int? selectedClassId;
  final String? selectedSubject;
  final int? selectedTopicId;
  final String type;
  final TextEditingController teacherSubjectController;
  final ValueChanged<int?> onClassChanged;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<int?> onTopicChanged;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onApply;

  const _FiltersCard({
    required this.isTeacher,
    required this.classes,
    required this.subjects,
    required this.topics,
    required this.selectedClassId,
    required this.selectedSubject,
    required this.selectedTopicId,
    required this.type,
    required this.teacherSubjectController,
    required this.onClassChanged,
    required this.onSubjectChanged,
    required this.onTopicChanged,
    required this.onTypeChanged,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                label: const Text('Показать'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final bool isTeacher;
  final Map<String, dynamic> data;

  const _HistoryList({required this.isTeacher, required this.data});

  @override
  Widget build(BuildContext context) {
    final items = data['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) {
      return const _MessageCard(text: 'История пуста.');
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: items.map((item) {
            final map = item as Map<String, dynamic>;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(map['assignment_title'] ?? 'Работа'),
              subtitle: Text(
                isTeacher
                    ? (map['student_name'] ?? '')
                    : (map['topic_title'] ?? ''),
              ),
              trailing: Text(
                (map['grade'] ?? '—').toString(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String text;

  const _MessageCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(text, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
