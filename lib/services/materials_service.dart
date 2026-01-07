// services/materials_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Для MediaType
import 'package:mime/mime.dart'; // Для lookupMimeType
import 'package:school_test_app/services/auth_service.dart';

class MaterialsService {
  final String baseUrl;

  MaterialsService(this.baseUrl);

  /// Список материалов по теме
  Future<List<Map<String, dynamic>>> listTheory({
    required bool isTeacher,
    required int classId,
    required String subject,
    int? topicId,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) throw Exception("No access token. User not authorized?");

    final query = isTeacher
        ? 'class_id=$classId&subject=$subject'
        : 'subject=$subject&topic_id=${topicId ?? ''}';
    final prefix = isTeacher ? 'teacher' : 'student';
    final url = Uri.parse("$baseUrl/$prefix/theory?$query");
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception("Failed to load materials. Code: ${response.statusCode}");
    }
  }

  /// Получить файл теории по прямой ссылке
  Future<List<int>> getTheoryFileBytes(String fileUrl) async {
    final response = await http.get(Uri.parse(fileUrl));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception(
          "Failed to get theory file. Code: ${response.statusCode}");
    }
  }

  /// Загрузить PDF (учитель).
  Future<void> uploadTheoryFile({
    required int classId,
    required String subject,
    required int topicId,
    required String filePath,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception("No access token. User not authorized?");
    }

    final url = Uri.parse('$baseUrl/teacher/theory');

    // Multipart-запрос
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['class_id'] = classId.toString();
    request.fields['subject'] = subject;
    request.fields['topic_id'] = topicId.toString();
    request.fields['kind'] = 'file';

    // Определяем MIME-тип файла
    final mimeType = lookupMimeType(filePath) ?? 'application/pdf';
    final mediaType = mimeType.split('/'); // ["application", "pdf"]

    // Добавляем файл
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      filePath,
      contentType: MediaType(mediaType[0], mediaType[1]),
    ));

    // Отправляем
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Успех
      return;
    } else {
      throw Exception(
          "Failed to upload material. Code: ${response.statusCode}");
    }
  }
}
