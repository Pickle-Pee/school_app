import 'package:dio/dio.dart';
import 'package:school_test_app/core/api/api_client.dart';
import 'package:school_test_app/features/common/models/assignment.dart';
import 'package:school_test_app/features/common/models/subject.dart';
import 'package:school_test_app/features/common/models/theory_material.dart';
import 'package:school_test_app/features/common/models/topic.dart';

class StudentSubjectService {
  StudentSubjectService({ApiClient? apiClient})
      : _client = (apiClient ?? ApiClient()).client;

  final Dio _client;

  Future<List<Subject>> fetchSubjects() async {
    final response = await _client.get('/student/subjects');
    final data = _extractList(response.data);
    return data
        .map((item) => Subject.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Topic>> fetchTopics({required String subject}) async {
    final response = await _client.get(
      '/student/topics',
      queryParameters: {'subject': subject},
    );
    final data = _extractList(response.data);
    return data
        .map((item) => Topic.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<TheoryMaterial>> fetchTheory({
    required String subject,
    int? topicId,
  }) async {
    final response = await _client.get(
      '/student/theory',
      queryParameters: {
        'subject': subject,
        if (topicId != null) 'topic_id': topicId,
      },
    );
    final data = _extractList(response.data);
    return data
        .map((item) => TheoryMaterial.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Assignment>> fetchAssignments({
    required String subject,
    String? type,
    int? topicId,
  }) async {
    final response = await _client.get(
      '/student/assignments',
      queryParameters: {
        'subject': subject,
        if (type != null && type.isNotEmpty) 'type': type,
        if (topicId != null) 'topic_id': topicId,
      },
    );
    final data = _extractList(response.data);
    return data
        .map((item) => Assignment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> fetchAssignmentDetail(int id) async {
    final response = await _client.get('/student/assignments/$id');
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

  Future<void> submitAssignment({
    required int id,
    required dynamic answers,
  }) async {
    await _client.post(
      '/student/assignments/$id/submit',
      data: {'answers': answers},
    );
  }

  Future<List<Map<String, dynamic>>> fetchGrades({
    required String subject,
  }) async {
    final response = await _client.get(
      '/student/grades',
      queryParameters: {'subject': subject},
    );
    final data = _extractList(response.data);
    return data.cast<Map<String, dynamic>>();
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
