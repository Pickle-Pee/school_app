import 'package:http/http.dart' as http;
import 'package:school_test_app/config.dart';
import 'package:school_test_app/services/auth_service.dart';
import 'package:school_test_app/utils/session_manager.dart';

class ApiClient {
  static const String baseUrl = Config.baseUrl;

  static Future<http.Response> makeRequest(String endpoint, String method,
      {Map<String, String>? headers, dynamic body}) async {
    final accessToken = await SessionManager.getAccessToken();
    headers ??= {};
    headers["Authorization"] = "Bearer $accessToken";

    Uri url = Uri.parse("$baseUrl$endpoint");

    try {
      http.Response response;
      if (method == "GET") {
        response = await http.get(url, headers: headers);
      } else if (method == "POST") {
        response = await http.post(url, headers: headers, body: body);
      } else {
        throw Exception("Unsupported HTTP method");
      }

      if (response.statusCode == 401) {
        // Если access_token истек
        final refreshed = await AuthService.refreshTokens();
        if (refreshed) {
          // Повторяем запрос с новым токеном
          headers["Authorization"] =
              "Bearer ${await SessionManager.getAccessToken()}";
          if (method == "GET") {
            response = await http.get(url, headers: headers);
          } else if (method == "POST") {
            response = await http.post(url, headers: headers, body: body);
          }
        } else {
          // Не удалось обновить токен
          throw Exception("Unauthorized");
        }
      }

      return response;
    } catch (e) {
      rethrow; // Пробрасываем ошибку дальше
    }
  }
}
