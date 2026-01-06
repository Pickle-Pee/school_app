import 'package:school_test_app/utils/session_manager.dart';

class TokenStorage {
  const TokenStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await SessionManager.saveTokens(accessToken, refreshToken);
  }

  Future<String?> getAccessToken() async {
    return SessionManager.getAccessToken();
  }

  Future<String?> getRefreshToken() async {
    return SessionManager.getRefreshToken();
  }

  Future<void> clearTokens() async {
    await SessionManager.clearTokens();
  }
}
