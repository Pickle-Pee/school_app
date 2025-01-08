import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:school_test_app/utils/interceptor.dart';
import 'package:school_test_app/widgets/app_navigator.dart';

/// Экран "История тестирования/результатов".
/// Если [studentId] == null -> ученик смотрит свои результаты (/student/my-results).
/// Если [studentId] != null -> учитель смотрит результаты конкретного ученика (/teacher/student/{id}/results).
class TestHistoryScreen extends StatefulWidget {
  final int? studentId;

  const TestHistoryScreen({Key? key, this.studentId}) : super(key: key);

  @override
  _TestHistoryScreenState createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  bool _isLoading = false;
  String? _error;

  /// Список результатов, каждый элемент - Map<String, dynamic>,
  ///   содержащий: { test_id, exam_id, subject, grade, score, final_grade, created_at, ... }
  List<Map<String, dynamic>> _allResults = [];

  @override
  void initState() {
    super.initState();
    _fetchTestHistory();
  }

  Future<void> _fetchTestHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Определяем, какой endpoint вызывать
      final endpoint = (widget.studentId == null)
          ? '/student/my-results'
          : '/teacher/student/${widget.studentId}/results';

      final response = await ApiInterceptor.get(endpoint);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _allResults = data.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } else {
        setState(() {
          _error = 'Ошибка: ${response.statusCode}';
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
    // Если studentId != null => учитель
    final isTeacher = widget.studentId != null;

    return Scaffold(
      appBar:
          appHeader(isTeacher ? 'Результаты ученика' : 'История тестирования'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? Center(child: Text(_error!))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    // Разделяем результаты на testResults (test_id != null) и examResults (exam_id != null)
    final testResults = _allResults.where((r) => r['test_id'] != null).toList();
    final examResults = _allResults.where((r) => r['exam_id'] != null).toList();

    if (testResults.isEmpty && examResults.isEmpty) {
      return const Center(child: Text('Нет результатов'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          // Раздел "Тесты (упражнения)"
          ExpansionTile(
            title: const Text('Тесты (упражнения)'),
            initiallyExpanded: true,
            children: testResults.map((res) => _buildResultItem(res)).toList(),
          ),
          const SizedBox(height: 16),
          // Раздел "Экзамены"
          ExpansionTile(
            title: const Text('Экзамены'),
            children: examResults.map((res) => _buildResultItem(res)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(Map<String, dynamic> result) {
    final subject = result['subject']?.toString() ?? '';
    final grade = result['grade']?.toString() ?? '';
    final score = result['score']?.toString() ?? '';
    final finalGrade = result['final_grade']?.toString() ?? '';
    final createdAt = result['created_at']?.toString() ?? '';

    return ListTile(
      title: Text('Предмет: $subject'),
      subtitle: Text(
        'Класс: $grade\nОценка: $finalGrade\nПроцент: $score%',
      ),
      trailing: Text(
        createdAt.split('T').join(' '),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
