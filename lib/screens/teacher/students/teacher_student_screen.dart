import 'package:flutter/material.dart';
import 'package:school_test_app/services/teacher_api_service.dart';
import 'package:school_test_app/theme/app_theme.dart';

class TeacherStudentsScreen extends StatefulWidget {
  const TeacherStudentsScreen({Key? key}) : super(key: key);

  @override
  State<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends State<TeacherStudentsScreen> {
  bool _loading = true;
  String? _error;

  List<dynamic> _classes = [];
  int? _selectedClassId;

  String _subject = "Информатика";
  final _subjects = const ["Информатика", "Математика"];

  List<dynamic> _students = []; // из grades/summary -> students

  @override
  void initState() {
    super.initState();
    _init();
  }

  String _classLabel(Map<String, dynamic> c) =>
      (c["name"]?.toString() ?? "${c["grade"] ?? ""}${c["letter"] ?? ""}");

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final classes = await TeacherApiService.getClasses();

      setState(() {
        _classes = classes;
        _selectedClassId = classes.isNotEmpty
            ? ((classes.first as Map)["id"] as num).toInt()
            : null;
      });

      await _load();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? get _selectedClassMap {
    if (_selectedClassId == null) return null;
    final found = _classes.cast<Map>().firstWhere(
          (c) => (c["id"] as num).toInt() == _selectedClassId,
          orElse: () => {},
        );
    return found.isEmpty ? null : Map<String, dynamic>.from(found);
  }

  Future<void> _load() async {
    if (_selectedClassId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await TeacherApiService.getGradesSummary(
        classId: _selectedClassId!,
        subject: _subject,
      );

      final raw = data["students"];
      final students = (raw is List) ? List<dynamic>.from(raw) : <dynamic>[];
      setState(() => _students = students);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
                    child:
                        const Icon(Icons.groups_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Ученики",
                            style: theme.textTheme.headlineMedium
                                ?.copyWith(fontSize: 22)),
                        const SizedBox(height: 6),
                        Text("Список и средняя оценка по предмету",
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Фильтры",
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width:
                              320, // на web красиво, на мобилке Wrap сам перенесёт
                          child: DropdownButtonFormField<int>(
                            value: _selectedClassId,
                            items: _classes.map((c) {
                              final m = Map<String, dynamic>.from(c as Map);
                              final id = (m["id"] as num).toInt();
                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text(_classLabel(m)),
                              );
                            }).toList(),
                            onChanged: (id) async {
                              setState(() => _selectedClassId = id);
                              await _load();
                            },
                            decoration: const InputDecoration(
                              labelText: "Класс",
                              prefixIcon: Icon(Icons.school_rounded),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 320,
                          child: DropdownButtonFormField<String>(
                            value: _subject,
                            items: _subjects
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) async {
                              setState(() => _subject = v ?? _subject);
                              await _load();
                            },
                            decoration: const InputDecoration(
                              labelText: "Предмет",
                              prefixIcon: Icon(Icons.bookmark_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text("Обновить"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              _ErrorCard(error: _error!, onRetry: _init)
            else if (_students.isEmpty)
              const _InfoCard(
                  icon: Icons.inbox_rounded, text: "Ученики не найдены")
            else ...[
              Text("Список", style: theme.textTheme.headlineSmall),
              const SizedBox(height: 10),
              ..._students.map((s) {
                final m = Map<String, dynamic>.from(s as Map);
                return Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: AppTheme.primaryColor),
                    ),
                    title: Text(m["full_name"]?.toString() ?? "Ученик",
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text("avg: ${m["avg_grade"]}"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // можно вести в результаты (пока без фильтра по student_id)
                      Navigator.pushNamed(context, '/teacher/results',
                          arguments: {
                            "class": _selectedClassMap,
                            "subject": _subject,
                          });
                    },
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
