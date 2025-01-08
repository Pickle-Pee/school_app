import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:school_test_app/utils/interceptor.dart';
import 'package:school_test_app/widgets/app_navigator.dart';

/// Экран "Успеваемость" (или "История тестирования")
/// Если [studentId] == null -> ученик смотрит свои результаты (/student/my-results)
/// Если [studentId] != null -> учитель смотрит результаты конкретного ученика (/teacher/student/{id}/results)
class PerformanceScreen extends StatefulWidget {
  final int? studentId;

  const PerformanceScreen({Key? key, this.studentId}) : super(key: key);

  @override
  _PerformanceScreenState createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  bool _isLoading = false;
  String? _error;

  // Список "результатов", каждый результат — Map (получаем из JSON)
  List<Map<String, dynamic>> _allResults = [];

  @override
  void initState() {
    super.initState();
    _fetchPerformanceData();
  }

  Future<void> _fetchPerformanceData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final String endpoint;
      if (widget.studentId == null) {
        // Ученик
        endpoint = '/student/my-results';
      } else {
        // Учитель
        endpoint = '/teacher/student/${widget.studentId}/results';
      }

      // Пример: ApiInterceptor.get(baseUrl + endpoint)
      final response = await ApiInterceptor.get(endpoint);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _allResults =
              data.map((item) => Map<String, dynamic>.from(item)).toList();
        });
      } else {
        setState(() {
          _error = 'Ошибка загрузки: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.studentId != null;

    return Scaffold(
      appBar: appHeader(isTeacher ? 'Результаты ученика' : 'Мои результаты'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    // Разделяем результаты на testResults (test_id != null) и examResults (exam_id != null)
    final testResults = _allResults.where((r) => r['test_id'] != null).toList();
    final examResults = _allResults.where((r) => r['exam_id'] != null).toList();

    // Можно сортировать по дате (r['created_at']) при желании.
    // testResults.sort(...)  examResults.sort(...)

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: (testResults.isEmpty && examResults.isEmpty)
          ? const Center(child: Text('Нет результатов'))
          : ListView(
              children: [
                // Раздел "Упражнения"
                ExpansionTile(
                  title: const Text('Упражнения (тесты)'),
                  initiallyExpanded: true,
                  children:
                      testResults.map((r) => _buildResultTile(r)).toList(),
                ),
                const SizedBox(height: 16),
                // Раздел "Экзамены"
                ExpansionTile(
                  title: const Text('Экзамены'),
                  initiallyExpanded: false,
                  children:
                      examResults.map((r) => _buildResultTile(r)).toList(),
                ),
              ],
            ),
    );
  }

  Widget _buildResultTile(Map<String, dynamic> result) {
    // result содержит:
    // {
    //   "id": int,
    //   "student_id": int,
    //   "test_id": int or null,
    //   "exam_id": int or null,
    //   "score": double,
    //   "final_grade": String?,
    //   "grade": int?,
    //   "subject": String?,
    //   "created_at": "2023-10-10T12:00:00"
    // }
    final subject = result['subject'] ?? '';
    final score = (result['score'] ?? 0).toString();
    final finalGrade = result['final_grade'] ?? '';
    final gradeClass = result['grade']?.toString() ?? '';
    final createdAt = result['created_at'] ?? '';

    return ListTile(
      title: Text('Предмет: $subject'),
      subtitle:
          Text('Класс: $gradeClass\nОценка: $finalGrade\nПроцент: $score%'),
      trailing: Text('$createdAt', style: const TextStyle(fontSize: 12)),
    );
  }
}
