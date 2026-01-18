import 'package:flutter/material.dart';
import 'package:school_test_app/services/student_api_service.dart';
import 'package:school_test_app/theme/app_theme.dart';
import 'package:school_test_app/widgets/app_navigator.dart';
import 'package:school_test_app/widgets/status_cards.dart';

class StudentGradesScreen extends StatefulWidget {
  const StudentGradesScreen({Key? key}) : super(key: key);

  @override
  State<StudentGradesScreen> createState() => _StudentGradesScreenState();
}

class _StudentGradesScreenState extends State<StudentGradesScreen> {
  bool _loading = true;
  String? _error;

  List<dynamic> _subjects = [];
  String? _selectedSubject;

  Map<String, dynamic>? _grades; // {avg_grade, items}

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
      await _loadGrades();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadGrades() async {
    if (_selectedSubject == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await StudentApiService.getGrades(subject: _selectedSubject!);
      setState(() => _grades = Map<String, dynamic>.from(res));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final avg = _grades?["avg_grade"];
    final items = (_grades?["items"] as List?) ?? const [];

    return Scaffold(
      appBar: appHeader("Оценки", context: context),
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
                      child: const Icon(Icons.bar_chart_rounded,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Успеваемость",
                              style: theme.textTheme.headlineMedium
                                  ?.copyWith(fontSize: 22)),
                          const SizedBox(height: 6),
                          Text("Просматривайте оценки по предметам",
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_error != null) AppErrorCard(error: _error!, onRetry: _init),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Builder(
                    builder: (context) {
                      final subjectNames = _subjects
                          .map((s) =>
                              Map<String, dynamic>.from(s as Map)["name"]
                                  ?.toString() ??
                              "")
                          .where((n) => n.isNotEmpty)
                          .toSet()
                          .toList()
                        ..sort();

                      final safeSelected = (_selectedSubject != null &&
                              subjectNames.contains(_selectedSubject))
                          ? _selectedSubject
                          : (subjectNames.isNotEmpty
                              ? subjectNames.first
                              : null);

                      if (_selectedSubject != safeSelected) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() => _selectedSubject = safeSelected);
                        });
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Предмет",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          if (subjectNames.isEmpty)
                            const AppInfoCard(
                              icon: Icons.inbox_rounded,
                              text: "Предметы не найдены",
                            )
                          else
                            DropdownButtonFormField<String>(
                              value: safeSelected,
                              items: subjectNames
                                  .map(
                                    (name) => DropdownMenuItem(
                                      value: name,
                                      child: Text(name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) async {
                                if (v == null) return;
                                setState(() => _selectedSubject = v);
                                await _loadGrades();
                              },
                              decoration: const InputDecoration(
                                labelText: "Выберите предмет",
                                prefixIcon: Icon(Icons.bookmark_rounded),
                              ),
                            ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed:
                                subjectNames.isEmpty ? null : _loadGrades,
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
                const AppLoadingCard(text: "Загружаем оценки…")
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.star_rounded,
                              color: AppTheme.primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Средний балл",
                                  style:
                                      TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              Text(
                                avg != null ? avg.toString() : "—",
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text("История", style: theme.textTheme.headlineSmall),
                const SizedBox(height: 10),
                if (items.isEmpty)
                  const AppEmptyCard(text: "Оценок пока нет")
                else
                  ...items.map((it) {
                    final m = Map<String, dynamic>.from(it as Map);
                    final grade = m["grade"];
                    final title =
                        m["assignment_title"]?.toString() ?? "Задание";
                    final topicTitle = m["topic_title"]?.toString() ?? "";
                    final type = m["type"]?.toString() ?? "";
                    final submittedAt = m["submitted_at"]?.toString() ?? "";

                    return Card(
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            grade?.toString() ?? "—",
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        title: Text(title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          "$topicTitle · $type\n$submittedAt",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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


