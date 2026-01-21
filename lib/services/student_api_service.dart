import 'dart:convert';
import 'dart:typed_data';
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
///
/// (Регистрация ученика)
/// GET  /class-groups                 (public)
/// POST /auth/register/student        (public)
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

  // -------------------- PUBLIC (no auth) --------------------

  /// GET /student/class-groups (для регистрации)
  static Future<List<dynamic>> getClassGroups() async {
    final resp = await http.get(_uri("/student/class-groups"));
    if (resp.statusCode == 200) {
      final decoded = _decode(resp);
      if (decoded is List) return List<dynamic>.from(decoded);
      return <dynamic>[];
    }
    throw _httpError(resp);
  }

  /// POST /auth/register/student (public)
  static Future<Map<String, dynamic>> registerStudent({
    required String fullName,
    required String phone,
    String? email,
    required String password,
    required int classGroupId,
  }) async {
    final resp = await http.post(
      _uri("/auth/register/student"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "full_name": fullName,
        "phone": phone,
        "email":
            (email != null && email.trim().isNotEmpty) ? email.trim() : null,
        "password": password,
        "class_group_id": classGroupId,
      }),
    );

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final decoded = _decode(resp);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return <String, dynamic>{};
    }
    throw _httpError(resp);
  }

  // -------------------- AUTH (student) --------------------

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
      _uri("/student/subjects"),
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
      _uri("/student/topics", {"subject": subject}),
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
      _uri("/student/theory", {"subject": subject, "topic_id": topicId}),
      headers: await _authHeaders(),
    );

    if (resp.statusCode == 200) {
      return List<dynamic>.from(_decode(resp) as List);
    }
    throw _httpError(resp);
  }

  /// GET /assignments?subject=...&type=...&topic_id=...
  static Future<List<dynamic>> getAssignments({
    required String subject,
    String? type, // null => все типы
    required int topicId,
  }) async {
    final resp = await http.get(
      _uri("/student/assignments", {
        "subject": subject,
        // если type == null, параметр не отправляем
        "type": (type == null || type == "all") ? null : type,
        "topic_id": topicId,
      }),
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
      _uri("/student/assignments/$assignmentId"),
      headers: await _authHeaders(),
    );

    if (resp.statusCode == 200) {
      return Map<String, dynamic>.from(_decode(resp) as Map);
    }
    throw _httpError(resp);
  }

  /// ✅ POST /assignments/{assignment_id}/submit
  /// IMPORTANT: оставляем параметр `answers`, чтобы совпадало с UI-экранами
  static Future<Map<String, dynamic>> submitAssignment({
    required int assignmentId,
    required Map<String, dynamic> answers, // keys: q1, q2, ...
  }) async {
    final resp = await http.post(
      _uri("/student/assignments/$assignmentId/submit"),
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
      _uri("/student/grades", {"subject": subject}),
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

  static String? _filenameFromContentDisposition(String? cd) {
    if (cd == null) return null;

    final utf8Match = RegExp(r"filename\*\=UTF-8''([^;]+)").firstMatch(cd);
    if (utf8Match != null) return Uri.decodeFull(utf8Match.group(1)!);

    final match = RegExp(r'filename\=\"?([^\";]+)\"?').firstMatch(cd);
    if (match != null) return match.group(1);

    return null;
  }

  static Future<({Uint8List bytes, String filename, String contentType})>
      downloadTheoryFileWeb(int theoryId) async {
    final resp = await http.get(
      Uri.parse("${_base()}/files/$theoryId"),
      headers: await _authHeaders(),
    );

    if (resp.statusCode != 200) throw _httpError(resp);

    final cd = resp.headers["content-disposition"];
    final filename = _filenameFromContentDisposition(cd) ?? "theory_$theoryId";

    final contentType =
        resp.headers["content-type"] ?? "application/octet-stream";

    return (
      bytes: resp.bodyBytes,
      filename: filename,
      contentType: contentType
    );
  }
}
