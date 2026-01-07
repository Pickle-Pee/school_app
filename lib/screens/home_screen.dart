import 'package:flutter/material.dart';
import 'package:school_test_app/services/auth_service.dart';
import 'package:school_test_app/theme/app_theme.dart';
import 'package:school_test_app/utils/subject_suggestions.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appHeader(
        'Цифровой класс',
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
              title: 'Теория',
              onTap: () => Navigator.pushNamed(context, '/theory'),
            ),
            _MenuTile(
              icon: Icons.code_rounded,
              title: 'Задачи и упражнения',
              onTap: () => Navigator.pushNamed(context, '/exercises'),
            ),
            if (_isTeacher)
              _MenuTile(
                icon: Icons.groups_rounded,
                title: 'Ученики',
                onTap: () => Navigator.pushNamed(context, '/students'),
              ),
            _MenuTile(
              icon: Icons.info_outline,
              title: 'О приложении',
              onTap: () => Navigator.pushNamed(context, '/about'),
            ),
            _MenuTile(
              icon: Icons.logout,
              title: 'Выход',
              onTap: () async {
                await AuthService.logout();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              },
            ),
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
                    title: 'Теория',
                    description: 'Конспекты, схемы и цифровые ресурсы.',
                    onTap: () => Navigator.pushNamed(context, '/theory'),
                  ),
                  _ActionCard(
                    icon: Icons.code_rounded,
                    title: 'Практика',
                    description: 'Алгоритмы, задачи и подготовка к ОГЭ/ЕГЭ.',
                    onTap: () => Navigator.pushNamed(context, '/exercises'),
                  ),
                  if (_isTeacher)
                    _ActionCard(
                      icon: Icons.groups_2_rounded,
                      title: 'Ученики',
                      description: 'Отслеживайте прогресс и приглашайте в класс.',
                      onTap: () => Navigator.pushNamed(context, '/students'),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Темы курса',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: subjectSuggestions
                    .map(
                      (subject) => Chip(
                        label: Text(subject),
                        avatar: const Icon(
                          Icons.memory,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              _FocusCard(
                title: 'Цифровая грамотность',
                description:
                    'Разбирайтесь в безопасности, обработке данных и создавайте свои проекты. Ученикам — понятные шаги, преподавателям — прозрачная аналитика.',
                actionLabel: 'Перейти к теории',
                onTap: () => Navigator.pushNamed(context, '/theory'),
              ),
              const SizedBox(height: 12),
              _FocusCard(
                title: 'Подготовка к контрольной',
                description:
                    'Сборники задач, быстрые тренировки и подбор заданий под тему урока.',
                actionLabel: 'Открыть практику',
                onTap: () => Navigator.pushNamed(context, '/exercises'),
              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isTeacher ? Icons.cast_for_education : Icons.laptop_chromebook,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isTeacher ? 'Режим преподавателя' : 'Режим ученика',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Цифровая учёба — просто',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Планируйте уроки, закрепляйте навыки и готовьтесь к контрольным. Все материалы в одном месте.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/theory'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Изучить теорию'),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/exercises'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                ),
                child: const Text('Практиковаться'),
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
              child: const Icon(Icons.data_usage_rounded, color: AppTheme.primaryColor),
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
