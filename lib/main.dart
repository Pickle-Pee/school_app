import 'package:flutter/material.dart';
import 'package:school_test_app/app.dart';
import 'package:school_test_app/services/auth_service.dart';
import 'package:school_test_app/utils/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final initialRoute = await getInitialRoute();

  runApp(App(initialRoute: initialRoute));
}

Future<String> getInitialRoute() async {
  final accessToken = await SessionManager.getAccessToken();
  final refreshToken = await SessionManager.getRefreshToken();

  if (accessToken != null && refreshToken != null) {
    final refreshed = await AuthService.refreshTokens();
    if (refreshed) {
      return '/shell';
    }
  }

  return '/';
}
