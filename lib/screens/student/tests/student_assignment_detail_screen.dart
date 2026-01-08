import 'package:flutter/material.dart';
import 'package:school_test_app/services/student_api_service.dart';
import 'package:school_test_app/theme/app_theme.dart';

class StudentAssignmentDetailScreen extends StatefulWidget {
  const StudentAssignmentDetailScreen({Key? key}) : super(key: key);

  @override
  State<StudentAssignmentDetailScreen> createState() => _StudentAssignmentDetailScreenState();
}

class _StudentAssignmentDetailScreenState extends State<StudentAssignmentDetailScreen> {
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
      final d = await StudentApiService.getAssignmentDetail(assignmentId: _assignmentId!);
      setState(() => _data = d);
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
      appBar: AppBar(title: const Text("Задание")),
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
                                    "max_attempts: ${_data!["max_attempts"]}",
                                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                                  ),
                                ],
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
                                  final type = q["type"]?.toString() ?? "";
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
                                              Chip(label: Text(type)),
                                              Chip(label: Text("points: ${q["points"]}")),
                                              if (q["required"] != null) Chip(label: Text("required: ${q["required"]}")),
                                            ],
                                          ),
                                          if (q["options"] != null) ...[
                                            const SizedBox(height: 8),
                                            Text("Варианты: ${(q["options"] as List).join(", ")}"),
                                          ]
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final res = await Navigator.pushNamed(
                                  context,
                                  '/student/tests/pass',
                                  arguments: {"assignment": _data, "assignmentId": _assignmentId},
                                );
                                if (res == true && mounted) Navigator.pop(context, true);
                              },
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text("Начать"),
                            )
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
