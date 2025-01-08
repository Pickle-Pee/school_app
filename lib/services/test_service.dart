import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_test_app/models/question_model.dart';
import 'package:school_test_app/models/test_model.dart';
import 'package:school_test_app/services/auth_service.dart';

class TestsService {
  final String baseUrl;

  TestsService(this.baseUrl);

  /// Получить список тестов (принадлежащих учителю)
  Future<List<TestModel>> getMyTests() async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token. User not authorized?');
    }

    final url = Uri.parse('$baseUrl/tests');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TestModel.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to get tests. Status code: ${response.statusCode}');
    }
  }

  /// Создать новый тест (с поддержкой grade/subject)
  Future<TestModel> createTest(
    String title,
    String description,
    int? grade,
    String? subject,
  ) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token');
    }

    final body = jsonEncode({
      'title': title,
      'description': description,
      'grade': grade,
      'subject': subject,
    });

    final url = Uri.parse('$baseUrl/tests');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return TestModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Failed to create test. Status code: ${response.statusCode}');
    }
  }

  /// Получить тест по ID (вместе с вопросами, если бэкенд так отдаёт)
  Future<TestModel> getTestById(int testId) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token. User not authorized?');
    }

    final url = Uri.parse('$baseUrl/tests/$testId');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return TestModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Failed to get test. Status code: ${response.statusCode}');
    }
  }

  /// Обновить существующий тест (с поддержкой grade/subject)
  Future<TestModel> updateTest(
    int testId,
    String? title,
    String? description,
    int? grade,
    String? subject,
  ) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token. User not authorized?');
    }

    final url = Uri.parse('$baseUrl/tests/$testId');
    final body = jsonEncode({
      'title': title,
      'description': description,
      'grade': grade,
      'subject': subject,
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
      return TestModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Failed to update test. Status code: ${response.statusCode}');
    }
  }

  /// Удалить тест
  Future<void> deleteTest(int testId) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token. User not authorized?');
    }

    final url = Uri.parse('$baseUrl/tests/$testId');
    final response = await http.delete(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'Failed to delete test. Status code: ${response.statusCode}');
    }
  }

  // ------------------------------------------------
  // Работа с вопросами
  // ------------------------------------------------

  /// Добавить новый вопрос в тест
  Future<QuestionModel> addQuestion(int testId, QuestionModel question) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token. User not authorized?');
    }

    final url = Uri.parse('$baseUrl/tests/$testId/questions');
    final body = jsonEncode({
      'question_type': question.questionType,
      'question_text': question.questionText,
      'options': question.options,
      'correct_answers': question.correctAnswers,
      'text_answer': question.textAnswer,
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
      return QuestionModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Failed to add question. Status code: ${response.statusCode}');
    }
  }

  /// Обновить существующий вопрос
  Future<QuestionModel> updateQuestion(
      int testId, QuestionModel question) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token. User not authorized?');
    }

    final url = Uri.parse('$baseUrl/tests/$testId/questions/${question.id}');
    final body = jsonEncode({
      'question_type': question.questionType,
      'question_text': question.questionText,
      'options': question.options,
      'correct_answers': question.correctAnswers,
      'text_answer': question.textAnswer,
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
      return QuestionModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Failed to update question. Status code: ${response.statusCode}');
    }
  }

  /// Удалить вопрос
  Future<void> deleteQuestion(int testId, int questionId) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token. User not authorized?');
    }

    final url = Uri.parse('$baseUrl/tests/$testId/questions/$questionId');
    final response = await http.delete(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'Failed to delete question. Status code: ${response.statusCode}');
    }
  }

  Future<void> submitTest(Map<String, dynamic> body) async {
    final token = await AuthService.getAccessToken();
    if (token == null) throw Exception('No access token');

    final url = Uri.parse('$baseUrl/student/submit-test');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to submit test. Code: ${response.statusCode}');
    }
  }
}
