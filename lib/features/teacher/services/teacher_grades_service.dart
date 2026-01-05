import 'package:dio/dio.dart';
import 'package:school_test_app/core/api/api_client.dart';
import 'package:school_test_app/features/teacher/classes/models/class_group.dart';

class TeacherGradesService {
  TeacherGradesService({ApiClient? apiClient})
      : _client = (apiClient ?? ApiClient()).client;

  final Dio _client;

  Future<List<ClassGroup>> fetchClasses() async {
    final response = await _client.get('/teacher/classes');
    final data = _extractList(response.data);
    return data
        .map((item) => ClassGroup.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchGradesSummary({
    required int classId,
    String? subject,
  }) async {
    final response = await _client.get(
      '/teacher/grades/summary',
      queryParameters: {
        'class_id': classId,
        if (subject != null && subject.isNotEmpty) 'subject': subject,
      },
    );
    final data = _extractList(response.data);
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchGradesByTopic({
    required int classId,
    required int topicId,
    required String type,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get(
      '/teacher/grades/by-topic',
      queryParameters: {
        'class_id': classId,
        'topic_id': topicId,
        'type': type,
        'page': page,
        'page_size': pageSize,
      },
    );
    final data = _extractList(response.data);
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> resetAttempts({
    required int studentId,
    required int assignmentId,
  }) async {
    await _client.post(
      '/teacher/attempts/reset',
      data: {
        'student_id': studentId,
        'assignment_id': assignmentId,
      },
    );
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List<dynamic>) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      final items = data['items'];
      if (items is List<dynamic>) {
        return items;
      }
    }
    return [];
  }
}
