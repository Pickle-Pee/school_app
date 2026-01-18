import 'package:flutter/material.dart';
import 'package:school_test_app/services/student_api_service.dart';
import 'package:school_test_app/theme/app_theme.dart';
import 'package:school_test_app/widgets/app_navigator.dart';

class StudentMaterialsScreen extends StatefulWidget {
  const StudentMaterialsScreen({Key? key}) : super(key: key);

  @override
  State<StudentMaterialsScreen> createState() => _StudentMaterialsScreenState();
}

class _StudentMaterialsScreenState extends State<StudentMaterialsScreen> {
  bool _loading = true;
  String? _error;

  List<dynamic> _subjects = [];
  String? _selectedSubject;

  List<dynamic> _topics = [];
  int? _selectedTopicId;

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
      final subjects = await StudentApiService.getSubjects();
      setState(() {
        _subjects = subjects;
        _selectedSubject = subjects.isNotEmpty
            ? (subjects.first as Map)["name"]?.toString()
            : null;
      });
      await _loadTopics();
      await _loadTheory();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadTopics() async {
    if (_selectedSubject == null) return;

    final topics =
        await StudentApiService.getTopics(subject: _selectedSubject!);

    // список id и безопасный выбор
    final topicIds = topics
        .map((t) => Map<String, dynamic>.from(t as Map)["id"])
        .where((id) => id is num)
        .map((id) => (id as num).toInt())
        .toSet()
        .toList();

    final safeTopicId =
        (_selectedTopicId != null && topicIds.contains(_selectedTopicId))
            ? _selectedTopicId
            : (topicIds.isNotEmpty ? topicIds.first : null);

    setState(() {
      _topics = topics;
      _selectedTopicId = safeTopicId;
    });
  }

  Future<void> _loadTheory() async {
    if (_selectedSubject == null || _selectedTopicId == null) {
      setState(() => _theory = []);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await StudentApiService.getTheory(
        subject: _selectedSubject!,
        topicId: _selectedTopicId!,
      );
      setState(() => _theory = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: appHeader("Материалы", context: context),
      body: SafeArea(
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
                      child: const Icon(Icons.menu_book_rounded,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Теория",
                              style: theme.textTheme.headlineMedium
                                  ?.copyWith(fontSize: 22)),
                          const SizedBox(height: 6),
                          Text("Выберите тему и изучайте материалы",
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_error != null) _ErrorCard(error: _error!, onRetry: _init),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Builder(
                    builder: (context) {
                      // SUBJECTS: уникальные имена
                      final subjectNames = _subjects
                          .map((s) =>
                              Map<String, dynamic>.from(s as Map)["name"]
                                  ?.toString() ??
                              "")
                          .where((n) => n.isNotEmpty)
                          .toSet()
                          .toList()
                        ..sort();

                      final safeSubject = (_selectedSubject != null &&
                              subjectNames.contains(_selectedSubject))
                          ? _selectedSubject
                          : (subjectNames.isNotEmpty
                              ? subjectNames.first
                              : null);

                      if (_selectedSubject != safeSubject) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() => _selectedSubject = safeSubject);
                        });
                      }

                      // TOPICS: строим список topicId + lookup title
                      final topicList = _topics
                          .map((t) => Map<String, dynamic>.from(t as Map))
                          .where((m) => m["id"] is num)
                          .toList();

                      final topicIds = topicList
                          .map((m) => (m["id"] as num).toInt())
                          .toSet()
                          .toList();

                      final safeTopicId = (_selectedTopicId != null &&
                              topicIds.contains(_selectedTopicId))
                          ? _selectedTopicId
                          : (topicIds.isNotEmpty ? topicIds.first : null);

                      if (_selectedTopicId != safeTopicId) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() => _selectedTopicId = safeTopicId);
                        });
                      }

                      String topicTitleById(int id) {
                        final m = topicList.firstWhere(
                          (x) => (x["id"] as num).toInt() == id,
                          orElse: () => const {},
                        );
                        final title = m["title"]?.toString();
                        return (title == null || title.isEmpty)
                            ? "Тема #$id"
                            : title;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Фильтры",
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 10),

                          // SUBJECT dropdown
                          if (subjectNames.isEmpty)
                            const _InfoCard(
                                icon: Icons.inbox_rounded,
                                text: "Предметы не найдены")
                          else
                            DropdownButtonFormField<String>(
                              value: safeSubject,
                              items: subjectNames
                                  .map((name) => DropdownMenuItem(
                                      value: name, child: Text(name)))
                                  .toList(),
                              onChanged: (v) async {
                                if (v == null) return;
                                setState(() {
                                  _selectedSubject = v;
                                  _selectedTopicId =
                                      null; // сброс темы при смене предмета
                                });
                                await _loadTopics();
                                await _loadTheory();
                              },
                              decoration: const InputDecoration(
                                labelText: "Предмет",
                                prefixIcon: Icon(Icons.bookmark_rounded),
                              ),
                            ),

                          const SizedBox(height: 12),

                          // TOPIC dropdown
                          if (topicIds.isEmpty)
                            const _InfoCard(
                                icon: Icons.topic_rounded,
                                text: "Темы не найдены")
                          else
                            DropdownButtonFormField<int>(
                              value: safeTopicId,
                              items: topicIds
                                  .map((id) => DropdownMenuItem<int>(
                                        value: id,
                                        child: Text(topicTitleById(id)),
                                      ))
                                  .toList(),
                              onChanged: (v) async {
                                if (v == null) return;
                                setState(() => _selectedTopicId = v);
                                await _loadTheory();
                              },
                              decoration: const InputDecoration(
                                labelText: "Тема",
                                prefixIcon: Icon(Icons.topic_rounded),
                              ),
                            ),

                          const SizedBox(height: 10),

                          OutlinedButton.icon(
                            onPressed:
                                (safeSubject == null || safeTopicId == null)
                                    ? null
                                    : _loadTheory,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text("Обновить"),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (_loading)
                const _InfoCard(
                    icon: Icons.hourglass_empty, text: "Загружаем материалы…")
              else if (_theory.isEmpty)
                const _InfoCard(
                    icon: Icons.inbox_rounded, text: "Материалов пока нет")
              else ...[
                Text("Список", style: theme.textTheme.headlineSmall),
                const SizedBox(height: 10),
                ..._theory.map((t) {
                  final item = Map<String, dynamic>.from(t as Map);
                  return Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item["file_url"] != null
                              ? Icons.attach_file_rounded
                              : Icons.notes_rounded,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      title: Text(
                        (item["kind"]?.toString() == "file")
                            ? "Файл"
                            : "Конспект",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(item["updated_at"]?.toString() ?? ""),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/student/materials/detail',
                        arguments: {"item": item},
                      ),
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
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
            const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                SizedBox(width: 10),
                Text("Ошибка", style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            Text(error),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Повторить"),
            )
          ],
        ),
      ),
    );
  }
}
