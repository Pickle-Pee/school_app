import 'package:flutter/material.dart';
import 'package:school_test_app/app.dart';
import 'package:school_test_app/utils/session_manager.dart';
import 'package:school_test_app/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final initialRoute = await getInitialRoute();

  runApp(App(initialRoute: initialRoute));
}

Future<String> getInitialRoute() async {
  final accessToken = await SessionManager.getAccessToken();
  final refreshToken = await SessionManager.getRefreshToken();

  // Если нет токенов — идём на логин
  if (accessToken == null && refreshToken == null) {
    return '/login';
  }

  // Если есть refreshToken — пробуем обновить accessToken
  if (refreshToken != null) {
    try {
      final refreshed = await AuthService.refreshTokens();
      if (refreshed) {
        return '/home';
      }
    } catch (_) {
      // если обновление упало — пойдём на логин
      return '/login';
    }
  }

  // Если refreshToken нет, но accessToken есть — пускаем (на свой риск)
  if (accessToken != null) {
    return '/home';
  }

  return '/login';
}
