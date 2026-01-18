import 'package:flutter/material.dart';
import 'package:school_test_app/theme/app_theme.dart';
import 'package:school_test_app/services/teacher_api_service.dart';
import 'package:school_test_app/widgets/app_navigator.dart';
import 'package:school_test_app/widgets/status_cards.dart';

class TeacherMaterialsScreen extends StatefulWidget {
  const TeacherMaterialsScreen({Key? key}) : super(key: key);

  @override
  State<TeacherMaterialsScreen> createState() => _TeacherMaterialsScreenState();
}

class _TeacherMaterialsScreenState extends State<TeacherMaterialsScreen> {
  bool _loading = true;
  String? _error;

  List<dynamic> _classes = [];
  int? _selectedClassId;

  // предмет можно брать из профиля, но пока даю выбор вручную
  String? _subject; // например "Информатика" / "Математика"
  final _subjects = const ["Информатика", "Математика"];

  List<dynamic> _theory = [];

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
        _selectedClassId = classes.isNotEmpty
            ? ((classes.first as Map)["id"] as num).toInt()
            : null;
        _subject = _subjects.first;
      });

      await _loadTheory();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadTheory() async {
    if (_selectedClassId == null || _subject == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final classId = _selectedClassId!;
      final items = await TeacherApiService.listTheory(
        classId: classId,
        subject: _subject!,
      );
      setState(() => _theory = items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String _classLabel(Map<String, dynamic> c) {
    // в бэке ClassGroup обычно имеет name
    final name = c["name"]?.toString();
    if (name != null && name.isNotEmpty) return name;
    final grade = c["grade"]?.toString() ?? '';
    final letter = c["letter"]?.toString() ?? '';
    return '$grade$letter';
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
            _Banner(
              title: 'Материалы',
              subtitle: 'Загружайте конспекты и файлы к темам урока',
              icon: Icons.menu_book_rounded,
              action: ElevatedButton.icon(
                onPressed: (_selectedClassId == null || _subject == null)
                    ? null
                    : () async {
                        final selectedClass = _classes
                            .map((e) => Map<String, dynamic>.from(e as Map))
                            .firstWhere((m) =>
                                (m["id"] as num).toInt() == _selectedClassId);

                        final res = await Navigator.pushNamed(
                          context,
                          '/teacher/materials/add',
                          arguments: {
                            "class": selectedClass,
                            "subject": _subject,
                          },
                        );

                        if (res == true) {
                          await _loadTheory();
                        }
                      },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Добавить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Фильтры
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Фильтры',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
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
                              await _loadTheory();
                            },
                            decoration: const InputDecoration(
                              labelText: 'Класс',
                              prefixIcon: Icon(Icons.groups_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _subject,
                            items: _subjects
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (val) async {
                              setState(() => _subject = val);
                              await _loadTheory();
                            },
                            decoration: const InputDecoration(
                              labelText: 'Предмет',
                              prefixIcon: Icon(Icons.bookmark_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loadTheory,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Обновить'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            if (_loading)
              const AppLoadingCard(text: 'Загружаем материалы…')
            else if (_error != null)
              AppErrorCard(error: _error!, onRetry: _init)
            else if (_theory.isEmpty)
              const AppEmptyCard(
                text: 'Материалы не найдены. Добавьте первый файл или конспект.',
              )
            else ...[
              Text('Список материалов', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 10),
              ..._theory.map((t) {
                final item = Map<String, dynamic>.from(t as Map);
                return _TheoryTile(
                  item: item,
                  // ✅ Реальная деталка материала (уже реализована)
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/teacher/materials/detail',
                    arguments: {"item": item},
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

class _Banner extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget action;

  const _Banner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.action,
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

class _TheoryTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _TheoryTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final kind = item["kind"]?.toString() ?? "text";
    final fileUrl = item["file_url"]?.toString();

    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            fileUrl != null ? Icons.attach_file_rounded : Icons.notes_rounded,
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          kind == "file" ? "Файл" : "Конспект",
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(item["updated_at"]?.toString() ?? ""),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}


