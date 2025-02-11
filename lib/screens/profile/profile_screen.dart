// screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:school_test_app/config.dart';
import 'package:school_test_app/models/user_profile.dart';
import 'package:school_test_app/services/profile_service.dart';
import 'package:school_test_app/widgets/app_navigator.dart';

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
          // 1) Пока идёт загрузка
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2) Ошибка
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          // 3) Успешно
          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: Text('Не удалось загрузить профиль'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${profile.email}',
                    style: const TextStyle(fontSize: 18.0)),
                const SizedBox(height: 8.0),
                Text('Имя: ${profile.firstName}',
                    style: const TextStyle(fontSize: 18.0)),
                const SizedBox(height: 8.0),
                Text('Фамилия: ${profile.lastName}',
                    style: const TextStyle(fontSize: 18.0)),
                const SizedBox(height: 8.0),
                Text('Роль: ${profile.role}',
                    style: const TextStyle(fontSize: 18.0)),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/test_history');
                  },
                  child: const Text('История тестирования'),
                ),
                const SizedBox(height: 8.0),
                // ElevatedButton(
                //   onPressed: () {
                //     Navigator.pushNamed(context, '/performance');
                //   },
                //   child: const Text('Успеваемость'),
                // ),
              ],
            ),
          );
        },
      ),
    );
  }
}
