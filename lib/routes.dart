import 'package:flutter/material.dart';
import 'package:school_test_app/screens/about/about_screen.dart';
import 'package:school_test_app/screens/auth/login_screen.dart';
import 'package:school_test_app/screens/home_screen.dart';
import 'package:school_test_app/screens/profile/edit_profile_screen.dart';
import 'package:school_test_app/screens/profile/performance_screen.dart';
import 'package:school_test_app/screens/profile/profile_screen.dart';
import 'package:school_test_app/screens/profile/test_history_screen.dart';
import 'package:school_test_app/screens/practice/teacher/tests_screen.dart';
import 'package:school_test_app/screens/strart_screen.dart';
import 'package:school_test_app/screens/students/student_list_screen.dart';
import 'package:school_test_app/screens/theory/materials_list_screen.dart';

Map<String, WidgetBuilder> get appRoutes => {
      '/': (_) => const StartScreen(),
      '/login': (_) => const LoginScreen(),
      '/home': (_) => const HomeScreen(),
      '/profile': (_) => const ProfileScreen(),
      '/edit_profile': (_) => const EditProfileScreen(),
      '/test_history': (_) => const TestHistoryScreen(),
      '/performance': (_) => const PerformanceScreen(),
      '/exercises': (_) => const TestsScreen(),
      '/theory': (_) => const MaterialsListScreen(),
      '/students': (_) => const StudentsListScreen(),
      '/about': (_) => const AboutScreen(),
    };
