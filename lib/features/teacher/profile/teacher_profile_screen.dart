import 'package:flutter/material.dart';
import 'package:school_test_app/features/teacher/profile/models/teacher_profile.dart';
import 'package:school_test_app/features/teacher/profile/teacher_profile_service.dart';
import 'package:school_test_app/theme/app_theme.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final TeacherProfileService _service = TeacherProfileService();
  late Future<TeacherProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _service.fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<TeacherProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _EmptyState(
              message: 'Ошибка загрузки профиля: ${snapshot.error}',
            );
          }
          final profile = snapshot.data;
          if (profile == null) {
            return const _EmptyState(message: 'Профиль недоступен.');
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Профиль',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppTheme.primaryColor.withOpacity(0.12),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Предмет: ${profile.subject}'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.extra.entries
                            .where((entry) => entry.key != 'full_name')
                            .map(
                              (entry) => Chip(
                                label: Text(
                                  '${entry.key}: ${entry.value}',
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Colors.black54),
      ),
    );
  }
}
