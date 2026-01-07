import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_test_app/models/question_model.dart';
import 'package:school_test_app/models/test_model.dart';
import 'package:school_test_app/services/auth_service.dart';

class TestsService {
  final String baseUrl;

  TestsService(this.baseUrl);

  /// Получить список работ (учитель)
  Future<List<TestModel>> getTeacherAssignments({
    required int classId,
    required String subject,
    required String type,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token. User not authorized?');
    }

    final url = Uri.parse(
        '$baseUrl/teacher/assignments?class_id=$classId&subject=$subject&type=$type');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TestModel.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to get assignments. Status code: ${response.statusCode}');
    }
  }

  /// Получить список работ (ученик)
  Future<List<TestModel>> getStudentAssignments({
    required String subject,
    required String type,
    int? topicId,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token');
    }

    final topicParam = topicId != null ? '&topic_id=$topicId' : '';
    final url = Uri.parse(
        '$baseUrl/student/assignments?subject=$subject&type=$type$topicParam');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TestModel.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to get student assignments. Status code: ${response.statusCode}');
    }
  }

  /// Получить работу по ID (учитель/ученик)
  Future<TestModel> getAssignmentById(int assignmentId,
      {required bool isTeacher}) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token. User not authorized?');
    }

    final prefix = isTeacher ? 'teacher' : 'student';
    final url = Uri.parse('$baseUrl/$prefix/assignments/$assignmentId');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return TestModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Failed to get assignment. Status code: ${response.statusCode}');
    }
  }

  /// Создать новую работу (учитель)
  Future<TestModel> createAssignment({
    required int classId,
    required String subject,
    required int topicId,
    required String type,
    required String title,
    String? description,
    required int maxAttempts,
    required bool published,
    required List<QuestionModel> questions,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token. User not authorized?');
    }

    final body = jsonEncode({
      'title': title,
      'description': description,
      'class_id': classId,
      'subject': subject,
      'topic_id': topicId,
      'type': type,
      'max_attempts': maxAttempts,
      'published': published,
      'questions': questions.map((q) => q.toJson()).toList(),
    });

    final url = Uri.parse('$baseUrl/teacher/assignments');
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
          'Failed to create assignment. Status code: ${response.statusCode}');
    }
  }

  /// Обновить существующую работу (учитель)
  Future<TestModel> updateAssignment(
    int assignmentId, {
    required int classId,
    required String subject,
    required int topicId,
    required String type,
    required String title,
    String? description,
    required int maxAttempts,
    required bool published,
    required List<QuestionModel> questions,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token. User not authorized?');
    }

    final url = Uri.parse('$baseUrl/teacher/assignments/$assignmentId');
    final body = jsonEncode({
      'title': title,
      'description': description,
      'class_id': classId,
      'subject': subject,
      'topic_id': topicId,
      'type': type,
      'max_attempts': maxAttempts,
      'published': published,
      'questions': questions.map((q) => q.toJson()).toList(),
    });

    final response = await http.patch(
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
          'Failed to update assignment. Status code: ${response.statusCode}');
    }
  }

  /// Удалить работу
  Future<void> deleteAssignment(int assignmentId) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token. User not authorized?');
    }

    final url = Uri.parse('$baseUrl/teacher/assignments/$assignmentId');
    final response = await http.delete(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'Failed to delete assignment. Status code: ${response.statusCode}');
    }
  }

  Future<QuestionModel> addQuestion(int assignmentId, QuestionModel question,
      {required TestModel assignment}) async {
    final updatedQuestions = [...assignment.questions, question];
    final updated = await updateAssignment(
      assignmentId,
      classId: assignment.classId ?? 0,
      subject: assignment.subject ?? '',
      topicId: assignment.topicId ?? 0,
      type: assignment.type ?? 'practice',
      title: assignment.title,
      description: assignment.description,
      maxAttempts: assignment.maxAttempts ?? 1,
      published: assignment.published ?? false,
      questions: updatedQuestions,
    );
    return updated.questions.last;
  }

  Future<QuestionModel> updateQuestion(int assignmentId, QuestionModel question,
      {required TestModel assignment}) async {
    final updatedQuestions = assignment.questions
        .map((q) => q.id == question.id ? question : q)
        .toList();
    await updateAssignment(
      assignmentId,
      classId: assignment.classId ?? 0,
      subject: assignment.subject ?? '',
      topicId: assignment.topicId ?? 0,
      type: assignment.type ?? 'practice',
      title: assignment.title,
      description: assignment.description,
      maxAttempts: assignment.maxAttempts ?? 1,
      published: assignment.published ?? false,
      questions: updatedQuestions,
    );
    return question;
  }

  Future<void> deleteQuestion(int assignmentId, int questionId,
      {required TestModel assignment}) async {
    final updatedQuestions =
        assignment.questions.where((q) => q.id != questionId).toList();
    await updateAssignment(
      assignmentId,
      classId: assignment.classId ?? 0,
      subject: assignment.subject ?? '',
      topicId: assignment.topicId ?? 0,
      type: assignment.type ?? 'practice',
      title: assignment.title,
      description: assignment.description,
      maxAttempts: assignment.maxAttempts ?? 1,
      published: assignment.published ?? false,
      questions: updatedQuestions,
    );
  }

  Future<void> submitAssignment(int assignmentId, Map<String, dynamic> answers) async {
    final token = await AuthService.getAccessToken();
    if (token == null) throw Exception('No access token');

    final url = Uri.parse('$baseUrl/student/assignments/$assignmentId/submit');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'answers': answers}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to submit assignment. Code: ${response.statusCode}');
    }
  }
}
