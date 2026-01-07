import 'package:flutter/material.dart';
import 'package:school_test_app/app.dart';
import 'package:school_test_app/services/auth_service.dart';
import 'package:school_test_app/utils/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Проверяем сессию при запуске
  final initialRoute = await getInitialRoute();

  runApp(App(initialRoute: initialRoute));
}

Future<String> getInitialRoute() async {
  final accessToken = await SessionManager.getAccessToken();
  final refreshToken = await SessionManager.getRefreshToken();

  if (accessToken != null && refreshToken != null) {
    // Пытаемся обновить токен, если accessToken истек
    final refreshed = await AuthService.refreshTokens();
    if (refreshed) {
      return '/home'; // Если сессия активна, отправляем на главный экран
    }
  }

  return '/'; // Если токенов нет или они недействительны, отправляем на авторизацию
}
