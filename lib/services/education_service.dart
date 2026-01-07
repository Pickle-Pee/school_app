import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_test_app/config.dart';
import 'package:school_test_app/models/education_models.dart';
import 'package:school_test_app/services/auth_service.dart';

class EducationService {
  Future<List<ClassItem>> getTeacherClasses() async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token. User not authorized?');
    }

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/teacher/classes'),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load classes. Code: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => ClassItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<TopicItem>> getTeacherTopics({
    required int classId,
    required String subject,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token. User not authorized?');
    }

    final response = await http.get(
      Uri.parse(
          '${Config.baseUrl}/teacher/topics?class_id=$classId&subject=$subject'),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load topics. Code: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => TopicItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<SubjectItem>> getStudentSubjects() async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token. User not authorized?');
    }

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/student/subjects'),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load subjects. Code: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => SubjectItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<TopicItem>> getStudentTopics({
    required String subject,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token. User not authorized?');
    }

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/student/topics?subject=$subject'),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load topics. Code: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => TopicItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
