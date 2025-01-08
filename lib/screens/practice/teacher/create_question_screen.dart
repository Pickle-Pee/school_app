import 'package:flutter/material.dart';
import 'package:school_test_app/config.dart';
import 'package:school_test_app/models/question_model.dart';
import 'package:school_test_app/services/test_service.dart';

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
      appBar: AppBar(
        title: Text(isEdit ? 'Редактирование вопроса' : 'Создание вопроса'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildQuestionTypeField(),
              const SizedBox(height: 16),
              _buildQuestionTextField(),
              const SizedBox(height: 16),

              // Если тип вопроса — не text_input, показываем поля для вариантов и правильных ответов
              if (_questionType != 'text_input') ...[
                const Text('Варианты ответов (через запятую):'),
                _buildOptionsField(),
                const SizedBox(height: 16),
                const Text('Правильные ответы (через запятую):'),
                _buildCorrectAnswersField(),
              ] else ...[
                // Если text_input — поле для ожидаемого ответа (необязательно)
                const Text('Ожидаемый ответ (необязательно):'),
                _buildTextAnswerField(),
              ],

              const SizedBox(height: 32),
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
      decoration: const InputDecoration(labelText: 'Тип вопроса'),
    );
  }

  /// Поле для текста вопроса
  Widget _buildQuestionTextField() {
    return TextFormField(
      initialValue: _questionText,
      decoration: const InputDecoration(labelText: 'Текст вопроса'),
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
