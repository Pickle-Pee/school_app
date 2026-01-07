import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _accessTokenKey = "access_token";
  static const String _tokenTypeKey = "token_type";

  // Сохранение токенов
  static Future<void> saveTokens(
      String accessToken, String tokenType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_tokenTypeKey, tokenType);
  }

  // Получение access_token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // Получение token_type
  static Future<String?> getTokenType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenTypeKey);
  }

  // Очистка токенов
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_tokenTypeKey);
  }
}
