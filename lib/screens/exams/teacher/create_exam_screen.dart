import 'package:flutter/material.dart';
import 'package:school_test_app/services/exam_service.dart';
import 'package:school_test_app/config.dart';

class CreateExamScreen extends StatefulWidget {
  final int? examId; // если хотим редактировать

  const CreateExamScreen({Key? key, this.examId}) : super(key: key);

  @override
  _CreateExamScreenState createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ExamsService _examsService;

  String _title = '';
  String _description = '';
  int? _grade;
  String? _subject;
  int? _timeLimit;

  final List<int> _grades = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
  final List<String> _subjects = [
    'Математика',
    'Физика',
    'Химия',
    'История'
  ];

  bool _isEdit = false; // если examId != null

  @override
  void initState() {
    super.initState();
    _examsService = ExamsService(Config.baseUrl);
    if (widget.examId != null) {
      _isEdit = true;
      // Загрузить данные экзамена с бэкенда, заполнить поля
      _loadExam(widget.examId!);
    }
  }

  Future<void> _loadExam(int examId) async {
    try {
      final exam = await _examsService.getExamById(examId);
      setState(() {
        _title = exam.title;
        _description = exam.description ?? '';
        _grade = exam.grade;
        _subject = exam.subject;
        _timeLimit = exam.timeLimitMinutes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')),
      );
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      if (_isEdit && widget.examId != null) {
        // Обновляем
        await _examsService.updateExam(
          examId: widget.examId!,
          title: _title,
          description: _description,
          grade: _grade,
          subject: _subject,
          timeLimitMinutes: _timeLimit,
        );
      } else {
        // Создаём
        await _examsService.createExam(
          title: _title,
          description: _description,
          grade: _grade,
          subject: _subject,
          timeLimitMinutes: _timeLimit,
        );
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Редактирование экзамена' : 'Создание экзамена'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: 'Название'),
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Введите название' : null,
                onSaved: (val) => _title = val ?? '',
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Описание'),
                onSaved: (val) => _description = val ?? '',
              ),
              const SizedBox(height: 16),

              // Класс
              DropdownButtonFormField<int>(
                value: _grade,
                decoration: const InputDecoration(labelText: 'Класс'),
                items: _grades.map((g) {
                  return DropdownMenuItem(
                    value: g,
                    child: Text('$g класс'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _grade = val),
              ),
              const SizedBox(height: 16),

              // Предмет
              DropdownButtonFormField<String>(
                value: _subject,
                decoration: const InputDecoration(labelText: 'Предмет'),
                items: _subjects.map((subj) {
                  return DropdownMenuItem(
                    value: subj,
                    child: Text(subj),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _subject = val),
              ),
              const SizedBox(height: 16),

              // Таймер (мин)
              TextFormField(
                initialValue: _timeLimit?.toString(),
                decoration: const InputDecoration(labelText: 'Время (мин)'),
                keyboardType: TextInputType.number,
                onSaved: (val) {
                  if (val != null && val.isNotEmpty) {
                    _timeLimit = int.tryParse(val);
                  } else {
                    _timeLimit = null;
                  }
                },
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _onSave,
                child: const Text('Сохранить'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
