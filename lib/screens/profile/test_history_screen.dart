import 'package:flutter/material.dart';
import 'package:school_test_app/widgets/app_navigator.dart';

/// Экран "История работ/результатов".
/// Если [studentId] == null -> ученик смотрит свои результаты (/student/my-results).
/// Если [studentId] != null -> учитель смотрит результаты выбранного ученика (/teacher/student/{id}/results).
class TestHistoryScreen extends StatefulWidget {
  final int? studentId;

  const TestHistoryScreen({Key? key, this.studentId}) : super(key: key);

  @override
  _TestHistoryScreenState createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    // Если передан studentId, значит экран открывает учитель
    final isTeacher = widget.studentId != null;

    return Scaffold(
      appBar: appHeader(isTeacher ? 'Результаты ученика' : 'История работ'),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'История работ будет доступна после подключения нового API.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
