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
  String _questionType = 'text_input'; // по умолчанию
  String _questionText = '';
  List<String>? _options;
  List<String>? _correctAnswers;
  String? _textAnswer;

  @override
  void initState() {
    super.initState();
    _testsService = TestsService(Config.baseUrl);

    // Если есть вопрос (редактирование), инициализируем поля
    final q = widget.question;
    if (q != null) {
      _questionType = q.questionType;
      _questionText = q.questionText;
      _options = q.options;
      _correctAnswers = q.correctAnswers;
      _textAnswer = q.textAnswer;
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      // Создаём модель вопроса
      final question = QuestionModel(
        id: widget.question?.id ??
            0, // при создании 0, сервер сам сгенерирует ID
        questionType: _questionType,
        questionText: _questionText,
        options: _options,
        correctAnswers: _correctAnswers,
        textAnswer: _textAnswer,
      );

      if (widget.question == null) {
        // создаём новый вопрос
        await _testsService.addQuestion(widget.testId, question);
      } else {
        // редактируем существующий вопрос
        await _testsService.updateQuestion(widget.testId, question);
      }

      // Возвращаемся назад и сообщаем об успешном сохранении
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
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
                              if (_questionType != 'text_input') ...[
                                const Text('Варианты ответов (через запятую):'),
                                _buildOptionsField(),
                                const SizedBox(height: 12),
                                const Text('Правильные ответы (через запятую):'),
                                _buildCorrectAnswersField(),
                              ] else ...[
                                const Text('Ожидаемый ответ (необязательно):'),
                                _buildTextAnswerField(),
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
        DropdownMenuItem(child: Text('Текстовый ввод'), value: 'text_input'),
        DropdownMenuItem(
            child: Text('Множественный выбор'), value: 'multiple_choice'),
        DropdownMenuItem(
            child: Text('Одиночный выбор'), value: 'single_choice'),
      ],
      onChanged: (value) {
        setState(() {
          _questionType = value ?? 'text_input';
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
      initialValue: _questionText,
      decoration: const InputDecoration(
        labelText: 'Текст вопроса',
        prefixIcon: Icon(Icons.text_snippet_outlined),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Введите текст вопроса' : null,
      onSaved: (value) => _questionText = value ?? '',
    );
  }

  /// Поле для списка вариантов (через запятую)
  Widget _buildOptionsField() {
    return TextFormField(
      initialValue: _options?.join(', ') ?? '',
      onSaved: (value) {
        if (value != null && value.trim().isNotEmpty) {
          _options = value.split(',').map((e) => e.trim()).toList();
        } else {
          _options = [];
        }
      },
    );
  }

  /// Поле для списка правильных ответов (через запятую)
  Widget _buildCorrectAnswersField() {
    return TextFormField(
      initialValue: _correctAnswers?.join(', ') ?? '',
      onSaved: (value) {
        if (value != null && value.trim().isNotEmpty) {
          _correctAnswers = value.split(',').map((e) => e.trim()).toList();
        } else {
          _correctAnswers = [];
        }
      },
    );
  }

  /// Поле для «ожидаемого ответа» (для text_input)
  Widget _buildTextAnswerField() {
    return TextFormField(
      initialValue: _textAnswer,
      onSaved: (value) {
        _textAnswer = value;
      },
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
