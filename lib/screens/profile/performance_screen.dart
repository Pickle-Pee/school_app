import 'package:flutter/material.dart';
import 'package:school_test_app/models/education_models.dart';
import 'package:school_test_app/models/profile_models.dart';
import 'package:school_test_app/services/auth_service.dart';
import 'package:school_test_app/services/education_service.dart';
import 'package:school_test_app/services/grades_service.dart';
import 'package:school_test_app/services/profile_service.dart';
import 'package:school_test_app/widgets/app_navigator.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({Key? key}) : super(key: key);

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  late final GradesService _gradesService;
  late final EducationService _educationService;
  late final ProfileService _profileService;
  late Future<Map<String, dynamic>> _futureData;

  bool _isTeacher = false;
  List<ClassItem> _classes = [];
  List<SubjectItem> _subjects = [];
  int? _selectedClassId;
  String? _selectedSubject;
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
    _loadGrades();
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
    } else {
      final subjects = await _educationService.getStudentSubjects();
      setState(() {
        _subjects = subjects;
        _selectedSubject = subjects.isNotEmpty ? subjects.first.name : null;
      });
    }
  }

  void _loadGrades() {
    final subject = _selectedSubject;
    if (subject == null || subject.isEmpty) {
      setState(() {
        _futureData = Future.value({});
      });
      return;
    }

    setState(() {
      _futureData = _isTeacher
          ? _gradesService.getTeacherSummary(
              classId: _selectedClassId ?? 0,
              subject: subject,
            )
          : _gradesService.getStudentGrades(subject: subject);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appHeader(_isTeacher ? 'Успеваемость класса' : 'Моя успеваемость'),
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
                selectedClassId: _selectedClassId,
                selectedSubject: _selectedSubject,
                teacherSubjectController: _teacherSubjectController,
                onClassChanged: (value) {
                  setState(() {
                    _selectedClassId = value;
                  });
                },
                onSubjectChanged: (value) {
                  setState(() {
                    _selectedSubject = value;
                  });
                },
                onApply: _loadGrades,
              ),
              const SizedBox(height: 16),
              if (_isTeacher)
                _TeacherSummary(data: snapshot.data ?? const {})
              else
                _StudentSummary(data: snapshot.data ?? const {}),
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
  final int? selectedClassId;
  final String? selectedSubject;
  final TextEditingController teacherSubjectController;
  final ValueChanged<int?> onClassChanged;
  final ValueChanged<String?> onSubjectChanged;
  final VoidCallback onApply;

  const _FiltersCard({
    required this.isTeacher,
    required this.classes,
    required this.subjects,
    required this.selectedClassId,
    required this.selectedSubject,
    required this.teacherSubjectController,
    required this.onClassChanged,
    required this.onSubjectChanged,
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

class _TeacherSummary extends StatelessWidget {
  final Map<String, dynamic> data;

  const _TeacherSummary({required this.data});

  @override
  Widget build(BuildContext context) {
    final classInfo = data['class'] as Map<String, dynamic>? ?? {};
    final students = data['students'] as List<dynamic>? ?? [];
    if (students.isEmpty) {
      return const _MessageCard(text: 'Нет данных по классу.');
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Класс: ${classInfo['name'] ?? '—'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...students.map(
              (item) {
                final map = item as Map<String, dynamic>;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(map['full_name'] ?? map['student_name'] ?? '—'),
                  trailing: Text(
                    (map['avg_grade'] ?? '—').toString(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentSummary extends StatelessWidget {
  final Map<String, dynamic> data;

  const _StudentSummary({required this.data});

  @override
  Widget build(BuildContext context) {
    final avg = data['avg_grade'];
    final items = data['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) {
      return const _MessageCard(text: 'Нет данных по предмету.');
    }

    return Column(
      children: [
        if (avg != null)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              title: const Text('Средний балл'),
              trailing: Text(
                avg.toString(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: items.map((item) {
                final map = item as Map<String, dynamic>;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(map['assignment_title'] ?? 'Работа'),
                  subtitle: Text(map['topic_title'] ?? ''),
                  trailing: Text(
                    (map['grade'] ?? '—').toString(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
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
