import 'package:flutter/material.dart';
import 'package:school_test_app/widgets/app_navigator.dart';
import 'package:school_test_app/theme/app_theme.dart';

class RegistrationSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: appHeader('Регистрация', context: context, showBack: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.account_circle_rounded,
                        color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Кому создаём доступ к урокам и материалам?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 18.0),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _RoleCard(
                    title: 'Преподаватель',
                    description:
                        'Создавайте материалы, задания и экзамены для класса.',
                    icon: Icons.cast_for_education,
                    onTap: () =>
                        Navigator.pushNamed(context, '/register/teacher'),
                  ),
                  _RoleCard(
                    title: 'Ученик',
                    description:
                        'Получайте доступ к теориям, тренажёрам и экзаменам.',
                    icon: Icons.school,
                    onTap: () =>
                        Navigator.pushNamed(context, '/register/student'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.08)),
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
              const SizedBox(height: 12),
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
