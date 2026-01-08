import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'package:school_test_app/config.dart';
import 'package:school_test_app/utils/session_manager.dart';

class FilesApiService {
  static String _base() => Config.baseUrl;

  static String fileUrlByTheoryId(int theoryId) => "${_base()}/files/$theoryId";

  /// Если эндпоинт будет требовать авторизацию (сейчас у тебя не требует),
  /// оставляю готовый вариант с Bearer.
  static Future<Uint8List> downloadTheoryFile(int theoryId) async {
    final token = await SessionManager.getAccessToken();
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }

    final resp = await http.get(Uri.parse(fileUrlByTheoryId(theoryId)), headers: headers);

    if (resp.statusCode == 200) {
      return resp.bodyBytes;
    }
    throw Exception("HTTP ${resp.statusCode}: ${resp.body}");
  }

  /// Когда в theory приходит file_url = "/files/{id}"
  static String resolveFileUrl(String fileUrl) {
    if (fileUrl.startsWith("http://") || fileUrl.startsWith("https://")) return fileUrl;
    return "${_base()}$fileUrl";
  }
}
