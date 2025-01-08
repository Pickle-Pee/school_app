// services/materials_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Для MediaType
import 'package:mime/mime.dart'; // Для lookupMimeType
import 'package:school_test_app/services/auth_service.dart';

class MaterialsService {
  final String baseUrl;

  MaterialsService(this.baseUrl);

  /// Список материалов (id, title, file_path, uploaded_at)
  Future<List<Map<String, dynamic>>> listMaterials() async {
    final token = await AuthService.getAccessToken();
    if (token == null) throw Exception("No access token. User not authorized?");

    final url = Uri.parse("$baseUrl/materials");
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

  /// Получить байты PDF через GET /materials/{material_id}/content
  Future<Uint8List> getMaterialPdfBytes(int materialId) async {
    final token = await AuthService.getAccessToken();
    if (token == null) throw Exception("No access token. User not authorized?");

    final url = Uri.parse("$baseUrl/materials/$materialId/content");
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      return response.bodyBytes; // PDF-байты
    } else {
      throw Exception(
          "Failed to get material content. Code: ${response.statusCode}");
    }
  }

  /// Загрузить PDF (учитель).
  /// [title] - название, [filePath] - путь к файлу (из file_picker)
  Future<void> uploadMaterial(String title, String filePath) async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception("No access token. User not authorized?");
    }

    final url = Uri.parse('$baseUrl/materials/upload');

    // Multipart-запрос
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';

    // Поле title
    request.fields['title'] = title;

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
