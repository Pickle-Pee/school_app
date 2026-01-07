// screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:school_test_app/theme/app_theme.dart';
import 'package:school_test_app/widgets/app_navigator.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  static const _ProfileData _profile = _ProfileData.placeholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: appHeader(
        'Профиль',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(context, '/edit_profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ApiNoticeCard(),
            const SizedBox(height: 16),
            _ProfileHeader(profile: _profile),
            const SizedBox(height: 18),
            _ProfileDetails(profile: _profile),
            const SizedBox(height: 12),
            const _ProfileActions(),
          ],
        ),
      ),
    );
  }
}

class _ApiNoticeCard extends StatelessWidget {
  const _ApiNoticeCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: const [
            Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Профиль будет доступен после подключения нового API. Пока можно '
                'перейти к истории работ и успеваемости.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final _ProfileData profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  profile.displayName,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.white),
                ),
                if (!profile.isPlaceholder) ...[
                  const SizedBox(height: 6),
                  Text(
                    profile.email,
                    style: const TextStyle(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (!profile.isPlaceholder)
            Chip(
              label: Text(
                profile.role,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.white.withOpacity(0.18),
            ),
        ],
      ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  final _ProfileData profile;

  const _ProfileDetails({required this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile.isPlaceholder) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Данные профиля появятся после подключения нового API.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileRow(label: 'Email', value: profile.email),
            _ProfileRow(label: 'Имя', value: profile.firstName),
            _ProfileRow(label: 'Фамилия', value: profile.lastName),
            _ProfileRow(label: 'Роль', value: profile.role),
          ],
        ),
      ),
    );
  }
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/test_history'),
              icon: const Icon(Icons.history_rounded),
              label: const Text('История работ'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/performance'),
              icon: const Icon(Icons.bar_chart_rounded),
              label: const Text('Успеваемость и отчёты'),
            ),
          ],
        ),
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
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black87,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileData {
  final String displayName;
  final String email;
  final String role;
  final String firstName;
  final String lastName;
  final bool isPlaceholder;

  const _ProfileData({
    required this.displayName,
    required this.email,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.isPlaceholder,
  });

  const _ProfileData.placeholder()
      : displayName = 'Пользователь',
        email = 'Нет данных',
        role = 'Не указана',
        firstName = 'Не указано',
        lastName = 'Не указано',
        isPlaceholder = true;
}
