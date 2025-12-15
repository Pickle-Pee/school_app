// screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:school_test_app/config.dart';
import 'package:school_test_app/models/user_profile.dart';
import 'package:school_test_app/services/profile_service.dart';
import 'package:school_test_app/widgets/app_navigator.dart';
import 'package:school_test_app/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileService _profileService;
  late Future<UserProfile> _futureProfile;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(Config.baseUrl);
    _futureProfile = _profileService.getMe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: appHeader(
        'Профиль',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/edit_profile');
            },
          ),
        ],
      ),
      body: FutureBuilder<UserProfile>(
        future: _futureProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: Text('Не удалось загрузить профиль'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${profile.firstName} ${profile.lastName}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              profile.email,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(
                          profile.role ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.white.withOpacity(0.18),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileRow(label: 'Email', value: profile.email),
                        _ProfileRow(
                          label: 'Имя',
                          value: profile.firstName ?? '',
                        ),
                        _ProfileRow(
                          label: 'Фамилия',
                          value: profile.lastName ?? '',
                        ),
                        _ProfileRow(
                          label: 'Роль',
                          value: profile.role ?? '',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/test_history');
                          },
                          icon: const Icon(Icons.history_rounded),
                          label: const Text('История тестирования'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/performance');
                          },
                          icon: const Icon(Icons.bar_chart_rounded),
                          label: const Text('Успеваемость и отчёты'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
