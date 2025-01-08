import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_test_app/models/student_model.dart';
import 'package:school_test_app/services/auth_service.dart';

class TeacherService {
  final String baseUrl;

  TeacherService(this.baseUrl);

  /// Получить список всех учеников (только для учителя)
  Future<List<StudentModel>> listAllStudents() async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception("No access token. Not authorized as teacher?");
    }

    final url = Uri.parse("$baseUrl/teacher/students");
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((jsonItem) => StudentModel.fromJson(jsonItem)).toList();
    } else {
      throw Exception("Failed to load students. Code: ${response.statusCode}");
    }
  }
}
