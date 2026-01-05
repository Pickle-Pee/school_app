import 'package:dio/dio.dart';
import 'package:school_test_app/core/api/api_client.dart';
import 'package:school_test_app/features/student/profile/models/student_profile.dart';

class StudentProfileService {
  StudentProfileService({ApiClient? apiClient})
      : _client = (apiClient ?? ApiClient()).client;

  final Dio _client;

  Future<StudentProfile> fetchProfile() async {
    final response = await _client.get('/student/profile');
    final data = response.data as Map<String, dynamic>;
    return StudentProfile.fromJson(data);
  }
}
