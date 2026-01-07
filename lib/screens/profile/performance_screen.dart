import 'package:flutter/material.dart';
import 'package:school_test_app/widgets/app_navigator.dart';

/// Экран "Успеваемость" (или "История работ")
/// Если [studentId] == null -> ученик смотрит свои результаты (/student/my-results)
/// Если [studentId] != null -> учитель смотрит результаты конкретного ученика (/teacher/student/{id}/results)
class PerformanceScreen extends StatefulWidget {
  final int? studentId;

  const PerformanceScreen({Key? key, this.studentId}) : super(key: key);

  @override
  _PerformanceScreenState createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.studentId != null;

    return Scaffold(
      appBar: appHeader(isTeacher ? 'Результаты ученика' : 'Мои результаты'),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Раздел успеваемости будет доступен после подключения нового API.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
