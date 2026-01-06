import 'package:dio/dio.dart';
import 'package:school_test_app/core/api/api_client.dart';
import 'package:school_test_app/features/common/models/submission.dart';

class TeacherSubmissionsService {
  TeacherSubmissionsService({ApiClient? apiClient})
      : _client = (apiClient ?? ApiClient()).client;

  final Dio _client;

  Future<List<Submission>> fetchSubmissions({
    required int assignmentId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get(
      '/teacher/submissions',
      queryParameters: {
        'assignment_id': assignmentId,
        'page': page,
        'page_size': pageSize,
      },
    );

    final data = _extractList(response.data);
    return data
        .map((item) => Submission.fromJson(item as Map<String, dynamic>))
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
