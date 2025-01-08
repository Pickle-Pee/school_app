import 'package:flutter/material.dart';
import 'package:school_test_app/models/test_model.dart';
import 'package:school_test_app/services/test_service.dart';
import 'package:school_test_app/config.dart';

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
      appBar: AppBar(
        title: Text(isEdit ? 'Редактирование теста' : 'Создание теста'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Название
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: 'Название теста'),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Введите название'
                    : null,
                onSaved: (value) => _title = value ?? '',
              ),
              const SizedBox(height: 16),

              // Описание
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Описание'),
                onSaved: (value) => _description = value ?? '',
              ),
              const SizedBox(height: 16),

              // Выбор класса (Dropdown)
              DropdownButtonFormField<int>(
                value: _grade,
                decoration: const InputDecoration(labelText: 'Класс (grade)'),
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
              const SizedBox(height: 16),

              // Выбор предмета (Dropdown)
              DropdownButtonFormField<String>(
                value: _subject,
                decoration: const InputDecoration(labelText: 'Предмет'),
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

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _onSave,
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
