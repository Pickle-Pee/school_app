import 'package:flutter/material.dart';
import 'package:school_test_app/services/student_api_service.dart';
import 'package:school_test_app/theme/app_theme.dart';
import 'package:school_test_app/widgets/app_navigator.dart';

class StudentTestPassScreen extends StatefulWidget {
  const StudentTestPassScreen({Key? key}) : super(key: key);

  @override
  State<StudentTestPassScreen> createState() => _StudentTestPassScreenState();
}

class _StudentTestPassScreenState extends State<StudentTestPassScreen> {
  bool _submitting = false;
  String? _error;

  late final int assignmentId;
  late final Map<String, dynamic> assignment;
  late final List<dynamic> questions;

  final Map<String, dynamic> _answers = {}; // q1 -> value

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    assignmentId = (args["assignmentId"] as int?) ?? (args["assignment"] as Map)["id"];
    assignment = Map<String, dynamic>.from(args["assignment"] as Map);
    questions = List<dynamic>.from(assignment["questions"] as List);

    // init defaults
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i] as Map;
      final type = q["type"]?.toString();
      final key = "q${i + 1}";
      if (_answers.containsKey(key)) continue;

      if (type == "checkbox") {
        _answers[key] = <String>[];
      } else {
        _answers[key] = null;
      }
    }
  }

  bool _isRequired(Map q) => (q["required"] == null) ? true : (q["required"] == true);

  String? _validate() {
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i] as Map;
      final key = "q${i + 1}";
      if (!_isRequired(q)) continue;

      final type = q["type"]?.toString();
      final v = _answers[key];

      if (type == "checkbox") {
        if (v is! List || v.isEmpty) return "Заполните вопрос ${i + 1}";
      } else {
        if (v == null) return "Заполните вопрос ${i + 1}";
        if (v is String && v.trim().isEmpty) return "Заполните вопрос ${i + 1}";
      }
    }
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }

    setState(() { _submitting = true; _error = null; });

    try {
      final res = await StudentApiService.submitAssignment(
        assignmentId: assignmentId,
        answers: _answers,
      );

      if (!mounted) return;
      final grade = res["grade"];
      final score = res["score"];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Отправлено! Баллы: $score, оценка: $grade")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: appHeader("Прохождение теста", context: context ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
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
                      assignment["title"]?.toString() ?? "Тест",
                      style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Вопросов: ${questions.length}",
                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (_error != null) _InlineError(text: _error!),

              Expanded(
                child: ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (_, i) {
                    final q = questions[i] as Map;
                    final type = q["type"]?.toString();
                    final prompt = q["prompt"]?.toString() ?? "";
                    final options = (q["options"] as List?)?.map((e) => e.toString()).toList() ?? [];
                    final key = "q${i + 1}";

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Вопрос ${i + 1}",
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text(prompt),
                            const SizedBox(height: 10),

                            if (type == "select")
                              _SelectBlock(
                                options: options,
                                value: _answers[key] as String?,
                                onChanged: (v) => setState(() => _answers[key] = v),
                              )
                            else if (type == "checkbox")
                              _CheckboxBlock(
                                options: options,
                                values: List<String>.from(_answers[key] as List),
                                onChanged: (vals) => setState(() => _answers[key] = vals),
                              )
                            else
                              TextField(
                                onChanged: (v) => _answers[key] = v,
                                decoration: const InputDecoration(
                                  labelText: "Ответ",
                                  prefixIcon: Icon(Icons.edit_rounded),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                label: Text(_submitting ? "Отправляем…" : "Отправить"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String text;
  const _InlineError({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

class _SelectBlock extends StatelessWidget {
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _SelectBlock({required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: onChanged,
      decoration: const InputDecoration(
        labelText: "Выберите вариант",
        prefixIcon: Icon(Icons.list_alt_rounded),
      ),
    );
  }
}

class _CheckboxBlock extends StatelessWidget {
  final List<String> options;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  const _CheckboxBlock({required this.options, required this.values, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((o) {
        final checked = values.contains(o);
        return CheckboxListTile(
          value: checked,
          onChanged: (v) {
            final next = List<String>.from(values);
            if (v == true) {
              if (!next.contains(o)) next.add(o);
            } else {
              next.remove(o);
            }
            onChanged(next);
          },
          title: Text(o),
          controlAffinity: ListTileControlAffinity.leading,
        );
      }).toList(),
    );
  }
}
