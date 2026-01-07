import 'package:flutter/material.dart';
import 'package:school_test_app/config.dart';
import 'package:school_test_app/models/question_model.dart';
import 'package:school_test_app/services/test_service.dart';
import 'package:school_test_app/theme/app_theme.dart';

class CreateQuestionScreen extends StatefulWidget {
  final int testId;
  final QuestionModel? question; // Если не null — значит, редактируем

  const CreateQuestionScreen({
    Key? key,
    required this.testId,
    this.question,
  }) : super(key: key);

  @override
  _CreateQuestionScreenState createState() => _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends State<CreateQuestionScreen> {
  // form key
  final _formKey = GlobalKey<FormState>();

  // Сервис для работы с вопросами (CRUD)
  late final TestsService _testsService;

  // Параметры вопроса
  String _questionType = 'text'; // по умолчанию
  String _prompt = '';
  List<String>? _options;
  List<String>? _correctAnswers;
  String? _correctAnswer;
  bool _isRequired = true;
  int _points = 1;

  @override
  void initState() {
    super.initState();
    _testsService = TestsService(Config.baseUrl);

    // Если есть вопрос (редактирование), инициализируем поля
    final q = widget.question;
    if (q != null) {
      _questionType = q.type;
      _prompt = q.prompt;
      _options = q.options;
      if (q.correctAnswer is List) {
        _correctAnswers = List<String>.from(q.correctAnswer as List);
      } else {
        _correctAnswer = q.correctAnswer?.toString();
      }
      _isRequired = q.required;
      _points = q.points;
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_questionType != 'text') {
      final options = _options ?? [];
      if (options.isEmpty) {
        _showValidationError('Добавьте варианты ответов.');
        return;
      }
      if (_questionType == 'select') {
        if (_correctAnswer == null || _correctAnswer!.isEmpty) {
          _showValidationError('Укажите правильный ответ.');
          return;
        }
        if (!options.contains(_correctAnswer)) {
          _showValidationError('Правильный ответ должен быть в вариантах.');
          return;
        }
      }
      if (_questionType == 'checkbox') {
        final correctAnswers = _correctAnswers ?? [];
        if (correctAnswers.isEmpty) {
          _showValidationError('Укажите правильные ответы.');
          return;
        }
        final invalid = correctAnswers.where((item) => !options.contains(item));
        if (invalid.isNotEmpty) {
          _showValidationError(
            'Правильные ответы должны быть среди вариантов.',
          );
          return;
        }
      }
    }

    try {
      // Создаём модель вопроса
      final question = QuestionModel(
        id: widget.question?.id ??
            0, // при создании 0, сервер сам сгенерирует ID
        type: _questionType,
        prompt: _prompt,
        options: _options,
        required: _isRequired,
        points: _points,
        correctAnswer:
            _questionType == 'checkbox' ? _correctAnswers : _correctAnswer,
      );

      if (widget.question == null) {
        // создаём новый вопрос
        final assignment = await _testsService.getAssignmentById(
          widget.testId,
          isTeacher: true,
        );
        await _testsService.addQuestion(
          widget.testId,
          question,
          assignment: assignment,
        );
      } else {
        // редактируем существующий вопрос
        final assignment = await _testsService.getAssignmentById(
          widget.testId,
          isTeacher: true,
        );
        await _testsService.updateQuestion(
          widget.testId,
          question,
          assignment: assignment,
        );
      }

      // Возвращаемся назад и сообщаем об успешном сохранении
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.question != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isEdit ? Icons.edit_outlined : Icons.add,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Редактирование вопроса' : 'Создание вопроса',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Добавьте текст вопроса и варианты ответов, чтобы подготовить ученикам практику.',
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
                            title: 'Тип вопроса',
                            children: [
                              _buildQuestionTypeField(),
                              const SizedBox(height: 12),
                              const Text(
                                'Выберите формат: текстовый ответ, одиночный или множественный выбор.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _FormSection(
                            title: 'Содержание',
                            children: [
                              _buildQuestionTextField(),
                              const SizedBox(height: 12),
                              _buildMetaFields(),
                              const SizedBox(height: 12),
                              if (_questionType != 'text') ...[
                                const Text('Варианты ответов (через запятую):'),
                                _buildOptionsField(),
                                const SizedBox(height: 12),
                                if (_questionType == 'checkbox') ...[
                                  const Text('Правильные ответы (через запятую):'),
                                  _buildCorrectAnswersField(),
                                ] else ...[
                                  const Text('Правильный ответ:'),
                                  _buildCorrectAnswerField(),
                                ],
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _onSave,
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Сохранить вопрос'),
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

  /// Поле выбора типа вопроса (Dropdown)
  Widget _buildQuestionTypeField() {
    return DropdownButtonFormField<String>(
      value: _questionType,
      items: const [
        DropdownMenuItem(child: Text('Текстовый ввод'), value: 'text'),
        DropdownMenuItem(child: Text('Множественный выбор'), value: 'checkbox'),
        DropdownMenuItem(child: Text('Одиночный выбор'), value: 'select'),
      ],
      onChanged: (value) {
        setState(() {
          _questionType = value ?? 'text';
        });
      },
      decoration: const InputDecoration(
        labelText: 'Тип вопроса',
        prefixIcon: Icon(Icons.tune_rounded),
      ),
    );
  }

  /// Поле для текста вопроса
  Widget _buildQuestionTextField() {
    return TextFormField(
      initialValue: _prompt,
      decoration: const InputDecoration(
        labelText: 'Текст вопроса',
        prefixIcon: Icon(Icons.text_snippet_outlined),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Введите текст вопроса' : null,
      onSaved: (value) => _prompt = value ?? '',
    );
  }

  Widget _buildMetaFields() {
    return Column(
      children: [
        TextFormField(
          initialValue: _points.toString(),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Баллы',
            prefixIcon: Icon(Icons.stars_outlined),
          ),
          validator: (value) {
            final parsed = int.tryParse(value ?? '');
            if (parsed == null || parsed <= 0) {
              return 'Введите баллы';
            }
            return null;
          },
          onSaved: (value) => _points = int.tryParse(value ?? '') ?? 1,
        ),
        SwitchListTile.adaptive(
          value: _isRequired,
          title: const Text('Обязательный'),
          contentPadding: EdgeInsets.zero,
          onChanged: (value) => setState(() => _isRequired = value),
        ),
      ],
    );
  }

  /// Поле для списка вариантов (через запятую)
  Widget _buildOptionsField() {
    return TextFormField(
      initialValue: _options?.join(', ') ?? '',
      validator: (value) {
        if (_questionType == 'text') {
          return null;
        }
        final parsed = _parseList(value);
        if (parsed.isEmpty) {
          return 'Укажите варианты ответов';
        }
        return null;
      },
      onSaved: (value) {
        _options = _parseList(value);
      },
    );
  }

  /// Поле для списка правильных ответов (через запятую)
  Widget _buildCorrectAnswersField() {
    return TextFormField(
      initialValue: _correctAnswers?.join(', ') ?? '',
      validator: (value) {
        if (_questionType == 'text') {
          return null;
        }
        final parsed = _parseList(value);
        if (parsed.isEmpty) {
          return 'Укажите правильные ответы';
        }
        return null;
      },
      onSaved: (value) {
        _correctAnswers = _parseList(value);
      },
    );
  }

  Widget _buildCorrectAnswerField() {
    return TextFormField(
      initialValue: _correctAnswer,
      onSaved: (value) {
        _correctAnswer = value?.trim();
      },
    );
  }

  List<String> _parseList(String? value) {
    if (value == null || value.trim().isEmpty) {
      return [];
    }
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
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
