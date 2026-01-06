import 'package:dio/dio.dart';
import 'package:school_test_app/core/api/api_client.dart';
import 'package:school_test_app/features/teacher/profile/models/teacher_profile.dart';

class TeacherProfileService {
  TeacherProfileService({ApiClient? apiClient})
      : _client = (apiClient ?? ApiClient()).client;

  final Dio _client;

  Future<TeacherProfile> fetchProfile() async {
    final response = await _client.get('/teacher/profile');
    final data = response.data as Map<String, dynamic>;
    return TeacherProfile.fromJson(data);
  }
}
