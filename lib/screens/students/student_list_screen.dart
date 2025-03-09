import 'package:flutter/material.dart';
import 'package:school_test_app/screens/profile/test_history_screen.dart';
import 'package:school_test_app/services/teacher_service.dart';
import 'package:school_test_app/models/student_model.dart';
import 'package:school_test_app/config.dart';

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
      appBar: AppBar(
        title: const Text('Список учеников'),
      ),
      body: FutureBuilder<List<StudentModel>>(
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
            return const Center(
              child: Text('Пока нет зарегистрированных учеников.'),
            );
          }
          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return ListTile(
                title: Text(student.email),
                subtitle: Text(
                    '${student.firstName ?? ''} ${student.lastName ?? ''}'),
                onTap: () {
                  // При нажатии переходим к экрану истории тестирования выбранного ученика,
                  // передавая student.id в качестве параметра studentId
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TestHistoryScreen(studentId: student.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
