import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:school_test_app/app.dart';
import 'package:school_test_app/app.dart';
import 'package:school_test_app/services/auth_service.dart';
import 'package:school_test_app/utils/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final initialRoute = await getInitialRoute();

  runApp(App(initialRoute: initialRoute));
}

Future<String> getInitialRoute() async {
  final accessToken = await SessionManager.getAccessToken();

  if (accessToken != null && accessToken.isNotEmpty) {
    return '/shell';
  }

  return '/';
}
