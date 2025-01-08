import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:school_test_app/services/auth_service.dart';
import 'package:school_test_app/utils/subjects_store.dart';
import 'package:school_test_app/widgets/app_navigator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isTeacher = false;

  @override
  void initState() {
    super.initState();
    subjectsStore.fetchSubjects();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final role = await AuthService.getUserType();
    // Предполагаем, что вернёт "teacher" / "student" / null
    setState(() {
      _isTeacher = (role == 'teacher');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appHeader(
        'Школьник',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Add search functionality
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Меню',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),

            // Теория
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Теория'),
              onTap: () => Navigator.pushNamed(context, '/theory'),
            ),

            // Задачи и упражнения
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Задачи и упражнения'),
              onTap: () => Navigator.pushNamed(context, '/exercises'),
            ),

            // Экзамен
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Экзамен'),
              onTap: () => Navigator.pushNamed(context, '/exams'),
            ),

            // Показываем "Ученики" только если _isTeacher == true
            if (_isTeacher)
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('Ученики (для профиля преподавателя)'),
                onTap: () => Navigator.pushNamed(context, '/students'),
              ),

            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('О приложении'),
              onTap: () => Navigator.pushNamed(context, '/about'),
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Выход'),
              onTap: () async {
                // Логика логаута
                await AuthService.logout();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Observer(
          builder: (_) => GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
            ),
            itemCount: subjectsStore.subjects.length,
            itemBuilder: (context, index) {
              return Card(
                child: Center(
                  child: Text(
                    subjectsStore.subjects[index],
                    style: const TextStyle(fontSize: 18.0),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }
}
