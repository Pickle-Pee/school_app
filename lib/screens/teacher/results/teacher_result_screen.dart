import 'package:flutter/material.dart';
import 'package:school_test_app/services/teacher_api_service.dart';
import 'package:school_test_app/theme/app_theme.dart';
import 'package:school_test_app/widgets/app_navigator.dart';
import 'package:school_test_app/widgets/status_cards.dart';

class TeacherResultsScreen extends StatefulWidget {
  const TeacherResultsScreen({Key? key}) : super(key: key);

  @override
  State<TeacherResultsScreen> createState() => _TeacherResultsScreenState();
}

class _TeacherResultsScreenState extends State<TeacherResultsScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;

  List<dynamic> _classes = [];
  int? _selectedClassId;

  String _subject = "Информатика";
  final _subjects = const ["Информатика", "Математика"];

  String? _type; // null => все

  List<dynamic> _topics = [];
  int? _selectedTopicId;

  List<dynamic> _items = []; // grades/by-topic items

  bool _compactFilters = false; // если пришли с экрана класса/ученика

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      // Если пришли из списка учеников/класса — можем зафиксировать класс/предмет
      final cls = args["class"];
      final subj = args["subject"];
      final compact = args["compact"];
      if (cls is Map && _selectedClassId == null) {
        final m = Map<String, dynamic>.from(cls);
        final id = (m["id"] as num?)?.toInt();
        if (id != null) {
          _selectedClassId = id;
          _compactFilters = (compact == true);
        }
      }
      if (subj is String && subj.trim().isNotEmpty) {
        _subject = subj;
      }
    }
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
        _selectedClassId ??= classes.isNotEmpty
            ? ((classes.first as Map)["id"] as num).toInt()
            : null;
      });
      await _loadTopics();
      await _loadResults();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadTopics() async {
    if (_selectedClassId == null) return;

    final topics = await TeacherApiService.getTopics(
      classId: _selectedClassId!,
      subject: _subject,
    );

    setState(() {
      _topics = topics;
      _selectedTopicId = topics.isNotEmpty
          ? ((topics.first as Map)["id"] as num).toInt()
          : null;
    });
  }

  Future<void> _loadResults() async {
    if (_selectedClassId == null || _selectedTopicId == null) {
      setState(() => _items = []);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await TeacherApiService.getGradesByTopic(
        classId: _selectedClassId!,
        topicId: _selectedTopicId!,
        type: _type,
        subject: _subject,
        page: 1,
        pageSize: 50,
      );

      setState(() =>
          _items = List<dynamic>.from((res["items"] as List?) ?? const []));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resetAttempts(int studentId, int assignmentId) async {
    try {
      await TeacherApiService.resetAttempts(
          studentId: studentId, assignmentId: assignmentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Попытки сброшены")),
      );
      await _loadResults();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: appHeader(
        "Результаты",
        context: context,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ---------------- TAB 1: РЕЗУЛЬТАТЫ (твой текущий экран) ----------------
          SafeArea(
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
                          child: const Icon(Icons.bar_chart_rounded,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Результаты",
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(fontSize: 22)),
                              const SizedBox(height: 6),
                              Text("Оценки учеников по теме и типу задания",
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
                          if (!_compactFilters)
                            DropdownButtonFormField<int>(
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
                                await _loadTopics();
                                await _loadResults();
                              },
                              decoration: const InputDecoration(
                                labelText: "Класс",
                                prefixIcon: Icon(Icons.school_rounded),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (!_compactFilters) ...[
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _subject,
                                    items: _subjects
                                        .map((s) => DropdownMenuItem(
                                            value: s, child: Text(s)))
                                        .toList(),
                                    onChanged: (v) async {
                                      setState(() => _subject = v ?? _subject);
                                      await _loadTopics();
                                      await _loadResults();
                                    },
                                    decoration: const InputDecoration(
                                      labelText: "Предмет",
                                      prefixIcon: Icon(Icons.bookmark_rounded),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: DropdownButtonFormField<String?>(
                                  value: _type,
                                  items: const [
                                    DropdownMenuItem(
                                        value: null, child: Text("Все")),
                                    DropdownMenuItem(
                                        value: "practice",
                                        child: Text("Практика")),
                                    DropdownMenuItem(
                                        value: "homework",
                                        child: Text("Домашка")),
                                  ],
                                  onChanged: (v) async {
                                    setState(() => _type = v);
                                    await _loadResults();
                                  },
                                  decoration: const InputDecoration(
                                    labelText: "Тип",
                                    prefixIcon: Icon(Icons.tune_rounded),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: _selectedTopicId,
                            items: _topics.map((t) {
                              final m = Map<String, dynamic>.from(t as Map);
                              final id = (m["id"] as num).toInt();
                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text(m["title"]?.toString() ?? "Тема"),
                              );
                            }).toList(),
                            onChanged: (id) async {
                              setState(() => _selectedTopicId = id);
                              await _loadResults();
                            },
                            decoration: const InputDecoration(
                              labelText: "Тема",
                              prefixIcon: Icon(Icons.topic_rounded),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _loadResults,
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
                    AppErrorCard(error: _error!, onRetry: _init)
                  else if (_items.isEmpty)
                    const AppInfoCard(
                        icon: Icons.inbox_rounded, text: "Результатов пока нет")
                  else ...[
                    Text("Список результатов",
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    ..._items.map((it) {
                      final m = Map<String, dynamic>.from(it as Map);
                      final studentId = (m["student_id"] as num?)?.toInt() ?? 0;
                      final assignmentId =
                          (m["assignment_id"] as num?)?.toInt() ?? 0;

                      final grade = m["grade"]?.toString() ?? "—";
                      final score = m["score"]?.toString() ?? "—";
                      final attemptNo = m["attempt_no"]?.toString() ?? "—";

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m["student_name"]?.toString() ?? "Ученик",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(m["assignment_title"]?.toString() ??
                                  "Задание"),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  Chip(label: Text("Оценка: $grade")),
                                  Chip(label: Text("Баллы: $score")),
                                  Chip(label: Text("Попытка: $attemptNo")),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: assignmentId == 0
                                        ? null
                                        : () => Navigator.pushNamed(
                                              context,
                                              '/teacher/tests/detail',
                                              arguments: {
                                                "assignmentId": assignmentId
                                              },
                                            ),
                                    icon: const Icon(Icons.visibility_rounded),
                                    label: const Text("Задание"),
                                  ),
                                  TextButton.icon(
                                    onPressed:
                                        (studentId == 0 || assignmentId == 0)
                                            ? null
                                            : () => _resetAttempts(
                                                studentId, assignmentId),
                                    icon: const Icon(Icons.restart_alt_rounded),
                                    label: const Text("Сброс попыток"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
