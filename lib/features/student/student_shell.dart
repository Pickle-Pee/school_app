import 'package:flutter/material.dart';
import 'package:school_test_app/features/student/profile/student_profile_screen.dart';
import 'package:school_test_app/features/student/subject/student_subject_screen.dart';
import 'package:school_test_app/theme/app_theme.dart';
import 'package:school_test_app/widgets/app_navigator.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _currentIndex = 0;

  static const _titles = [
    'Профиль',
    'Предмет',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: appHeader(_titles[_currentIndex]),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          StudentProfileScreen(),
          StudentSubjectScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Профиль',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Предмет',
          ),
        ],
      ),
    );
  }
}
