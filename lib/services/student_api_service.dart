import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:school_test_app/config.dart';
import 'package:school_test_app/utils/session_manager.dart';

/// GET  /profile
/// GET  /subjects
/// GET  /topics?subject=...
/// GET  /theory?subject=...&topic_id=...
/// GET  /assignments?subject=...&type=...&topic_id=...
/// GET  /assignments/{assignment_id}
/// POST /assignments/{assignment_id}/submit
/// GET  /grades?subject=...
class StudentApiService {
  static String _base() => Config.baseUrl;

  static Uri _uri(String path, [Map<String, dynamic>? query]) {
    final qp = <String, String>{};
    if (query != null) {
      for (final e in query.entries) {
        if (e.value == null) continue;
        qp[e.key] = e.value.toString();
      }
    }
    return Uri.parse("${_base()}$path")
        .replace(queryParameters: qp.isEmpty ? null : qp);
  }

  static Future<Map<String, String>> _authHeaders(
      {bool jsonBody = false}) async {
    final token = await SessionManager.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception("Нет access_token. Сначала выполните логин.");
    }
    final headers = <String, String>{
      "Authorization": "Bearer $token",
    };
    if (jsonBody) headers["Content-Type"] = "application/json";
    return headers;
  }

  static dynamic _decode(http.Response resp) {
    if (resp.body.isEmpty) return null;
    try {
      return json.decode(utf8.decode(resp.bodyBytes));
    } catch (_) {
      return resp.body;
    }
  }

  static Exception _httpError(http.Response resp) {
    final decoded = _decode(resp);
    return Exception("HTTP ${resp.statusCode}: $decoded");
  }

  /// GET /profile
  static Future<Map<String, dynamic>> getProfile() async {
    final resp = await http.get(
      _uri("/profile"),
      headers: await _authHeaders(),
    );

    if (resp.statusCode == 200) {
      return Map<String, dynamic>.from(_decode(resp) as Map);
    }
    throw _httpError(resp);
  }

  /// GET /subjects
  static Future<List<dynamic>> getSubjects() async {
    final resp = await http.get(
      _uri("/subjects"),
      headers: await _authHeaders(),
    );

    if (resp.statusCode == 200) {
      return List<dynamic>.from(_decode(resp) as List);
    }
    throw _httpError(resp);
  }

  /// GET /topics?subject=...
  static Future<List<dynamic>> getTopics({required String subject}) async {
    final resp = await http.get(
      _uri("/topics", {"subject": subject}),
      headers: await _authHeaders(),
    );

    if (resp.statusCode == 200) {
      return List<dynamic>.from(_decode(resp) as List);
    }
    throw _httpError(resp);
  }

  /// GET /theory?subject=...&topic_id=...
  static Future<List<dynamic>> getTheory({
    required String subject,
    required int topicId,
  }) async {
    final resp = await http.get(
      _uri("/theory", {"subject": subject, "topic_id": topicId}),
      headers: await _authHeaders(),
    );

    if (resp.statusCode == 200) {
      return List<dynamic>.from(_decode(resp) as List);
    }
    throw _httpError(resp);
  }

  /// GET /assignments?subject=...&type=...&topic_id=...
  /// type: значения должны совпадать с AssignmentType на бэке (например: "practice", "test", ...)
  static Future<List<dynamic>> getAssignments({
    required String subject,
    required String type,
    required int topicId,
  }) async {
    final resp = await http.get(
      _uri("/assignments",
          {"subject": subject, "type": type, "topic_id": topicId}),
      headers: await _authHeaders(),
    );

    if (resp.statusCode == 200) {
      return List<dynamic>.from(_decode(resp) as List);
    }
    throw _httpError(resp);
  }

  /// GET /assignments/{assignment_id}
  static Future<Map<String, dynamic>> getAssignmentDetail({
    required int assignmentId,
  }) async {
    final resp = await http.get(
      _uri("/assignments/$assignmentId"),
      headers: await _authHeaders(),
    );

    if (resp.statusCode == 200) {
      return Map<String, dynamic>.from(_decode(resp) as Map);
    }
    throw _httpError(resp);
  }

  static Future<Map<String, dynamic>> submitAssignment({
  required int assignmentId,
  required Map<String, dynamic> answers, // keys: q1, q2, ...
}) async {
  final resp = await http.post(
    _uri("/assignments/$assignmentId/submit"),
    headers: await _authHeaders(jsonBody: true),
    body: json.encode({"answers": answers}),
  );

  if (resp.statusCode == 200) {
    return Map<String, dynamic>.from(_decode(resp) as Map);
  }
  throw _httpError(resp);
}


  /// GET /grades?subject=...
  static Future<Map<String, dynamic>> getGrades(
      {required String subject}) async {
    final resp = await http.get(
      _uri("/grades", {"subject": subject}),
      headers: await _authHeaders(),
    );

    if (resp.statusCode == 200) {
      return Map<String, dynamic>.from(_decode(resp) as Map);
    }
    throw _httpError(resp);
  }

  static String resolveFileUrl(String fileUrl) {
    if (fileUrl.startsWith("http://") || fileUrl.startsWith("https://")) {
      return fileUrl;
    }
    return "${_base()}$fileUrl";
  }
}
