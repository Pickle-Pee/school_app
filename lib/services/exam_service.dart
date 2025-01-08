// services/exams_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_test_app/models/exam_models.dart';
import 'package:school_test_app/services/auth_service.dart';

class ExamsService {
  final String baseUrl;

  ExamsService(this.baseUrl);

  /// Получить список экзаменов
  /// Если учитель - вернёт экзамены учителя, если ученик - все (по бэкенду)
  Future<List<ExamModel>> getExams() async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token');
    }

    final url = Uri.parse('$baseUrl/exams');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => ExamModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load exams. Code: ${response.statusCode}');
    }
  }

  /// Создать экзамен (учитель)
  Future<ExamModel> createExam({
    required String title,
    String? description,
    int? grade,
    String? subject,
    int? timeLimitMinutes,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token');
    }

    final url = Uri.parse('$baseUrl/exams');
    final body = json.encode({
      'title': title,
      'description': description,
      'grade': grade,
      'subject': subject,
      'time_limit_minutes': timeLimitMinutes,
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
      return ExamModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create exam. Code: ${response.statusCode}');
    }
  }

  Future<void> submitExam(Map<String, dynamic> body) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token');
    }

    final url = Uri.parse('$baseUrl/student/exams/submit');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body), // <-- ВАЖНО
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit exam. Code: ${response.statusCode}');
    }
  }

  /// Получить один экзамен
  Future<ExamModel> getExamById(int examId) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token');
    }

    final url = Uri.parse('$baseUrl/exams/$examId');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      return ExamModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get exam. Code: ${response.statusCode}');
    }
  }

  /// Обновить экзамен (учитель)
  Future<ExamModel> updateExam({
    required int examId,
    required String title,
    String? description,
    int? grade,
    String? subject,
    int? timeLimitMinutes,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token');
    }

    final url = Uri.parse('$baseUrl/exams/$examId');
    final body = json.encode({
      'title': title,
      'description': description,
      'grade': grade,
      'subject': subject,
      'time_limit_minutes': timeLimitMinutes,
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
      return ExamModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update exam. Code: ${response.statusCode}');
    }
  }

  /// Удалить экзамен (учитель)
  Future<void> deleteExam(int examId) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token');
    }

    final url = Uri.parse('$baseUrl/exams/$examId');
    final response = await http.delete(url, headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete exam. Code: ${response.statusCode}');
    }
  }

  // ---- Вопросы (опционально) ----
  Future<ExamQuestionModel> addQuestion(
    int examId, {
    required String questionType,
    required String questionText,
    List<String>? options,
    List<String>? correctAnswers,
    String? textAnswer,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) throw Exception('No access token');

    final url = Uri.parse('$baseUrl/exams/$examId/questions');
    final body = json.encode({
      'question_type': questionType,
      'question_text': questionText,
      'options': options,
      'correct_answers': correctAnswers,
      'text_answer': textAnswer,
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
      return ExamQuestionModel.fromJson(json.decode(response.body));
    } else {
      throw Exception(
          'Failed to add exam question. Code: ${response.statusCode}');
    }
  }

  // ... updateQuestion, deleteQuestion аналогично
}
