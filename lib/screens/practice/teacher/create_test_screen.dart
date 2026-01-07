import 'package:flutter/material.dart';
import 'package:school_test_app/models/test_model.dart';
import 'package:school_test_app/services/test_service.dart';
import 'package:school_test_app/config.dart';
import 'package:school_test_app/theme/app_theme.dart';
import 'package:school_test_app/utils/subject_suggestions.dart';

class CreateTestScreen extends StatefulWidget {
  final TestModel? existingTest;

  const CreateTestScreen({Key? key, this.existingTest}) : super(key: key);

  @override
  _CreateTestScreenState createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TestsService _testsService;

  String _title = '';
  String _description = '';

  int? _classId;
  String? _subject;
  int? _topicId;
  String _type = 'practice';
  int _maxAttempts = 1;
  bool _published = true;

  // Пример статических списков
  final List<String> _subjects = subjectSuggestions;

  @override
  void initState() {
    super.initState();
    _testsService = TestsService(Config.baseUrl);

    if (widget.existingTest != null) {
      _title = widget.existingTest!.title;
      _description = widget.existingTest!.description ?? '';
      _classId = widget.existingTest!.classId;
      _subject = widget.existingTest!.subject;
      _topicId = widget.existingTest!.topicId;
      _type = widget.existingTest!.type ?? 'practice';
      _maxAttempts = widget.existingTest!.maxAttempts ?? 1;
      _published = widget.existingTest!.published ?? true;
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      if (widget.existingTest == null) {
        // Создаём
        await _testsService.createAssignment(
          classId: _classId ?? 0,
          subject: _subject ?? '',
          topicId: _topicId ?? 0,
          type: _type,
          title: _title,
          description: _description,
          maxAttempts: _maxAttempts,
          published: _published,
          questions: const [],
        );
      } else {
        // Редактируем (PATCH /teacher/assignments/{id})
        await _testsService.updateAssignment(
          widget.existingTest!.id,
          classId: _classId ?? 0,
          subject: _subject ?? '',
          topicId: _topicId ?? 0,
          type: _type,
          title: _title,
          description: _description,
          maxAttempts: _maxAttempts,
          published: _published,
          questions: widget.existingTest!.questions,
        );
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingTest != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isEdit ? Icons.edit_note_rounded : Icons.add_task,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Редактирование работы' : 'Создание работы',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Опишите задания, класс и предмет, чтобы ученики быстрее нашли работу.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          _FormSection(
                            title: 'Основное',
                            children: [
                              TextFormField(
                                initialValue: _title,
                                decoration: const InputDecoration(
                                  labelText: 'Название работы',
                                  prefixIcon: Icon(Icons.title_rounded),
                                ),
                                validator: (value) => (value == null || value.isEmpty)
                                    ? 'Введите название'
                                    : null,
                                onSaved: (value) => _title = value ?? '',
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                initialValue: _description,
                                decoration: const InputDecoration(
                                  labelText: 'Описание',
                                  prefixIcon: Icon(Icons.notes_rounded),
                                ),
                                onSaved: (value) => _description = value ?? '',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _FormSection(
                            title: 'Параметры',
                            children: [
                              TextFormField(
                                initialValue:
                                    _classId != null ? _classId.toString() : '',
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'ID класса',
                                  prefixIcon: Icon(Icons.school_outlined),
                                ),
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                        ? 'Введите ID класса'
                                        : null,
                                onSaved: (value) =>
                                    _classId = int.tryParse(value ?? ''),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _subject,
                                decoration: const InputDecoration(
                                  labelText: 'Предмет',
                                  prefixIcon: Icon(Icons.code_rounded),
                                ),
                                items: _subjects.map((subj) {
                                  return DropdownMenuItem<String>(
                                    value: subj,
                                    child: Text(subj),
                                  );
                                }).toList(),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'Выберите предмет'
                                        : null,
                                onChanged: (val) {
                                  setState(() {
                                    _subject = val;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                initialValue:
                                    _topicId != null ? _topicId.toString() : '',
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'ID темы',
                                  prefixIcon: Icon(Icons.topic_outlined),
                                ),
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                        ? 'Введите ID темы'
                                        : null,
                                onSaved: (value) =>
                                    _topicId = int.tryParse(value ?? ''),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _type,
                                decoration: const InputDecoration(
                                  labelText: 'Тип работы',
                                  prefixIcon: Icon(Icons.assignment_outlined),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'practice', child: Text('Практика')),
                                  DropdownMenuItem(
                                      value: 'homework', child: Text('Домашняя')),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    _type = val ?? 'practice';
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                initialValue: _maxAttempts.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Максимум попыток',
                                  prefixIcon: Icon(Icons.repeat_rounded),
                                ),
                                validator: (value) {
                                  final parsed = int.tryParse(value ?? '');
                                  if (parsed == null || parsed <= 0) {
                                    return 'Введите число попыток';
                                  }
                                  return null;
                                },
                                onSaved: (value) => _maxAttempts =
                                    int.tryParse(value ?? '') ?? 1,
                              ),
                              SwitchListTile.adaptive(
                                value: _published,
                                title: const Text('Опубликовано'),
                                onChanged: (value) =>
                                    setState(() => _published = value),
                              ),
                              _SubjectChips(
                                subjects: _subjects,
                                onSelected: (value) {
                                  setState(() {
                                    _subject = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _onSave,
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Сохранить работу'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectChips extends StatelessWidget {
  const _SubjectChips({
    required this.subjects,
    required this.onSelected,
  });

  final List<String> subjects;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: subjects
          .map(
            (subject) => ActionChip(
              label: Text(subject),
              onPressed: () => onSelected(subject),
            ),
          )
          .toList(),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FormSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
