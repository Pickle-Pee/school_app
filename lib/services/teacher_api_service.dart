import 'dart:convert';
import 'package:file_picker/file_picker.dart';

import 'package:http/http.dart' as http;
import 'package:school_test_app/config.dart';
import 'package:school_test_app/utils/session_manager.dart';

/// Teacher API (с prefix="/teacher"):
/// GET    /teacher/profile
/// GET    /teacher/classes
/// GET    /teacher/topics?class_id=&subject=
/// GET    /teacher/grades/summary?class_id=&subject=
/// GET    /teacher/grades/by-topic?class_id=&topic_id=&type=&subject=&page=&page_size=
/// POST   /teacher/attempts/reset
/// GET    /teacher/theory?class_id=&subject=
/// POST   /teacher/theory  (json или multipart/form-data)
/// PATCH  /teacher/theory/{theory_id}
/// DELETE /teacher/theory/{theory_id}
/// GET    /teacher/assignments?class_id=&subject=&type=
/// POST   /teacher/assignments
/// GET    /teacher/assignments/{assignment_id}
/// PATCH  /teacher/assignments/{assignment_id}
/// DELETE /teacher/assignments/{assignment_id}
/// GET    /teacher/submissions?assignment_id=&page=&page_size=
class TeacherApiService {
  static const String _prefix = "/teacher";

  static String _base() => Config.baseUrl;
  static String _path(String p) => "$_prefix$p";

  static Uri _uri(String path, [Map<String, dynamic>? query]) {
    final qp = <String, String>{};
    if (query != null) {
      for (final e in query.entries) {
        if (e.value == null) continue;
        qp[e.key] = e.value.toString();
      }
    }
    return Uri.parse("${_base()}${_path(path)}")
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

  // ---------- PROFILE / CLASSES / TOPICS ----------

  static Future<Map<String, dynamic>> getProfile() async {
    final resp =
        await http.get(_uri("/profile"), headers: await _authHeaders());
    if (resp.statusCode == 200)
      return Map<String, dynamic>.from(_decode(resp) as Map);
    throw _httpError(resp);
  }

  static Future<List<dynamic>> getClasses() async {
    final resp =
        await http.get(_uri("/classes"), headers: await _authHeaders());
    if (resp.statusCode == 200)
      return List<dynamic>.from(_decode(resp) as List);
    throw _httpError(resp);
  }

  static Future<List<dynamic>> getTopics({
    required int classId,
    required String subject,
  }) async {
    final resp = await http.get(
      _uri("/topics", {"class_id": classId, "subject": subject}),
      headers: await _authHeaders(),
    );
    if (resp.statusCode == 200)
      return List<dynamic>.from(_decode(resp) as List);
    throw _httpError(resp);
  }

  // ---------- GRADES ----------

  static Future<Map<String, dynamic>> getGradesSummary({
    required int classId,
    required String subject,
  }) async {
    final resp = await http.get(
      _uri("/grades/summary", {"class_id": classId, "subject": subject}),
      headers: await _authHeaders(),
    );
    if (resp.statusCode == 200)
      return Map<String, dynamic>.from(_decode(resp) as Map);
    throw _httpError(resp);
  }

  static Future<Map<String, dynamic>> getGradesByTopic({
    required int classId,
    required int topicId,
    required String type, // "practice" | "homework"
    required String subject,
    int page = 1,
    int pageSize = 20,
  }) async {
    final resp = await http.get(
      _uri("/grades/by-topic", {
        "class_id": classId,
        "topic_id": topicId,
        "type": type,
        "subject": subject,
        "page": page,
        "page_size": pageSize,
      }),
      headers: await _authHeaders(),
    );
    if (resp.statusCode == 200)
      return Map<String, dynamic>.from(_decode(resp) as Map);
    throw _httpError(resp);
  }

  // ---------- ATTEMPTS ----------

  static Future<Map<String, dynamic>> resetAttempts({
    required int studentId,
    required int assignmentId,
  }) async {
    final resp = await http.post(
      _uri("/attempts/reset"),
      headers: await _authHeaders(jsonBody: true),
      body: json.encode({
        "student_id": studentId,
        "assignment_id": assignmentId,
      }),
    );
    if (resp.statusCode == 200)
      return Map<String, dynamic>.from(_decode(resp) as Map);
    throw _httpError(resp);
  }

  // ---------- THEORY ----------

  static Future<List<dynamic>> listTheory({
    required int classId,
    required String subject,
  }) async {
    final resp = await http.get(
      _uri("/theory", {"class_id": classId, "subject": subject}),
      headers: await _authHeaders(),
    );
    if (resp.statusCode == 200)
      return List<dynamic>.from(_decode(resp) as List);
    throw _httpError(resp);
  }

  /// POST /teacher/theory (JSON) для текста
  static Future<Map<String, dynamic>> createTheoryText({
    required int classId,
    required String subject,
    required int topicId,
    required String text,
  }) async {
    final resp = await http.post(
      _uri("/theory"),
      headers: await _authHeaders(jsonBody: true),
      body: json.encode({
        "class_id": classId,
        "subject": subject,
        "topic_id": topicId,
        "kind": "text",
        "text": text,
      }),
    );
    if (resp.statusCode == 200)
      return Map<String, dynamic>.from(_decode(resp) as Map);
    throw _httpError(resp);
  }

  /// POST /teacher/theory (multipart) для файла
  static Future<Map<String, dynamic>> createTheoryFile({
    required int classId,
    required String subject,
    required int topicId,
    required PlatformFile file,
  }) async {
    final token = await SessionManager.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception("Нет access_token. Сначала выполните логин.");
    }

    final req = http.MultipartRequest("POST", _uri("/theory"));
    req.headers["Authorization"] = "Bearer $token";

    req.fields["class_id"] = classId.toString();
    req.fields["subject"] = subject;
    req.fields["topic_id"] = topicId.toString();
    req.fields["kind"] = "file";

    // Web: bytes доступны только если pickFiles(withData: true)
    if (file.bytes != null) {
      req.files.add(
        http.MultipartFile.fromBytes(
          "file",
          file.bytes!,
          filename: file.name,
        ),
      );
    } else if (file.path != null) {
      // Android/iOS обычно можно грузить из path
      req.files.add(await http.MultipartFile.fromPath("file", file.path!));
    } else {
      throw Exception(
        "Файл не содержит bytes и path. Для Web используйте FilePicker(... withData: true).",
      );
    }

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode == 200) {
      return Map<String, dynamic>.from(_decode(resp) as Map);
    }
    throw _httpError(resp);
  }

  static Future<Map<String, dynamic>> updateTheory({
    required int theoryId,
    required Map<String, dynamic> payload, // TheoryUpdate subset
  }) async {
    final resp = await http.patch(
      _uri("/theory/$theoryId"),
      headers: await _authHeaders(jsonBody: true),
      body: json.encode(payload),
    );
    if (resp.statusCode == 200)
      return Map<String, dynamic>.from(_decode(resp) as Map);
    throw _httpError(resp);
  }

  static Future<Map<String, dynamic>> deleteTheory(
      {required int theoryId}) async {
    final resp = await http.delete(_uri("/theory/$theoryId"),
        headers: await _authHeaders());
    if (resp.statusCode == 200)
      return Map<String, dynamic>.from(_decode(resp) as Map);
    throw _httpError(resp);
  }

  // ---------- ASSIGNMENTS ----------

  static Future<List<dynamic>> listAssignments({
    required int classId,
    required String subject,
    required String type, // "practice" | "homework"
  }) async {
    final resp = await http.get(
      _uri("/assignments",
          {"class_id": classId, "subject": subject, "type": type}),
      headers: await _authHeaders(),
    );
    if (resp.statusCode == 200)
      return List<dynamic>.from(_decode(resp) as List);
    throw _httpError(resp);
  }

  /// payload = AssignmentCreate
  static Future<int> createAssignment(
      {required Map<String, dynamic> payload}) async {
    final resp = await http.post(
      _uri("/assignments"),
      headers: await _authHeaders(jsonBody: true),
      body: json.encode(payload),
    );
    if (resp.statusCode == 200) {
      final data = Map<String, dynamic>.from(_decode(resp) as Map);
      return (data["id"] as num).toInt();
    }
    throw _httpError(resp);
  }

  static Future<Map<String, dynamic>> getAssignmentDetail(
      {required int assignmentId}) async {
    final resp = await http.get(_uri("/assignments/$assignmentId"),
        headers: await _authHeaders());
    if (resp.statusCode == 200)
      return Map<String, dynamic>.from(_decode(resp) as Map);
    throw _httpError(resp);
  }

  /// payload = AssignmentUpdate
  static Future<Map<String, dynamic>> updateAssignment({
    required int assignmentId,
    required Map<String, dynamic> payload,
  }) async {
    final resp = await http.patch(
      _uri("/assignments/$assignmentId"),
      headers: await _authHeaders(jsonBody: true),
      body: json.encode(payload),
    );
    if (resp.statusCode == 200)
      return Map<String, dynamic>.from(_decode(resp) as Map);
    throw _httpError(resp);
  }

  static Future<Map<String, dynamic>> deleteAssignment(
      {required int assignmentId}) async {
    final resp = await http.delete(_uri("/assignments/$assignmentId"),
        headers: await _authHeaders());
    if (resp.statusCode == 200)
      return Map<String, dynamic>.from(_decode(resp) as Map);
    throw _httpError(resp);
  }

  // ---------- SUBMISSIONS ----------

  static Future<Map<String, dynamic>> listSubmissions({
    required int assignmentId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final resp = await http.get(
      _uri("/submissions", {
        "assignment_id": assignmentId,
        "page": page,
        "page_size": pageSize,
      }),
      headers: await _authHeaders(),
    );
    if (resp.statusCode == 200)
      return Map<String, dynamic>.from(_decode(resp) as Map);
    throw _httpError(resp);
  }

  /// Полный URL на файл теории (из file_url: "/files/{id}")
  static String resolveFileUrl(String fileUrl) {
    if (fileUrl.startsWith("http://") || fileUrl.startsWith("https://"))
      return fileUrl;
    return "${_base()}$fileUrl";
  }
}
