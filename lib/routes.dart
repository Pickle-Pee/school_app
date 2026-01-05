import 'package:flutter/material.dart';
import 'package:school_test_app/features/student/student_shell.dart';
import 'package:school_test_app/features/teacher/teacher_shell.dart';
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
import 'package:school_test_app/services/auth_service.dart';

Map<String, WidgetBuilder> get appRoutes => {
      '/': (_) => StartScreen(),
      '/login': (_) => const LoginScreen(),
      '/registration': (_) => RegistrationScreen(),
      '/home': (_) => const HomeScreen(),
      '/profile': (_) => const ProfileScreen(),
      '/edit_profile': (_) => const EditProfileScreen(),
      '/test_history': (_) => const TestHistoryScreen(),
      '/performance': (_) => const PerformanceScreen(),
      '/register/teacher': (_) => const TeacherRegistrationScreen(),
      '/register/student': (_) => const StudentRegistrationScreen(),
      '/exercises': (_) => const TestsScreen(),
      '/theory': (_) => const MaterialsListScreen(),
      '/students': (_) => const StudentsListScreen(),
      '/exams': (_) => const ExamsScreen(),
      '/create_exam': (_) => const CreateExamScreen(),
      '/about': (_) => const AboutScreen(),
      '/shell': (_) => const RoleGate(),
      '/teacher': (_) => const TeacherShell(),
      '/student': (_) => const StudentShell(),
    };

class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService.getUserType(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final role = snapshot.data;
        if (role == 'teacher') {
          return const TeacherShell();
        }
        if (role == 'student') {
          return const StudentShell();
        }
        return const LoginScreen();
      },
    );
  }
}
