import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_test_app/config.dart';
import 'package:school_test_app/services/auth_service.dart';
import 'package:school_test_app/utils/session_manager.dart';

class ApiInterceptor {
  // GET-запрос с перехватом
  static Future<http.Response> get(String endpoint) async {
    return _interceptRequest(() async {
      final url = "${Config.baseUrl}$endpoint";
      return http.get(Uri.parse(url), headers: await _getHeaders());
    });
  }

  // POST-запрос с перехватом
  static Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    return _interceptRequest(() async {
      final url = "${Config.baseUrl}$endpoint";
      return http.post(Uri.parse(url), headers: await _getHeaders(), body: json.encode(body));
    });
  }

  // Общий перехват запросов
  static Future<http.Response> _interceptRequest(Future<http.Response> Function() request) async {
    http.Response response = await request();

    // Если токен истек
    if (response.statusCode == 401) {
      final refreshed = await AuthService.refreshTokens();
      if (refreshed) {
        // Повторяем запрос с новым токеном
        response = await request();
      } else {
        // Очистка токенов и выход пользователя
        await SessionManager.clearTokens();
        throw Exception("Unauthorized. Please log in again.");
      }
    }

    return response;
  }

  // Получение заголовков с токенами
  static Future<Map<String, String>> _getHeaders() async {
    final accessToken = await SessionManager.getAccessToken();
    if (accessToken == null) {
      throw Exception("Access token is missing. Please log in again.");
    }
    return {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
  }
}
