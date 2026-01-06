import 'package:flutter/material.dart';
import 'package:school_test_app/features/common/models/assignment.dart';
import 'package:school_test_app/features/teacher/practice/teacher_assignments_service.dart';
import 'package:school_test_app/features/teacher/practice/teacher_submissions_screen.dart';
import 'package:school_test_app/theme/app_theme.dart';

class TeacherPracticeScreen extends StatefulWidget {
  const TeacherPracticeScreen({super.key});

  @override
  State<TeacherPracticeScreen> createState() => _TeacherPracticeScreenState();
}

class _TeacherPracticeScreenState extends State<TeacherPracticeScreen> {
  final TeacherAssignmentsService _service = TeacherAssignmentsService();
  final TextEditingController _classIdController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _topicIdController = TextEditingController();
  String _assignmentType = 'practice';
  Future<List<Assignment>>? _assignmentsFuture;

  @override
  void dispose() {
    _classIdController.dispose();
    _subjectController.dispose();
    _topicIdController.dispose();
    super.dispose();
  }

  void _loadAssignments() {
    setState(() {
      _assignmentsFuture = _service.fetchAssignments(
        classId: int.tryParse(_classIdController.text.trim()),
        subject: _subjectController.text.trim().isEmpty
            ? null
            : _subjectController.text.trim(),
        topicId: int.tryParse(_topicIdController.text.trim()),
        type: _assignmentType,
      );
    });
  }

  Future<void> _openAssignmentForm({Assignment? existing}) async {
    final titleController =
        TextEditingController(text: existing?.title ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    final maxAttemptsController = TextEditingController(
      text: existing?.maxAttempts?.toString() ?? '1',
    );
    final classIdController = TextEditingController(
      text: existing?.classId?.toString() ?? _classIdController.text,
    );
    final topicIdController = TextEditingController(
      text: existing?.topicId?.toString() ?? _topicIdController.text,
    );
    String type = existing?.type ?? _assignmentType;
    final questions = <_QuestionDraft>[
      _QuestionDraft(),
    ];

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Новое задание' : 'Редактировать'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField('Название', titleController),
                _buildField('Описание', descriptionController, maxLines: 3),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Тип'),
                  items: const [
                    DropdownMenuItem(
                      value: 'practice',
                      child: Text('Практика'),
                    ),
                    DropdownMenuItem(value: 'homework', child: Text('ДЗ')),
                  ],
                  onChanged: (value) => type = value ?? 'practice',
                ),
                _buildField('Max attempts', maxAttemptsController),
                _buildField('ID класса', classIdController),
                _buildField('ID темы', topicIdController),
                const SizedBox(height: 12),
                _QuestionEditor(
                  questions: questions,
                  onChanged: () => setDialogState(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'type': type,
                  'max_attempts': maxAttemptsController.text.trim(),
                  'class_id': classIdController.text.trim(),
                  'topic_id': topicIdController.text.trim(),
                  'questions': questions,
                });
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    descriptionController.dispose();
    maxAttemptsController.dispose();
    classIdController.dispose();
    topicIdController.dispose();
    for (final question in questions) {
      question.dispose();
    }

    if (payload == null) {
      return;
    }

    final classId = int.tryParse(payload['class_id'] as String? ?? '');
    final topicId = int.tryParse(payload['topic_id'] as String? ?? '');
    final maxAttempts =
        int.tryParse(payload['max_attempts'] as String? ?? '');

    if (classId == null || topicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите корректные ID класса и темы.')),
      );
      return;
    }

    final questions = _mapQuestions(payload['questions'] as List<_QuestionDraft>);

    final data = {
      'title': payload['title'],
      'description': (payload['description'] as String).isEmpty
          ? null
          : payload['description'],
      'type': payload['type'],
      'class_id': classId,
      'topic_id': topicId,
      'max_attempts': maxAttempts,
      if (questions.isNotEmpty) 'questions': questions,
    };

    try {
      if (existing == null) {
        await _service.createAssignment(data);
      } else {
        await _service.updateAssignment(existing.id, data);
      }
      _loadAssignments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  }

  Future<void> _deleteAssignment(Assignment assignment) async {
    try {
      await _service.deleteAssignment(assignment.id);
      _loadAssignments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось удалить: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            'ID класса',
                            _classIdController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField('ID темы', _topicIdController),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildField('Предмет', _subjectController),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _assignmentType,
                      decoration: const InputDecoration(labelText: 'Тип'),
                      items: const [
                        DropdownMenuItem(
                          value: 'practice',
                          child: Text('Практика'),
                        ),
                        DropdownMenuItem(
                          value: 'homework',
                          child: Text('ДЗ'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _assignmentType = value ?? 'practice'),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _loadAssignments,
                        icon: const Icon(Icons.search),
                        label: const Text('Загрузить'),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _assignmentsFuture == null
                  ? const Center(
                      child: Text('Укажите фильтры и загрузите задания.'),
                    )
                  : FutureBuilder<List<Assignment>>(
                      future: _assignmentsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Ошибка: ${snapshot.error}'),
                          );
                        }
                        final items = snapshot.data ?? [];
                        if (items.isEmpty) {
                          return const Center(
                            child: Text('Задания не найдены.'),
                          );
                        }
                        return ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                ),
                              ),
                              child: ListTile(
                                title: Text(item.title),
                                subtitle: Text(
                                  'Тип: ${item.type} · попытки: ${item.maxAttempts ?? '-'}',
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TeacherSubmissionsScreen(
                                        assignmentId: item.id,
                                        assignmentTitle: item.title,
                                      ),
                                    ),
                                  );
                                },
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _openAssignmentForm(existing: item);
                                    }
                                    if (value == 'delete') {
                                      _deleteAssignment(item);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Редактировать'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Удалить'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAssignmentForm(),
        icon: const Icon(Icons.add),
        label: const Text('Новое задание'),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
}

List<Map<String, dynamic>> _mapQuestions(List<_QuestionDraft> drafts) {
  return drafts
      .where((draft) => draft.promptController.text.trim().isNotEmpty)
      .map((draft) {
        final prompt = draft.promptController.text.trim();
        final rawOptions = draft.optionsController.text
            .split(',')
            .map((option) => option.trim())
            .where((option) => option.isNotEmpty)
            .toList();
        final rawAnswer = draft.answerController.text.trim();

        dynamic answer;
        if (draft.type == 'checkbox') {
          answer = rawAnswer
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList();
        } else {
          answer = rawAnswer;
        }

        return {
          'type': draft.type,
          'question': prompt,
          if (rawOptions.isNotEmpty) 'options': rawOptions,
          if (rawAnswer.isNotEmpty) 'answer': answer,
        };
      })
      .toList();
}

class _QuestionDraft {
  _QuestionDraft({
    this.type = 'text',
  });

  String type;
  final TextEditingController promptController = TextEditingController();
  final TextEditingController optionsController = TextEditingController();
  final TextEditingController answerController = TextEditingController();

  void dispose() {
    promptController.dispose();
    optionsController.dispose();
    answerController.dispose();
  }
}

class _QuestionEditor extends StatelessWidget {
  const _QuestionEditor({
    required this.questions,
    required this.onChanged,
  });

  final List<_QuestionDraft> questions;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Вопросы',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              onPressed: () {
                questions.add(_QuestionDraft());
                onChanged();
              },
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < questions.length; index++)
          _QuestionCard(
            index: index,
            draft: questions[index],
            onRemove: () {
              questions[index].dispose();
              questions.removeAt(index);
              onChanged();
            },
            onChanged: onChanged,
          ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.draft,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final _QuestionDraft draft;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Вопрос ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                )
              ],
            ),
            TextField(
              controller: draft.promptController,
              decoration: const InputDecoration(labelText: 'Текст вопроса'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: draft.type,
              decoration: const InputDecoration(labelText: 'Тип'),
              items: const [
                DropdownMenuItem(value: 'text', child: Text('Текст')),
                DropdownMenuItem(value: 'select', child: Text('Выбор')),
                DropdownMenuItem(value: 'checkbox', child: Text('Чекбоксы')),
              ],
              onChanged: (value) {
                if (value != null) {
                  draft.type = value;
                  onChanged();
                }
              },
            ),
            const SizedBox(height: 8),
            if (draft.type != 'text')
              TextField(
                controller: draft.optionsController,
                decoration: const InputDecoration(
                  labelText: 'Варианты (через запятую)',
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: draft.answerController,
              decoration: const InputDecoration(
                labelText: 'Правильный ответ',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
