// test_results_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_test_app/services/auth_service.dart';

class TestResultsService {
  final String baseUrl;

  TestResultsService({required this.baseUrl});

  /// Получить результаты по заданию (Teacher)
  Future<Map<String, dynamic>> getAssignmentSubmissions({
    required int assignmentId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception("Unauthorized: no access token");
    }

    final url = Uri.parse(
        '$baseUrl/teacher/submissions?assignment_id=$assignmentId&page=$page&page_size=$pageSize');
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
          "Failed to load test results. Status code: ${response.statusCode}");
    }
  }

  /// Сброс попытки
  Future<bool> resetAttempt({
    required int studentId,
    required int assignmentId,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception("Unauthorized: no access token");
    }

    final url = Uri.parse('$baseUrl/teacher/attempts/reset');
    final body = json.encode({
      "student_id": studentId,
      "assignment_id": assignmentId,
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    return response.statusCode == 200;
  }
}
