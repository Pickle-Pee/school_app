// student_test_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_test_app/services/auth_service.dart';

class StudentTestService {
  final String baseUrl;

  StudentTestService({required this.baseUrl});

  /// Ученик отправляет результаты прохождения теста
  /// [testId] - ID теста
  /// [answers] - список ответов в формате:
  ///   [
  ///     {
  ///       "question_id": 1,
  ///       "chosen_options": ["A", "B"],  // для multiple_choice
  ///       "text_input": "Мой ответ"      // для text_input
  ///     },
  ///     ...
  ///   ]
  ///
  /// Пример использования:
  ///   submitTest(5, [
  ///     {
  ///       "question_id": 10,
  ///       "chosen_options": ["1", "3"],
  ///     },
  ///     {
  ///       "question_id": 11,
  ///       "text_input": "Hello!"
  ///     }
  ///   ]);
  Future<Map<String, dynamic>> submitTest(
      int testId, List<Map<String, dynamic>> answers) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception("Unauthorized: no access token");
    }

    final url = Uri.parse('$baseUrl/student/submit-test');
    final body = json.encode({
      "test_id": testId,
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
      // При успехе бэкенд возвращает объект результата (StudentTestResultOut)
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
          "Failed to submit test. Status code: ${response.statusCode}");
    }
  }
}
