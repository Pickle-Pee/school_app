import 'package:flutter/material.dart';
import 'package:school_test_app/models/exam_models.dart';
import 'package:school_test_app/screens/exams/student/test_exam_screen.dart';
import 'package:school_test_app/screens/exams/teacher/create_exam_screen.dart';
import 'package:school_test_app/services/exam_service.dart';
import 'package:school_test_app/services/auth_service.dart';
import 'package:school_test_app/config.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({Key? key}) : super(key: key);

  @override
  _ExamsScreenState createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  late final ExamsService _examsService;
  late Future<List<ExamModel>> _futureExams;

  bool _isTeacher = false;

  @override
  void initState() {
    super.initState();
    _examsService = ExamsService(Config.baseUrl);
    _checkUserType();
    _loadExams();
  }

  Future<void> _checkUserType() async {
    final role = await AuthService.getUserType();
    setState(() {
      _isTeacher = (role == 'teacher');
    });
  }

  void _loadExams() {
    setState(() {
      _futureExams = _examsService.getExams();
    });
  }

  void _onCreateExam() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateExamScreen()),
    );
    if (created == true) {
      _loadExams();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Экзамены'),
      ),
      body: FutureBuilder<List<ExamModel>>(
        future: _futureExams,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          final exams = snapshot.data ?? [];
          if (exams.isEmpty) {
            return const Center(child: Text('Пока нет экзаменов.'));
          }
          return ListView.builder(
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final exam = exams[index];
              return ListTile(
                title: Text(exam.title),
                subtitle: Text(exam.description ?? ''),
                // Нажатие:
                onTap: () {
                  if (_isTeacher) {
                    // учитель -> редактирование
                    // Navigator.push(... ExamDetailScreen or smth)
                  } else {
                    // ученик -> прохождение
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TakeExamScreen(examId: exam.id),
                      ),
                    );
                  }
                },
                // Удалить - только учитель
                trailing: _isTeacher
                    ? IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          try {
                            await _examsService.deleteExam(exam.id);
                            _loadExams();
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
      // кнопка создания - только учитель
      floatingActionButton: _isTeacher
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: _onCreateExam,
            )
          : null,
    );
  }
}
