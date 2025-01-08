// test_results_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_test_app/services/auth_service.dart';

class TestResultsService {
  final String baseUrl;

  TestResultsService({required this.baseUrl});

  /// Получить все результаты по тесту (Teacher)
  /// /teacher/tests/{test_id}/results
  Future<List<dynamic>> getTestResults(int testId) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception("Unauthorized: no access token");
    }

    final url = Uri.parse('$baseUrl/teacher/tests/$testId/results');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Предположим, бэкенд возвращает List[StudentTestResultOut]
      return data as List<dynamic>;
    } else {
      throw Exception(
          "Failed to load test results. Status code: ${response.statusCode}");
    }
  }

  /// Получить детальный результат прохождения
  /// /teacher/tests/{test_id}/results/{result_id}
  Future<Map<String, dynamic>> getTestResultDetail(
      int testId, int resultId) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception("Unauthorized: no access token");
    }

    final url = Uri.parse('$baseUrl/teacher/tests/$testId/results/$resultId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
          "Failed to load test result detail. Status code: ${response.statusCode}");
    }
  }

  /// Выставить/обновить оценку
  /// /teacher/tests/{test_id}/results/{result_id}/grade
  Future<Map<String, dynamic>> setGrade(
      int testId, int resultId, String grade) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception("Unauthorized: no access token");
    }

    final url =
        Uri.parse('$baseUrl/teacher/tests/$testId/results/$resultId/grade');
    final body = json.encode({
      "grade": grade,
    });

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      // Бэкенд возвращает обновлённый StudentTestResultOut
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
          "Failed to set grade. Status code: ${response.statusCode}");
    }
  }
}
