import 'package:flutter/material.dart';
import 'package:school_test_app/features/teacher/classes/teacher_classes_screen.dart';
import 'package:school_test_app/features/teacher/practice/teacher_practice_screen.dart';
import 'package:school_test_app/features/teacher/profile/teacher_profile_screen.dart';
import 'package:school_test_app/features/teacher/theory/teacher_theory_screen.dart';
import 'package:school_test_app/features/common/widgets/section_placeholder.dart';
import 'package:school_test_app/features/teacher/classes/teacher_classes_screen.dart';
import 'package:school_test_app/features/teacher/profile/teacher_profile_screen.dart';
import 'package:school_test_app/theme/app_theme.dart';
import 'package:school_test_app/widgets/app_navigator.dart';

class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _currentIndex = 0;

  static const _titles = [
    'Профиль',
    'Параллели',
    'Теория',
    'Практика',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: appHeader(_titles[_currentIndex]),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TeacherProfileScreen(),
          TeacherClassesScreen(),
          TeacherTheoryScreen(),
          TeacherPracticeScreen(),
          SectionPlaceholder(
            title: 'Теория',
            description: 'Здесь появится список теоретических материалов.',
          ),
          SectionPlaceholder(
            title: 'Практика',
            description: 'Раздел практики и заданий в разработке.',
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Профиль',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_2_outlined),
            label: 'Параллели',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Теория',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_outlined),
            label: 'Практика',
          ),
        ],
      ),
    );
  }
}
