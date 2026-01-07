// screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:school_test_app/models/profile_models.dart';
import 'package:school_test_app/services/profile_service.dart';
import 'package:school_test_app/theme/app_theme.dart';
import 'package:school_test_app/widgets/app_navigator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileService _profileService;
  late Future<ProfileView> _futureProfile;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService();
    _futureProfile = _profileService.getProfile();
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
            onPressed: () => Navigator.pushNamed(context, '/edit_profile'),
          ),
        ],
      ),
      body: FutureBuilder<ProfileView>(
        future: _futureProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MessageCard(
              text: 'Не удалось загрузить профиль: ${snapshot.error}',
            );
          }
          final profile = snapshot.data;
          if (profile == null) {
            return const _MessageCard(text: 'Профиль не найден.');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHeader(profile: profile),
                const SizedBox(height: 18),
                _ProfileDetails(profile: profile),
                const SizedBox(height: 12),
                const _ProfileActions(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final ProfileView profile;

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
                  profile.fullName,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.phone,
                  style: const TextStyle(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Chip(
            label: Text(
              profile.isTeacher ? 'Преподаватель' : 'Ученик',
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
  final ProfileView profile;

  const _ProfileDetails({required this.profile});

  @override
  Widget build(BuildContext context) {
    final rows = <_ProfileRow>[
      _ProfileRow(label: 'Телефон', value: profile.phone),
    ];
    if (profile.isTeacher) {
      rows.addAll([
        _ProfileRow(label: 'Предмет', value: profile.subject),
        _ProfileRow(label: 'Email', value: profile.email),
        _ProfileRow(label: 'Кабинет', value: profile.room),
        _ProfileRow(label: 'Заметка', value: profile.note),
      ]);
    } else {
      rows.add(_ProfileRow(label: 'Класс', value: profile.className));
    }
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
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
  final String? value;

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
              value == null || value!.isEmpty ? '—' : value!,
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

class _MessageCard extends StatelessWidget {
  final String text;

  const _MessageCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(text, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
