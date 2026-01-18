import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:school_test_app/config.dart';
import 'package:school_test_app/services/auth_service.dart';
import 'package:school_test_app/theme/app_theme.dart';
import 'package:school_test_app/utils/session_manager.dart';
import 'package:school_test_app/widgets/app_navigator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  String? _error;

  String? _role; // "teacher" | "student"
  Map<String, dynamic>? _profile; // profile payload

  @override
  void initState() {
    super.initState();
    _load();
  }

  static dynamic decodeJson(http.Response resp) {
    final body = utf8.decode(resp.bodyBytes);
    return json.decode(body);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await SessionManager.getAccessToken();
      if (token == null) throw Exception("Нет access token");

      final resp = await http.get(
        Uri.parse("${Config.baseUrl}/me"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (resp.statusCode != 200) {
        throw Exception("me: ${resp.statusCode} ${resp.body}");
      }

      final data = decodeJson(resp) as Map<String, dynamic>;
      final role = data["role"]?.toString();
      final profile = data["profile"];

      if (role != "teacher" && role != "student") {
        throw Exception("Неизвестная роль: $role");
      }
      if (profile is! Map) {
        throw Exception("Некорректный формат profile");
      }

      setState(() {
        _role = role;
        _profile = Map<String, dynamic>.from(profile);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cfg = _role == null
        ? null
        : (_role == "teacher"
            ? _teacherConfig(context, _profile ?? {})
            : _studentConfig(context, _profile ?? {}));

    return Scaffold(
      appBar: appHeader("Профиль", context: context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHero(
                title: cfg?.heroTitle ?? "Профиль",
                subtitle: cfg?.heroSubtitle ?? "Данные аккаунта",
                icon: cfg?.heroIcon ?? Icons.person_rounded,
              ),
              const SizedBox(height: 14),
              if (_loading)
                const _LoadingCard(text: "Загружаем профиль…")
              else if (_error != null)
                _ErrorCard(error: _error!, onRetry: _load)
              else if (cfg == null)
                const _LoadingCard(text: "Определяем роль…")
              else ...[
                _SectionTitle("Статус"),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: cfg.chips,
                ),
                const SizedBox(height: 16),
                _SectionTitle("Быстрые действия"),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: cfg.actions,
                ),
                const SizedBox(height: 16),
                _SectionTitle("Данные профиля"),
                const SizedBox(height: 10),
                ...cfg.infoTiles,
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await AuthService.logout();
                    if (!mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (r) => false);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text("Выйти"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------- CONFIGS ----------

  _ProfileConfig _teacherConfig(BuildContext context, Map<String, dynamic> p) {
    final subject = (p["subject"] ?? "").toString();
    final room = (p["room"] ?? "").toString();

    return _ProfileConfig(
      heroTitle: "Преподаватель",
      heroSubtitle: "Данные аккаунта и быстрые действия",
      heroIcon: Icons.cast_for_education_rounded,
      chips: [
        const Chip(
          avatar:
              Icon(Icons.badge_rounded, size: 18, color: AppTheme.primaryColor),
          label: Text("Моя роль: Учитель"),
        ),
        if (subject.isNotEmpty)
          Chip(
            avatar: const Icon(Icons.menu_book_rounded,
                size: 18, color: AppTheme.primaryColor),
            label: Text("Предмет: $subject"),
          ),
        if (room.isNotEmpty)
          Chip(
            avatar: const Icon(Icons.meeting_room_rounded,
                size: 18, color: AppTheme.primaryColor),
            label: Text("Кабинет: $room"),
          ),
      ],
      actions: [
        _ActionCardSmall(
          icon: Icons.upload_file_rounded,
          title: "Материалы",
          description: "Конспекты и файлы",
          onTap: () => Navigator.pushNamed(context, '/teacher/materials'),
        ),
        _ActionCardSmall(
          icon: Icons.quiz_rounded,
          title: "Тесты",
          description: "Создать задание",
          onTap: () => Navigator.pushNamed(context, '/teacher/tests/create'),
        ),
        _ActionCardSmall(
          icon: Icons.groups_rounded,
          title: "Ученики",
          description: "Списки и классы",
          onTap: () => Navigator.pushNamed(context, '/teacher/students'),
        ),
        _ActionCardSmall(
          icon: Icons.bar_chart_rounded,
          title: "Результаты",
          description: "Оценки и попытки",
          onTap: () => Navigator.pushNamed(context, '/teacher/results'),
        ),
      ],
      infoTiles: [
        _InfoTile(
          icon: Icons.person_rounded,
          label: "ФИО",
          value: (p["full_name"] ?? "—").toString(),
        ),
        _InfoTile(
          icon: Icons.phone_rounded,
          label: "Телефон",
          value: (p["phone"] ?? "—").toString(),
        ),
        _InfoTile(
          icon: Icons.alternate_email_rounded,
          label: "Email",
          value: (p["email"] ?? "—").toString(),
        ),
        _InfoTile(
          icon: Icons.sticky_note_2_rounded,
          label: "Заметка",
          value: (() {
            final note = p["note"];
            if (note == null) return "—";
            final s = note.toString().trim();
            return s.isEmpty ? "—" : s;
          })(),
          multiline: true,
        ),
      ],
    );
  }

  _ProfileConfig _studentConfig(BuildContext context, Map<String, dynamic> p) {
    final classGroup = (p["class_group"] ?? "").toString();

    return _ProfileConfig(
      heroTitle: "Ученик",
      heroSubtitle: "Ваш класс и быстрые действия",
      heroIcon: Icons.laptop_chromebook_rounded,
      chips: [
        const Chip(
          avatar:
              Icon(Icons.badge_rounded, size: 18, color: AppTheme.primaryColor),
          label: Text("Моя роль: Ученик"),
        ),
        if (classGroup.isNotEmpty)
          Chip(
            avatar: const Icon(Icons.groups_rounded,
                size: 18, color: AppTheme.primaryColor),
            label: Text("Класс: $classGroup"),
          ),
      ],
      actions: [
        _ActionCardSmall(
          icon: Icons.menu_book_rounded,
          title: "Материалы",
          description: "Теория и файлы",
          onTap: () => Navigator.pushNamed(context, '/student/materials'),
        ),
        _ActionCardSmall(
          icon: Icons.quiz_rounded,
          title: "Тесты",
          description: "Практика и ДЗ",
          onTap: () => Navigator.pushNamed(context, '/student/tests'),
        ),
        _ActionCardSmall(
          icon: Icons.star_rounded,
          title: "Оценки",
          description: "Средний балл",
          onTap: () => Navigator.pushNamed(context, '/student/grades'),
        ),
      ],
      infoTiles: [
        _InfoTile(
          icon: Icons.person_rounded,
          label: "ФИО",
          value: (p["full_name"] ?? "—").toString(),
        ),
        _InfoTile(
          icon: Icons.phone_rounded,
          label: "Телефон",
          value: (p["phone"] ?? "—").toString(),
        ),
        _InfoTile(
          icon: Icons.groups_rounded,
          label: "Класс",
          value: classGroup.isEmpty ? "—" : classGroup,
        ),
      ],
    );
  }
}

// ---------- MODELS / UI ----------

class _ProfileConfig {
  final String heroTitle;
  final String heroSubtitle;
  final IconData heroIcon;
  final List<Widget> chips;
  final List<Widget> actions;
  final List<Widget> infoTiles;

  _ProfileConfig({
    required this.heroTitle,
    required this.heroSubtitle,
    required this.heroIcon,
    required this.chips,
    required this.actions,
    required this.infoTiles,
  });
}

class _ProfileHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ProfileHero({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.headlineSmall);
  }
}

class _LoadingCard extends StatelessWidget {
  final String text;
  const _LoadingCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorCard({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                SizedBox(width: 10),
                Text("Ошибка", style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            Text(error, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Повторить"),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool multiline;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(
          value,
          maxLines: multiline ? 4 : 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(label),
      ),
    );
  }
}

class _ActionCardSmall extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ActionCardSmall({
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
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
