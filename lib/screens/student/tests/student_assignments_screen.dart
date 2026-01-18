import 'package:flutter/material.dart';
import 'package:school_test_app/services/student_api_service.dart';
import 'package:school_test_app/theme/app_theme.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({Key? key}) : super(key: key);

  @override
  State<StudentAssignmentsScreen> createState() =>
      _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  bool _loading = true;
  String? _error;

  List<dynamic> _subjects = [];
  String? _selectedSubject;

  List<dynamic> _topics = [];
  int? _selectedTopicId;

  List<dynamic> _assignments = [];

  String? get _type {
    switch (_tabCtrl.index) {
      case 0:
        return null; // все
      case 1:
        return "practice";
      case 2:
        return "homework";
      default:
        return "practice";
    }
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() async {
      if (_tabCtrl.indexIsChanging) return;
      await _loadAssignments();
    });
    _init();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
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
      await _loadAssignments();
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

  Future<void> _loadAssignments() async {
    if (_selectedSubject == null || _selectedTopicId == null) {
      setState(() => _assignments = []);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await StudentApiService.getAssignments(
        subject: _selectedSubject!,
        type: _type,
        topicId: _selectedTopicId!,
      );
      setState(() => _assignments = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String _typeTitle(String? type) {
    switch (type) {
      case "practice":
        return "Практика";
      case "homework":
        return "Домашка";
      default:
        return "Все задания";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Тесты"),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          // TODO: Изменить цвет табов на белый
          tabs: const [
            Tab(text: "Все"),
            Tab(text: "Практика"),
            Tab(text: "Домашка"),
          ],
        ),
      ),
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
                      child:
                          const Icon(Icons.quiz_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_typeTitle(_type),
                              style: theme.textTheme.headlineMedium
                                  ?.copyWith(fontSize: 22)),
                          const SizedBox(height: 6),
                          Text("Выберите тему и выполните задания",
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // if (_error != null) _ErrorCard(error: _error!, onRetry: _init),
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

                      // TOPICS: ids + title lookup
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
                                await _loadAssignments();
                              },
                              decoration: const InputDecoration(
                                labelText: "Предмет",
                                prefixIcon: Icon(Icons.bookmark_rounded),
                              ),
                            ),
                          const SizedBox(height: 12),
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
                                await _loadAssignments();
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
                                    : _loadAssignments,
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
                    icon: Icons.hourglass_empty, text: "Загружаем задания…")
              else if (_assignments.isEmpty)
                const _InfoCard(
                    icon: Icons.inbox_rounded, text: "Заданий пока нет")
              else ...[
                Text("Список заданий", style: theme.textTheme.headlineSmall),
                const SizedBox(height: 10),
                ..._assignments.map((a) {
                  final m = Map<String, dynamic>.from(a as Map);
                  final attemptsLeft =
                      (m["attempts_left"] as num?)?.toInt() ?? 0;
                  final lastGrade = m["last_grade"];

                  return Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.assignment_rounded,
                            color: AppTheme.primaryColor),
                      ),
                      title: Text(
                        m["title"]?.toString() ?? "Задание",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        "Попыток осталось: $attemptsLeft"
                        "${lastGrade != null ? " · последняя оценка: $lastGrade" : ""}",
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/student/tests/detail',
                        arguments: {"assignmentId": (m["id"] as num).toInt()},
                      ).then((_) => _loadAssignments()),
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
