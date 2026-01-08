import 'package:flutter/material.dart';
import 'package:school_test_app/services/teacher_api_service.dart';
import 'package:school_test_app/theme/app_theme.dart';

class TeacherAssignmentDetailScreen extends StatefulWidget {
  const TeacherAssignmentDetailScreen({Key? key}) : super(key: key);

  @override
  State<TeacherAssignmentDetailScreen> createState() => _TeacherAssignmentDetailScreenState();
}

class _TeacherAssignmentDetailScreenState extends State<TeacherAssignmentDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  int? _assignmentId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && _assignmentId == null) {
      _assignmentId = args["assignmentId"] as int?;
      _load();
    }
  }

  Future<void> _load() async {
    if (_assignmentId == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final d = await TeacherApiService.getAssignmentDetail(assignmentId: _assignmentId!);
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Отмена")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Удалить")),
        ],
      ),
    );

    if (ok != true) return;

    setState(() { _loading = true; _error = null; });
    try {
      await TeacherApiService.deleteAssignment(assignmentId: _assignmentId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Удалено")));
      Navigator.pop(context, true);
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
      appBar: AppBar(
        title: const Text("Задание"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _loading ? null : _delete,
          )
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
                                    style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Тип: ${_data!["type"]}",
                                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    const Icon(Icons.repeat_rounded, color: AppTheme.primaryColor),
                                    const SizedBox(width: 10),
                                    Text("max_attempts: ${_data!["max_attempts"]}",
                                        style: const TextStyle(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                            Text("Вопросы", style: theme.textTheme.headlineSmall),
                            const SizedBox(height: 10),

                            Expanded(
                              child: ListView.builder(
                                itemCount: (_data!["questions"] as List).length,
                                itemBuilder: (_, i) {
                                  final q = (_data!["questions"] as List)[i] as Map;
                                  return Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Вопрос ${i + 1}",
                                              style: const TextStyle(fontWeight: FontWeight.w800)),
                                          const SizedBox(height: 6),
                                          Text(q["prompt"]?.toString() ?? ""),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              Chip(label: Text("type: ${q["type"]}")),
                                              Chip(label: Text("points: ${q["points"]}")),
                                              if (q["required"] != null)
                                                Chip(label: Text("required: ${q["required"]}")),
                                            ],
                                          ),
                                          if (q["options"] != null) ...[
                                            const SizedBox(height: 8),
                                            Text("options: ${(q["options"] as List).join(", ")}"),
                                          ],
                                          if (q["correct_answer"] != null) ...[
                                            const SizedBox(height: 8),
                                            Text("correct: ${q["correct_answer"]}"),
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
