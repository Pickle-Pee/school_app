// student_test_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_test_app/services/auth_service.dart';

class StudentTestService {
  final String baseUrl;

  StudentTestService({required this.baseUrl});

  /// Ученик отправляет результаты прохождения задания
  /// [assignmentId] - ID задания
  /// [answers] - карта ответов: { "q1": "A", "q2": ["x"], "q3": "text" }
  Future<Map<String, dynamic>> submitAssignment(
      int assignmentId, Map<String, dynamic> answers) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception("Unauthorized: no access token");
    }

    final url = Uri.parse('$baseUrl/student/assignments/$assignmentId/submit');
    final body = json.encode({
      "answers": answers,
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // При успехе бэкенд возвращает объект результата
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
          "Failed to submit assignment. Status code: ${response.statusCode}");
    }
  }
}
