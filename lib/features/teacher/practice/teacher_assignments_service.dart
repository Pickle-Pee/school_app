import 'package:dio/dio.dart';
import 'package:school_test_app/core/api/api_client.dart';
import 'package:school_test_app/features/common/models/assignment.dart';

class TeacherAssignmentsService {
  TeacherAssignmentsService({ApiClient? apiClient})
      : _client = (apiClient ?? ApiClient()).client;

  final Dio _client;

  Future<List<Assignment>> fetchAssignments({
    int? classId,
    String? subject,
    int? topicId,
    String? type,
  }) async {
    final response = await _client.get(
      '/teacher/assignments',
      queryParameters: {
        if (classId != null) 'class_id': classId,
        if (subject != null && subject.isNotEmpty) 'subject': subject,
        if (topicId != null) 'topic_id': topicId,
        if (type != null && type.isNotEmpty) 'type': type,
      },
    );

    final data = _extractList(response.data);
    return data
        .map((item) => Assignment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createAssignment(Map<String, dynamic> payload) async {
    await _client.post('/teacher/assignments', data: payload);
  }

  Future<void> updateAssignment(int id, Map<String, dynamic> payload) async {
    await _client.patch('/teacher/assignments/$id', data: payload);
  }

  Future<void> deleteAssignment(int id) async {
    await _client.delete('/teacher/assignments/$id');
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
