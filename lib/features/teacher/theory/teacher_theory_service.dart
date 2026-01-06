import 'package:dio/dio.dart';
import 'package:school_test_app/core/api/api_client.dart';
import 'package:school_test_app/features/common/models/theory_material.dart';

class TeacherTheoryService {
  TeacherTheoryService({ApiClient? apiClient})
      : _client = (apiClient ?? ApiClient()).client;

  final Dio _client;

  Future<List<TheoryMaterial>> fetchTheory({
    int? classId,
    String? subject,
    int? topicId,
  }) async {
    final response = await _client.get(
      '/teacher/theory',
      queryParameters: {
        if (classId != null) 'class_id': classId,
        if (subject != null && subject.isNotEmpty) 'subject': subject,
        if (topicId != null) 'topic_id': topicId,
      },
    );

    final data = _extractList(response.data);
    return data
        .map((item) => TheoryMaterial.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createTheory(Map<String, dynamic> payload) async {
    await _client.post('/teacher/theory', data: payload);
  }

  Future<void> updateTheory(int id, Map<String, dynamic> payload) async {
    await _client.patch('/teacher/theory/$id', data: payload);
  }

  Future<void> deleteTheory(int id) async {
    await _client.delete('/teacher/theory/$id');
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
