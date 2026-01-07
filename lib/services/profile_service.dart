import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_test_app/config.dart';
import 'package:school_test_app/models/profile_models.dart';
import 'package:school_test_app/services/auth_service.dart';

class ProfileService {
  Future<ProfileView> getProfile() async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('No access token. User not authorized?');
    }

    final meResponse = await http.get(
      Uri.parse('${Config.baseUrl}/me'),
      headers: {"Authorization": "Bearer $token"},
    );
    if (meResponse.statusCode != 200) {
      throw Exception('Failed to load /me. Code: ${meResponse.statusCode}');
    }

    final meData = jsonDecode(meResponse.body) as Map<String, dynamic>;
    final role = meData['role'] as String? ?? 'student';

    if (role == 'teacher') {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/teacher/profile'),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to load teacher profile. Code: ${response.statusCode}');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ProfileView.fromTeacher(TeacherProfile.fromJson(data));
    }

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/student/profile'),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load student profile. Code: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ProfileView.fromStudent(StudentProfile.fromJson(data));
  }
}
