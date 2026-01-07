import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_test_app/utils/session_manager.dart';
import 'package:school_test_app/config.dart';

class AuthService {
  /// Логин
  /// [email], [password], опционально [authCode] — если это учитель
  static Future<bool> login({
    required String email,
    required String password,
    String? authCode,
  }) async {
    final url = "${Config.baseUrl}/login";
    final body = {
      "email": email,
      "password": password,
    };
    if (authCode != null && authCode.isNotEmpty) {
      body["auth_code"] = authCode;
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final accessToken = data["access_token"];
      final refreshToken = data["refresh_token"];
      // Сохраняем токены
      await SessionManager.saveTokens(accessToken, refreshToken);
      return true;
    } else {
      return false;
    }
  }

// Пример: вызываем /me и возвращаем поле "role"
// Если /me вернёт {"email": "...", "first_name": "...", "last_name": "...", "role": "teacher"}
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

  /// Рефреш токенов
  static Future<bool> refreshTokens() async {
    final refreshToken = await SessionManager.getRefreshToken();
    if (refreshToken == null) return false;

    final url = "${Config.baseUrl}/refresh";
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"refresh_token": refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await SessionManager.saveTokens(
          data["access_token"],
          data["refresh_token"],
        );
        return true;
      } else {
        // Если рефреш не успешен, очищаем
        await SessionManager.clearTokens();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Логаут (удаляет refresh-токен и локальные токены)
  static Future<void> logout() async {
    // 1) Попробуем удалить сессию на бэкенде
    await _logoutOnBackend();

    // 2) Локально чистим
    await SessionManager.clearTokens();
  }

  /// Доп. метод: вызвать POST /logout, чтобы на бэкенде удалить refresh-сессию
  static Future<void> _logoutOnBackend() async {
    final refreshToken = await SessionManager.getRefreshToken();
    if (refreshToken == null) {
      // Нет refreshToken — нечего удалять
      return;
    }

    final url = "${Config.baseUrl}/logout";
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"refresh_token": refreshToken}),
      );
      // Даже если вернётся ошибка, мы всё равно почистим локальные токены,
      // поэтому тут не делаем строгую проверку response.statusCode.
    } catch (e) {
      // Игнорируем ошибку сети
    }
  }

  /// Получить текущий access_token из хранилища
  static Future<String?> getAccessToken() async {
    return SessionManager.getAccessToken();
  }
}
