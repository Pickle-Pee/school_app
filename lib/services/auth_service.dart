import 'package:dio/dio.dart';
import 'package:school_test_app/core/api/api_client.dart';
import 'package:school_test_app/core/storage/token_storage.dart';

class AuthService {
  static final Dio _client = ApiClient().client;
  static const TokenStorage _tokenStorage = TokenStorage();

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

    try {
      final response = await _client.post('/auth/login', data: body);
      final data = response.data as Map<String, dynamic>? ?? {};
      final accessToken = data["access_token"]?.toString();
      if (accessToken == null || accessToken.isEmpty) {
        return false;
      }
      final refreshToken = data["refresh_token"]?.toString() ?? '';
      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final accessToken = data["access_token"];
      final refreshToken = data["refresh_token"] ?? '';
      await SessionManager.saveTokens(accessToken, refreshToken);
      return true;
    } on DioException {
      return false;
    }
  }

// Пример: вызываем /me и возвращаем поле "role"
// Если /me вернёт {"email": "...", "first_name": "...", "last_name": "...", "role": "teacher"}
  static Future<String?> getUserType() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) return null; // не авторизован

    try {
      final response = await _client.get('/me');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>? ?? {};
        return data["role"] as String?; // "teacher" или "student"
      }
      return null;
    } on DioException {
      // не смогли получить /me — значит неизвестно
      return null;
    }
  }

  /// Рефреш токенов (опционально)
  static Future<bool> refreshTokens() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) return false;

    final url = "${Config.baseUrl}/auth/refresh";
    try {
      final response = await _client.post(
        '/auth/refresh',
        data: {"refresh_token": refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>? ?? {};
        final accessToken = data["access_token"]?.toString();
        final newRefreshToken = data["refresh_token"]?.toString();
        if (accessToken != null && accessToken.isNotEmpty) {
          await _tokenStorage.saveTokens(
            accessToken: accessToken,
            refreshToken: newRefreshToken ?? refreshToken,
          );
        }
        return true;
      } else {
        // Если рефреш не успешен, очищаем
        await _tokenStorage.clearTokens();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Получить текущий access_token из хранилища
  static Future<String?> getAccessToken() async {
    return _tokenStorage.getAccessToken();
  }

  /// Очистить локальную сессию
  static Future<void> clearSession() async {
    await _tokenStorage.clearTokens();
  }
}
