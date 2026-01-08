import 'package:flutter/material.dart';
import 'package:school_test_app/theme/app_theme.dart';
import 'package:school_test_app/services/teacher_api_service.dart';

class TeacherAssignmentsScreen extends StatefulWidget {
  const TeacherAssignmentsScreen({Key? key}) : super(key: key);

  @override
  State<TeacherAssignmentsScreen> createState() =>
      _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> {
  bool _loading = true;
  String? _error;

  List<dynamic> _classes = [];
  Map<String, dynamic>? _selectedClass;

  String _subject = "Информатика";
  String _type = "practice"; // practice/homework

  List<dynamic> _assignments = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final classes = await TeacherApiService.getClasses();
      setState(() {
        _classes = classes;
        _selectedClass = classes.isNotEmpty
            ? Map<String, dynamic>.from(classes.first as Map)
            : null;
      });
      await _loadAssignments();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadAssignments() async {
    if (_selectedClass == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final classId = (_selectedClass!["id"] as num).toInt();
      final list = await TeacherApiService.listAssignments(
        classId: classId,
        subject: _subject,
        type: _type,
      );
      setState(() => _assignments = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String _classLabel(Map<String, dynamic> c) =>
      (c["name"]?.toString() ?? "${c["grade"] ?? ""}${c["letter"] ?? ""}");

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              title: 'Тесты и задания',
              subtitle: 'Создавайте практику и домашние задания',
              icon: Icons.assignment_rounded,
              action: ElevatedButton.icon(
                onPressed: _selectedClass == null
                    ? null
                    : () async {
                        final res = await Navigator.pushNamed(
                          context,
                          '/teacher/tests/create',
                          arguments: {
                            "class": _selectedClass,
                            "subject": _subject,
                            "type": _type,
                          },
                        );
                        if (res == true) await _loadAssignments();
                      },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Создать'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Фильтры',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 320,
                          child: DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedClass,
                            items: _classes
                                .map((c) =>
                                    DropdownMenuItem<Map<String, dynamic>>(
                                      value:
                                          Map<String, dynamic>.from(c as Map),
                                      child: Text(_classLabel(
                                          Map<String, dynamic>.from(c))),
                                    ))
                                .toList(),
                            onChanged: (v) async {
                              setState(() => _selectedClass = v);
                              await _loadAssignments();
                            },
                            decoration: const InputDecoration(
                              labelText: 'Класс',
                              prefixIcon: Icon(Icons.groups_rounded),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 320,
                          child: DropdownButtonFormField<String>(
                            value: _type,
                            items: const [
                              DropdownMenuItem(
                                  value: "practice", child: Text("Практика")),
                              DropdownMenuItem(
                                  value: "homework", child: Text("Домашка")),
                            ],
                            onChanged: (v) async {
                              setState(() => _type = v ?? "practice");
                              await _loadAssignments();
                            },
                            decoration: const InputDecoration(
                              labelText: 'Тип',
                              prefixIcon: Icon(Icons.tune_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _loadAssignments,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Обновить'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const _InfoCard(
                  icon: Icons.hourglass_empty, text: 'Загружаем задания…')
            else if (_error != null)
              _ErrorCard(error: _error!, onRetry: _init)
            else if (_assignments.isEmpty)
              const _InfoCard(
                  icon: Icons.inbox_rounded,
                  text: 'Заданий пока нет. Создайте первое.')
            else ...[
              Text('Список', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              ..._assignments.map((a) {
                final item = Map<String, dynamic>.from(a as Map);
                return Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.quiz_rounded,
                          color: AppTheme.primaryColor),
                    ),
                    title: Text(item["title"]?.toString() ?? "Задание",
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text("max_attempts: ${item["max_attempts"]}"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/teacher/tests/detail',
                      arguments: {"assignmentId": item["id"]},
                    ),
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget action;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontSize: 22)),
                const SizedBox(height: 6),
                Text(subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          action,
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoCard({required this.icon, required this.text});

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
          Icon(icon, color: AppTheme.primaryColor),
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
            const Text('Ошибка', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(error),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Повторить'),
            )
          ],
        ),
      ),
    );
  }
}
