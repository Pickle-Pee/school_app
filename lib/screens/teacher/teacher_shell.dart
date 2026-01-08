import 'package:flutter/material.dart';
import 'package:school_test_app/screens/teacher/materials/teacher_material_screen.dart';
import 'package:school_test_app/theme/app_theme.dart';

class TeacherShell extends StatefulWidget {
  const TeacherShell({Key? key}) : super(key: key);

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _index = 0;

  final _pages = const [
    TeacherMaterialsScreen(),
    _TeacherPlaceholder(title: 'Тесты'),
    _TeacherPlaceholder(title: 'Ученики'),
    _TeacherPlaceholder(title: 'Результаты'),
    _TeacherPlaceholder(title: 'Профиль'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Режим преподавателя'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.black45,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Материалы'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Тесты'),
          BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: 'Ученики'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Результаты'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Профиль'),
        ],
      ),
    );
  }
}

class _TeacherPlaceholder extends StatelessWidget {
  final String title;
  const _TeacherPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_empty, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Text('$title — скоро', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
