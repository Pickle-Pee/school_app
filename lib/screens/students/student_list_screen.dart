import 'package:flutter/material.dart';
import 'package:school_test_app/screens/profile/test_history_screen.dart';
import 'package:school_test_app/services/teacher_service.dart';
import 'package:school_test_app/models/student_model.dart';
import 'package:school_test_app/config.dart';
import 'package:school_test_app/theme/app_theme.dart';

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({Key? key}) : super(key: key);

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  late final TeacherService _teacherService;
  late Future<List<StudentModel>> _futureStudents;

  @override
  void initState() {
    super.initState();
    _teacherService = TeacherService(Config.baseUrl);
    _futureStudents = _teacherService.listAllStudents();
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
              const _Header(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: FutureBuilder<List<StudentModel>>(
                    future: _futureStudents,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Ошибка: ${snapshot.error}'));
                      }
                      final students = snapshot.data ?? [];
                      if (students.isEmpty) {
                        return const _EmptyState();
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return _StudentCard(student: student);
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
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: const [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white24,
            child: Icon(Icons.groups_rounded, color: Colors.white),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ученики',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentModel student;

  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TestHistoryScreen(studentId: student.id),
              ),
            );
          },
          leading: CircleAvatar(
            backgroundColor: AppTheme.accentColor.withOpacity(0.18),
            child: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
          ),
          title: Text(
            student.email,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            '${student.firstName ?? ''} ${student.lastName ?? ''}'.trim().isEmpty
                ? 'Ученик'
                : '${student.firstName ?? ''} ${student.lastName ?? ''}'.trim(),
            style: const TextStyle(color: Colors.black54),
          ),
          trailing:
              const Icon(Icons.chevron_right_rounded, color: Colors.black38),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_search_rounded,
                color: AppTheme.primaryColor, size: 64),
            const SizedBox(height: 12),
            Text(
              'Пока нет зарегистрированных учеников.',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Пригласите учеников в класс и отслеживайте их результаты.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
