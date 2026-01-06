import 'package:dio/dio.dart';
import 'package:school_test_app/core/api/api_client.dart';
import 'package:school_test_app/features/common/models/topic.dart';

class TeacherTopicsService {
  TeacherTopicsService({ApiClient? apiClient})
      : _client = (apiClient ?? ApiClient()).client;

  final Dio _client;

  Future<List<Topic>> fetchTopics({
    required int classId,
    String? subject,
  }) async {
    final response = await _client.get(
      '/teacher/topics',
      queryParameters: {
        'class_id': classId,
        if (subject != null && subject.isNotEmpty) 'subject': subject,
      },
    );

    final data = _extractList(response.data);
    return data
        .map((item) => Topic.fromJson(item as Map<String, dynamic>))
        .toList();
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
