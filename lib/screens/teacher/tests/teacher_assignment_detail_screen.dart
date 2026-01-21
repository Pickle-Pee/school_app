import 'package:flutter/material.dart';
import 'package:school_test_app/services/teacher_api_service.dart';
import 'package:school_test_app/theme/app_theme.dart';

class TeacherAssignmentDetailScreen extends StatefulWidget {
  const TeacherAssignmentDetailScreen({Key? key}) : super(key: key);

  @override
  State<TeacherAssignmentDetailScreen> createState() =>
      _TeacherAssignmentDetailScreenState();
}

class _TeacherAssignmentDetailScreenState
    extends State<TeacherAssignmentDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  int? _assignmentId;

  // режим просмотра ответов ученика
  bool _reviewMode = false;
  String? _studentName;
  dynamic _answers; // Map или List или null

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && _assignmentId == null) {
      _assignmentId = args["assignmentId"] as int?;
      _reviewMode = args["review"] == true;
      _studentName = args["studentName"]?.toString();
      _answers = args["answers"];
      _load();
    }
  }

  Future<void> _load() async {
    if (_assignmentId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await TeacherApiService.getAssignmentDetail(
          assignmentId: _assignmentId!);
      setState(() => _data = d);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    if (_assignmentId == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Удалить задание?"),
        content: const Text("Действие необратимо."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Отмена")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Удалить")),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await TeacherApiService.deleteAssignment(assignmentId: _assignmentId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Удалено")));
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String _formatAnswer(dynamic a) {
    if (a == null) return "—";
    if (a is String) return a.isEmpty ? "—" : a;
    if (a is num || a is bool) return a.toString();
    if (a is List) {
      if (a.isEmpty) return "—";
      return a
          .map((e) => e?.toString() ?? "")
          .where((s) => s.isNotEmpty)
          .join(", ");
    }
    if (a is Map) return a.toString();
    return a.toString();
  }

  dynamic _getAnswerForIndex(int i) {
    final qList = (_data?["questions"] as List?) ?? const [];
    final q = (i < qList.length && qList[i] is Map)
        ? Map<String, dynamic>.from(qList[i] as Map)
        : null;

    if (_answers == null) return null;

    // List by index
    if (_answers is List) {
      final list = List<dynamic>.from(_answers as List);
      return (i < list.length) ? list[i] : null;
    }

    // Map: q1/q2..., by question id, or by prompt
    if (_answers is Map) {
      final m = Map<String, dynamic>.from(_answers as Map);

      final key = "q${i + 1}";
      if (m.containsKey(key)) return m[key];

      final qid = q?["id"];
      if (qid != null) {
        final idKey = qid.toString();
        if (m.containsKey(idKey)) return m[idKey];
      }

      final prompt = q?["prompt"]?.toString();
      if (prompt != null && m.containsKey(prompt)) return m[prompt];
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = _reviewMode ? "Ответы ученика" : "Задание";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!_reviewMode)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _loading ? null : _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorCard(error: _error!, onRetry: _load)
                  : _data == null
                      ? const Text("Нет данных")
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _data!["title"]?.toString() ?? "Задание",
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(fontSize: 20),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Тип: ${_data!["type"]}",
                                    style: theme.textTheme.bodyLarge
                                        ?.copyWith(color: Colors.white70),
                                  ),
                                  if (_reviewMode && _studentName != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      "Ученик: $_studentName",
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(color: Colors.white70),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    const Icon(Icons.repeat_rounded,
                                        color: AppTheme.primaryColor),
                                    const SizedBox(width: 10),
                                    Text(
                                        "max_attempts: ${_data!["max_attempts"]}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text("Вопросы",
                                style: theme.textTheme.headlineSmall),
                            const SizedBox(height: 10),
                            Expanded(
                              child: ListView.builder(
                                itemCount: (_data!["questions"] as List).length,
                                itemBuilder: (_, i) {
                                  final q = Map<String, dynamic>.from(
                                      (_data!["questions"] as List)[i] as Map);

                                  final studentAnswer = _reviewMode
                                      ? _getAnswerForIndex(i)
                                      : null;

                                  return Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text("Вопрос ${i + 1}",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800)),
                                          const SizedBox(height: 6),
                                          Text(q["prompt"]?.toString() ?? ""),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              Chip(
                                                  label: Text(
                                                      "type: ${q["type"]}")),
                                              Chip(
                                                  label: Text(
                                                      "points: ${q["points"]}")),
                                              if (q["required"] != null)
                                                Chip(
                                                    label: Text(
                                                        "required: ${q["required"]}")),
                                            ],
                                          ),
                                          if (q["options"] != null) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                                "options: ${(q["options"] as List).join(", ")}"),
                                          ],

                                          // режим просмотра ученика: показываем его ответ
                                          if (_reviewMode) ...[
                                            const SizedBox(height: 12),
                                            const Divider(),
                                            const SizedBox(height: 8),
                                            const Text(
                                              "Ответ ученика:",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w800),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(_formatAnswer(studentAnswer)),
                                          ],

                                          // правильный ответ полезен и в обычном режиме, и в review
                                          if (q["correct_answer"] != null) ...[
                                            const SizedBox(height: 10),
                                            Text(
                                                "correct: ${q["correct_answer"]}"),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
        ),
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
