import 'package:flutter/material.dart';
import 'package:school_test_app/app.dart';
import 'package:school_test_app/utils/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Проверяем сессию при запуске
  final initialRoute = await getInitialRoute();

  runApp(App(initialRoute: initialRoute));
}

Future<String> getInitialRoute() async {
  final accessToken = await SessionManager.getAccessToken();
  if (accessToken != null) {
    return '/home';
  }

  return '/'; // Если токенов нет или они недействительны, отправляем на авторизацию
}
