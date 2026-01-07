import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_test_app/config.dart';
import 'package:school_test_app/services/auth_service.dart';

class GradesService {
  Future<Map<String, dynamic>> getTeacherSummary({
    required int classId,
    required String subject,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token. User not authorized?');
    }

    final response = await http.get(
      Uri.parse(
          '${Config.baseUrl}/teacher/grades/summary?class_id=$classId&subject=$subject'),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load summary. Code: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTeacherGradesByTopic({
    required int classId,
    required int topicId,
    required String type,
    int page = 1,
    int pageSize = 20,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token. User not authorized?');
    }

    final response = await http.get(
      Uri.parse(
          '${Config.baseUrl}/teacher/grades/by-topic?class_id=$classId&topic_id=$topicId&type=$type&page=$page&page_size=$pageSize'),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load grades. Code: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getStudentGrades({
    required String subject,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token. User not authorized?');
    }

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/student/grades?subject=$subject'),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load grades. Code: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
