import 'package:flutter/material.dart';
import 'package:school_test_app/models/test_model.dart';
import 'package:school_test_app/services/test_service.dart';
import 'package:school_test_app/config.dart';
import 'package:school_test_app/theme/app_theme.dart';

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

  int? _grade;
  String? _subject;

  // Пример статических списков
  final List<int> _grades = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
  final List<String> _subjects = [
    'Математика',
    'Физика',
    'Химия',
    'Биология',
    'История'
  ];

  @override
  void initState() {
    super.initState();
    _testsService = TestsService(Config.baseUrl);

    if (widget.existingTest != null) {
      _title = widget.existingTest!.title;
      _description = widget.existingTest!.description ?? '';
      _grade = widget.existingTest!.grade;
      _subject = widget.existingTest!.subject;
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      if (widget.existingTest == null) {
        // Создаём
        await _testsService.createTest(_title, _description, _grade, _subject);
      } else {
        // Редактируем (пропишем в сервисе updateTest или что-то такое)
        await _testsService.updateTest(
          widget.existingTest!.id,
          _title,
          _description,
          _grade,
          _subject,
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
                            isEdit ? 'Редактирование теста' : 'Создание теста',
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
                                  labelText: 'Название теста',
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
                              DropdownButtonFormField<int>(
                                value: _grade,
                                decoration: const InputDecoration(
                                  labelText: 'Класс',
                                  prefixIcon: Icon(Icons.school_outlined),
                                ),
                                items: _grades.map((g) {
                                  return DropdownMenuItem<int>(
                                    value: g,
                                    child: Text('$g класс'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _grade = val;
                                  });
                                },
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
                                onChanged: (val) {
                                  setState(() {
                                    _subject = val;
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
                              label: const Text('Сохранить тест'),
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
