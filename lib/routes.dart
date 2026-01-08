import 'package:flutter/material.dart';
import 'package:school_test_app/screens/about/about_screen.dart';
import 'package:school_test_app/screens/auth/login_screen.dart';
import 'package:school_test_app/screens/auth/password_reset_screen.dart';
import 'package:school_test_app/screens/auth/registration_screen.dart';
import 'package:school_test_app/screens/home_screen.dart';
import 'package:school_test_app/screens/profile/profile_screen.dart';
import 'package:school_test_app/screens/strart_screen.dart';
import 'package:school_test_app/screens/student/grades/student_grades_screen.dart';
import 'package:school_test_app/screens/student/materials/student_material_detail_screen.dart';
import 'package:school_test_app/screens/student/materials/student_material_screen.dart';
import 'package:school_test_app/screens/student/tests/student_assignment_detail_screen.dart';
import 'package:school_test_app/screens/student/tests/student_assignments_screen.dart';
import 'package:school_test_app/screens/student/tests/student_test_pass_screen.dart';
import 'package:school_test_app/screens/teacher/materials/teacher_add_material_screen.dart';
import 'package:school_test_app/screens/teacher/materials/teacher_material_detail_screen.dart';
import 'package:school_test_app/screens/teacher/materials/teacher_material_screen.dart';
import 'package:school_test_app/screens/teacher/results/teacher_result_screen.dart';
import 'package:school_test_app/screens/teacher/students/teacher_student_screen.dart';
import 'package:school_test_app/screens/teacher/teacher_shell.dart';
import 'package:school_test_app/screens/teacher/tests/teacher_assignment_detail_screen.dart';
import 'package:school_test_app/screens/teacher/tests/teacher_create_assignment_screen.dart';

Map<String, WidgetBuilder> get appRoutes => {
      '/': (_) => const StartScreen(),
      '/login': (_) => const LoginScreen(),
      '/register': (_) => const RegistrationScreen(),
      '/password_reset': (_) => PasswordResetScreen(),
      '/home': (_) => const HomeScreen(),
      '/teacher': (_) => const TeacherShell(),
      '/teacher/materials': (_) => const TeacherMaterialsScreen(),
      '/teacher/materials/add': (_) => const TeacherAddMaterialScreen(),
      '/teacher/tests/create': (_) => const TeacherCreateAssignmentScreen(),
      '/teacher/tests/detail': (_) => const TeacherAssignmentDetailScreen(),
      '/teacher/students': (_) => const TeacherStudentsScreen(),
      '/teacher/results': (_) => const TeacherResultsScreen(),
      '/teacher/materials/detail': (_) => const TeacherMaterialDetailScreen(),
      '/student/tests': (_) => const StudentAssignmentsScreen(),
      '/student/tests/detail': (_) => const StudentAssignmentDetailScreen(),
      '/student/tests/pass': (_) => const StudentTestPassScreen(),
      '/student/materials/detail': (_) => const StudentMaterialDetailScreen(),
      '/student/materials': (_) => const StudentMaterialsScreen(),
      '/student/grades': (_) => const StudentGradesScreen(),
      '/profile': (_) => const ProfileScreen(),
      '/about': (_) => const AboutScreen(),
    };
