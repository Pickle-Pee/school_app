import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:school_test_app/services/auth_service.dart';
import 'package:school_test_app/utils/subjects_store.dart';
import 'package:school_test_app/theme/app_theme.dart';
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
    if (!mounted) return;

    setState(() {
      _isTeacher = (role == 'teacher');
    });
  }

  void _goTheory(BuildContext context) {
    if (_isTeacher) {
      Navigator.pushNamed(context, '/teacher/materials');
    } else {
      Navigator.pushNamed(context, '/student/materials');
    }
  }

  void _goPractice(BuildContext context) {
    if (_isTeacher) {
      Navigator.pushNamed(context, '/teacher/tests/create');
    } else {
      Navigator.pushNamed(context, '/student/tests');
    }
  }

  void _goStudents(BuildContext context) {
    Navigator.pushNamed(context, '/teacher/students');
  }

  void _goResults(BuildContext context) {
    Navigator.pushNamed(context, '/teacher/results');
  }

  void _goGrades(BuildContext context) {
    Navigator.pushNamed(context, '/student/grades');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appHeader(
        'Информатика', context: context,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    'Меню',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Быстрый доступ к материалам и практике',
                    style: TextStyle(color: Colors.white70),
                  )
                ],
              ),
            ),
            _MenuTile(
              icon: Icons.book_rounded,
              title: 'Материалы',
              onTap: () => _goTheory(context),
            ),
            _MenuTile(
              icon: Icons.code_rounded,
              title: 'Тесты / Практика',
              onTap: () => _goPractice(context),
            ),
            if (_isTeacher) ...[
              _MenuTile(
                icon: Icons.groups_rounded,
                title: 'Ученики',
                onTap: () => _goStudents(context),
              ),
              _MenuTile(
                icon: Icons.bar_chart_rounded,
                title: 'Результаты',
                onTap: () => _goResults(context),
              ),
            ] else ...[
              _MenuTile(
                icon: Icons.star_rounded,
                title: 'Мои оценки',
                onTap: () => _goGrades(context),
              ),
            ],
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroBanner(isTeacher: _isTeacher),
              const SizedBox(height: 16),
              Text(
                'Быстрый доступ',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ActionCard(
                    icon: Icons.menu_book_rounded,
                    title: 'Материалы',
                    description: 'Конспекты и файлы учителя.',
                    onTap: () => _goTheory(context),
                  ),
                  _ActionCard(
                    icon: Icons.code_rounded,
                    title: _isTeacher ? 'Создать тест' : 'Тесты',
                    description: _isTeacher
                        ? 'Создавайте задания и вопросы.'
                        : 'Проходите тесты и практикуйтесь.',
                    onTap: () => _goPractice(context),
                  ),
                  if (_isTeacher)
                    _ActionCard(
                      icon: Icons.groups_2_rounded,
                      title: 'Ученики',
                      description: 'Списки и классы.',
                      onTap: () => _goStudents(context),
                    )
                  else
                    _ActionCard(
                      icon: Icons.star_rounded,
                      title: 'Оценки',
                      description: 'Смотрите средний балл и историю.',
                      onTap: () => _goGrades(context),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (!_isTeacher) ...[
                Text(
                  'Темы информатики',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Observer(
                  builder: (_) {
                    final subjects = subjectsStore.subjects;

                    if (subjects.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.hourglass_empty,
                                color: AppTheme.primaryColor),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Загружаем темы курса…',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          ],
                        ),
                      );
                    }

                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: subjects
                          .map(
                            (subject) => Chip(
                              label: Text(subject),
                              avatar: const Icon(Icons.memory,
                                  size: 18, color: AppTheme.primaryColor),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),
              if (!_isTeacher) ...[
                _FocusCard(
                  title: 'Цифровая грамотность',
                  description:
                      'Разбирайтесь в безопасности, обработке данных и создавайте свои проекты. Ученикам — понятные шаги, преподавателям — прозрачная аналитика.',
                  actionLabel: 'Перейти к теории',
                  onTap: () =>
                      Navigator.pushNamed(context, '/student/materials'),
                ),
                const SizedBox(height: 12),
                _FocusCard(
                  title: 'Подготовка к контрольной',
                  description:
                      'Сборники задач, быстрые тренировки и возможность сформировать экзамен под тему урока.',
                  actionLabel: 'Открыть практику',
                  onTap: () => Navigator.pushNamed(context, '/student/tests'),
                ),
              ],
            ],
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
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline_rounded),
            label: 'О приложении',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;

          final route = (index == 1) ? '/profile' : '/about';
          Navigator.pushReplacementNamed(context, route);
        },
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final bool isTeacher;

  const _HeroBanner({required this.isTeacher});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isTeacher
                          ? Icons.cast_for_education
                          : Icons.laptop_chromebook,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isTeacher ? 'Режим преподавателя' : 'Режим ученика',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Информатика — легко',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Планируйте уроки, закрепляйте алгоритмы и готовьтесь к экзамену. Все материалы в одном месте.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context,
                      isTeacher ? '/teacher/materials' : '/student/tests');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                ),
                child: Text(isTeacher ? 'Материалы' : 'Тесты'),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context,
                      isTeacher ? '/teacher/tests/create' : '/student/tests');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                ),
                child: Text(isTeacher ? 'Создать тест' : 'Практиковаться'),
              )
            ],
          )
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;

  const _FocusCard({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.data_usage_rounded,
                  color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onTap,
              child: Text(actionLabel),
            )
          ],
        ),
      ),
    );
  }
}
