import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_test_app/utils/session_manager.dart';
import 'package:school_test_app/config.dart';

class AuthService {
  /// Логин
  /// [phone], [password], опционально [teacherCode] — если это учитель
  static Future<bool> login({
    required String phone,
    required String password,
    String? teacherCode,
  }) async {
    final url = "${Config.baseUrl}/auth/login";
    final body = {
      "phone": phone,
      "password": password,
    };
    if (teacherCode != null && teacherCode.isNotEmpty) {
      body["teacher_code"] = teacherCode;
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final accessToken = data["access_token"];
      final tokenType = data["token_type"] ?? "bearer";
      // Сохраняем токены
      await SessionManager.saveTokens(accessToken, tokenType);
      return true;
    } else {
      return false;
    }
  }

// Пример: вызываем /me и возвращаем поле "role"
// Если /me вернёт {"role": "teacher", "profile": {...}}
  static Future<String?> getUserType() async {
    final token = await SessionManager.getAccessToken();
    if (token == null) return null; // не авторизован

    final url = "${Config.baseUrl}/me";
    final response = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["role"] as String?; // "teacher" или "student"
    } else {
      // не смогли получить /me — значит неизвестно
      return null;
    }
  }

  /// Логаут (удаляет refresh-токен и локальные токены)
  static Future<void> logout() async {
    // Контракт не описывает logout: чистим локальные токены.
    await SessionManager.clearTokens();
  }

  /// Установка/сброс пароля
  static Future<bool> setPassword({
    required String phone,
    required String newPassword,
    String? teacherCode,
  }) async {
    final url = "${Config.baseUrl}/auth/set-password";
    final body = {
      "phone": phone,
      "new_password": newPassword,
    };
    if (teacherCode != null && teacherCode.isNotEmpty) {
      body["teacher_code"] = teacherCode;
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );

    return response.statusCode == 200;
  }

  /// Получить текущий access_token из хранилища
  static Future<String?> getAccessToken() async {
    return SessionManager.getAccessToken();
  }
}
