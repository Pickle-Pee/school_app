import 'package:flutter/material.dart';
import 'package:school_test_app/screens/about/about_screen.dart';
import 'package:school_test_app/screens/auth/login_screen.dart';
import 'package:school_test_app/screens/auth/registration_screen.dart';
import 'package:school_test_app/screens/exams/teacher/create_exam_screen.dart';
import 'package:school_test_app/screens/exams/teacher/exams_screen.dart';
import 'package:school_test_app/screens/home_screen.dart';
import 'package:school_test_app/screens/practice/teacher/tests_screen.dart';
import 'package:school_test_app/screens/profile/edit_profile_screen.dart';
import 'package:school_test_app/screens/profile/performance_screen.dart';
import 'package:school_test_app/screens/profile/profile_screen.dart';
import 'package:school_test_app/screens/profile/test_history_screen.dart';
import 'package:school_test_app/screens/register/student_register.dart';
import 'package:school_test_app/screens/register/teacher_register.dart';
import 'package:school_test_app/screens/strart_screen.dart';
import 'package:school_test_app/screens/students/student_list_screen.dart';
import 'package:school_test_app/screens/theory/materials_list_screen.dart';
import 'package:school_test_app/theme/app_theme.dart';

class AppNavigator extends StatelessWidget {
  final String initialRoute;

  AppNavigator({required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Школьник · Информатика',
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      routes: {
        '/': (context) => StartScreen(),
        '/login': (context) => LoginScreen(),
        '/registration': (context) => RegistrationScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/edit_profile': (context) => EditProfileScreen(),
        '/test_history': (context) => TestHistoryScreen(),
        '/performance': (context) => PerformanceScreen(),
        '/register/teacher': (context) => TeacherRegistrationScreen(),
        '/register/student': (context) => StudentRegistrationScreen(),
        '/exercises': (_) => const TestsScreen(),
        '/theory': (context) => const MaterialsListScreen(),
        '/students': (context) => const StudentsListScreen(),
        '/exams': (_) => const ExamsScreen(),
        '/create_exam': (_) => const CreateExamScreen(),
        '/about': (_) => const AboutScreen(),
      },
    );
  }
}

PreferredSizeWidget appHeader(String title, {List<Widget>? actions}) {
  return AppBar(
    title: Text(title),
    centerTitle: false,
    elevation: 0,
    actions: actions,
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
    ),
  );
}
