import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:school_test_app/services/teacher_api_service.dart';
import 'package:school_test_app/theme/app_theme.dart';

class TeacherCreateAssignmentScreen extends StatefulWidget {
  const TeacherCreateAssignmentScreen({Key? key}) : super(key: key);

  @override
  State<TeacherCreateAssignmentScreen> createState() =>
      _TeacherCreateAssignmentScreenState();
}

class _TeacherCreateAssignmentScreenState
    extends State<TeacherCreateAssignmentScreen> {
  bool _topicsLoading = false;
  bool _submitting = false;
  String? _error;
  bool _classesLoading = false;

  // Class can be passed via route arguments, but the screen can also
  // be opened directly from Home (then we fetch classes and allow selection).
  List<dynamic> _classes = [];
  Map<String, dynamic>? _selectedClass;
  String _subject = "Информатика";
  String _type = "practice";

  List<dynamic> _topics = [];
  Map<String, dynamic>? _selectedTopic;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _maxAttemptsCtrl = TextEditingController(text: "3");
  final _topicTitleCtrl = TextEditingController();

  bool _published = true;

  final List<_QuestionForm> _questions = [
    _QuestionForm(type: "select"),
  ];

  String _classLabel(Map<String, dynamic> c) {
    final name = c["name"]?.toString();
    if (name != null && name.isNotEmpty) return name;

    final grade = c["grade"]?.toString() ?? "";
    final letter = c["letter"]?.toString() ?? "";
    return "$grade$letter";
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _maxAttemptsCtrl.dispose();
    _topicTitleCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;

    // Already initialized
    if (_selectedClass != null || _classes.isNotEmpty) return;

    if (args != null && args["class"] != null) {
      _selectedClass = Map<String, dynamic>.from(args["class"] as Map);
      _subject = (args["subject"] as String?) ?? _subject;
      _type = (args["type"] as String?) ?? _type;
      _initTopics();
    } else {
      // Opened without args: load teacher classes and let user select
      _initClasses();
    }
  }

  Future<void> _initClasses() async {
    setState(() {
      _classesLoading = true;
      _error = null;
    });

    try {
      final classes = await TeacherApiService.getClasses();

      final normalized = classes
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);

      setState(() {
        _classes = normalized;
        _selectedClass = normalized.isNotEmpty ? normalized.first : null;
      });

      await _initTopics();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _classesLoading = false);
    }
  }

  Future<void> _initTopics() async {
    setState(() {
      _topicsLoading = true;
      _error = null;
    });

    try {
      if (_selectedClass == null) {
        setState(() => _topics = []);
        return;
      }

      final classId = (_selectedClass!["id"] as num).toInt();
      final topics = await TeacherApiService.getTopics(
        classId: classId,
        subject: _subject,
      );
      final normalized = topics
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);

      setState(() {
        _topics = normalized;
        _selectedTopic = normalized.isNotEmpty ? normalized.first : null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _topicsLoading = false);
    }
  }

  void _addQuestion() {
    setState(() => _questions.add(_QuestionForm(type: "select")));
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) return;
    setState(() => _questions.removeAt(index));
  }

  Future<void> _submit() async {
    if (_selectedClass == null) return;

    final topicTitle = _topicTitleCtrl.text.trim();
    if (topicTitle.isEmpty) {
      setState(() => _error = "Введите тему");
      return;
    }

    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = "Введите название задания");
      return;
    }

    final maxAttempts = int.tryParse(_maxAttemptsCtrl.text.trim());
    if (maxAttempts == null || maxAttempts < 1) {
      setState(() => _error = "max_attempts должен быть числом >= 1");
      return;
    }

    final questionsPayload = <Map<String, dynamic>>[];
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final err = q.validate();
      if (err != null) {
        setState(() => _error = "Вопрос ${i + 1}: $err");
        return;
      }
      questionsPayload.add(q.toPayload());
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final classId = (_selectedClass!["id"] as num).toInt();

      final ensured = await TeacherApiService.ensureTopic(
        classId: classId,
        subject: _subject,
        title: topicTitle,
      );

      final topicId = (ensured["id"] as num).toInt();

      final payload = {
        "class_id": classId,
        "subject": _subject,
        "topic_id": topicId,
        "type": _type,
        "title": title,
        "description":
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        "max_attempts": maxAttempts,
        "published": _published,
        "questions": questionsPayload,
      };

      await TeacherApiService.createAssignment(payload: payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Задание создано")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Создать тест/задание")),
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
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child:
                          const Icon(Icons.quiz_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Новый тест",
                              style: theme.textTheme.headlineMedium
                                  ?.copyWith(fontSize: 20)),
                          const SizedBox(height: 4),
                          Text(
                              "Тип: ${_type == "practice" ? "Практика" : "Домашка"}",
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(color: const Color.fromARGB(255, 63, 63, 63))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_error != null) _InlineError(text: _error!),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Параметры", style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      if (_classesLoading)
                        const _InlineLoading(text: "Загрузка классов…")
                      else
                        DropdownButtonFormField<Map<String, dynamic>>(
                          value: _selectedClass,
                          items: _classes
                              .map(
                                  (c) => DropdownMenuItem<Map<String, dynamic>>(
                                        value: c,
                                        child: Text(_classLabel(c)),
                                      ))
                              .toList(),
                          onChanged: (val) async {
                            setState(() => _selectedClass = val);
                            await _initTopics();
                          },
                          decoration: const InputDecoration(
                            labelText: "Класс",
                            prefixIcon: Icon(Icons.school_rounded),
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _topicTitleCtrl,
                        decoration: const InputDecoration(
                          labelText: "Тема",
                          prefixIcon: Icon(Icons.topic_rounded),
                          hintText: "Напр.: Алгоритмы / Циклы / Строки",
                        ),
                      ),

                      const SizedBox(height: 12),
                      TextField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: "Название",
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Материал — вручную (текст/ссылка).
                      // Храним в поле description на бэке.
                      TextField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: "Материал (текст или ссылка)",
                          prefixIcon: Icon(Icons.menu_book_rounded),
                          hintText: "Напр.: https://... или краткий конспект",
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: 260,
                            child: TextField(
                              controller: _maxAttemptsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Макс. попыток",
                                prefixIcon: Icon(Icons.repeat_rounded),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 260,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppTheme.primaryColor
                                        .withOpacity(0.12)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.public_rounded,
                                      color: AppTheme.primaryColor),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      "Опубликовано",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Switch(
                                    value: _published,
                                    activeColor: AppTheme.accentColor,
                                    onChanged: (v) =>
                                        setState(() => _published = v),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text("Вопросы", style: theme.textTheme.headlineSmall),
              const SizedBox(height: 10),
              ...List.generate(_questions.length, (index) {
                final q = _questions[index];
                return _QuestionCard(
                  index: index,
                  question: q,
                  onRemove: () => _removeQuestion(index),
                  onChanged: () => setState(() {}),
                );
              }),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add_rounded),
                label: const Text("Добавить вопрос"),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_rounded),
                label: Text(_submitting ? "Сохраняем…" : "Сохранить"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineLoading extends StatelessWidget {
  final String text;
  const _InlineLoading({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
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
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

class _QuestionForm {
  String type; // select/checkbox/text
  final promptCtrl = TextEditingController();
  final pointsCtrl = TextEditingController(text: "1");
  bool required = true;

  // options для select/checkbox
  final optionsCtrl = TextEditingController(); // "a; b; c"
  final correctCtrl =
      TextEditingController(); // select/text: value, checkbox: JSON list

  _QuestionForm({required this.type});

  String? validate() {
    final prompt = promptCtrl.text.trim();
    if (prompt.isEmpty) return "Введите текст вопроса (prompt)";

    final points = int.tryParse(pointsCtrl.text.trim());
    if (points == null || points < 1) return "points должен быть числом >= 1";

    if (type == "select" || type == "checkbox") {
      final raw = optionsCtrl.text.trim();
      final opts = raw
          .split(';')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (opts.length < 2) return "options: минимум 2 варианта (через ; )";
      final correct = correctCtrl.text.trim();
      if (correct.isEmpty) return "Укажите correct_answer";
      if (type == "select" && !opts.contains(correct)) {
        return "correct_answer должен совпадать с одним из вариантов";
      }
      if (type == "checkbox") {
        // ожидаем JSON: ["a","b"]
        try {
          final decoded = json.decode(correct);
          if (decoded is! List)
            return "checkbox correct_answer должен быть JSON-массивом";
          for (final v in decoded) {
            if (!opts.contains(v.toString()))
              return "correct_answer содержит значения не из options";
          }
        } catch (_) {
          return "checkbox correct_answer: укажите JSON-массив, напр. [\"A\",\"B\"]";
        }
      }
    }

    if (type == "text") {
      if (correctCtrl.text.trim().isEmpty)
        return "Укажите correct_answer (для text)";
    }

    return null;
  }

  Map<String, dynamic> toPayload() {
    final points = int.parse(pointsCtrl.text.trim());

    List<String>? opts;
    if (type == "select" || type == "checkbox") {
      opts = optionsCtrl.text
          .trim()
          .split(';')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    dynamic correct;
    final rawCorrect = correctCtrl.text.trim();
    if (rawCorrect.isNotEmpty) {
      if (type == "checkbox") {
        correct = json.decode(rawCorrect);
      } else {
        correct = rawCorrect;
      }
    }

    return {
      "type": type,
      "prompt": promptCtrl.text.trim(),
      "options": opts,
      "required": required,
      "points": points,
      "correct_answer": correct,
    };
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final _QuestionForm question;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isOptions = question.type == "select" || question.type == "checkbox";

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("Вопрос ${index + 1}",
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: Colors.redAccent,
                  tooltip: "Удалить вопрос",
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              value: question.type,
              items: const [
                DropdownMenuItem(
                    value: "select", child: Text("Один вариант (select)")),
                DropdownMenuItem(
                    value: "checkbox",
                    child: Text("Несколько вариантов (checkbox)")),
                DropdownMenuItem(
                    value: "text", child: Text("Текстовый ответ (text)")),
              ],
              onChanged: (v) {
                question.type = v ?? "select";
                onChanged();
              },
              decoration: const InputDecoration(
                labelText: "Тип",
                prefixIcon: Icon(Icons.tune_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: question.promptCtrl,
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                labelText: "Текст вопроса (prompt)",
                prefixIcon: Icon(Icons.help_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: question.pointsCtrl,
                    onChanged: (_) => onChanged(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Баллы (points)",
                      prefixIcon: Icon(Icons.star_border_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Обязательный"),
                    value: question.required,
                    activeColor: AppTheme.accentColor,
                    onChanged: (v) {
                      question.required = v;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            if (isOptions) ...[
              const SizedBox(height: 12),
              TextField(
                controller: question.optionsCtrl,
                onChanged: (_) => onChanged(),
                decoration: const InputDecoration(
                  labelText: "Варианты (options) через ;",
                  prefixIcon: Icon(Icons.list_alt_rounded),
                  hintText: "Напр.: 1; 2; 3",
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: question.correctCtrl,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                labelText: "Правильный ответ (correct_answer)",
                prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                hintText: question.type == "checkbox"
                    ? 'JSON массив, напр. ["A","B"]'
                    : "Текст/вариант",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
