import 'package:flutter/material.dart';
import 'package:school_test_app/routes.dart';
import 'package:school_test_app/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Цифровой класс',
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      routes: appRoutes,
    );
  }
}