import 'package:flutter/material.dart';
import 'package:school_test_app/features/student/subject/student_subject_service.dart';
import 'package:school_test_app/theme/app_theme.dart';

class StudentAssignmentDetailScreen extends StatefulWidget {
  const StudentAssignmentDetailScreen({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
  });

  final int assignmentId;
  final String assignmentTitle;

  @override
  State<StudentAssignmentDetailScreen> createState() =>
      _StudentAssignmentDetailScreenState();
}

class _StudentAssignmentDetailScreenState
    extends State<StudentAssignmentDetailScreen> {
  final StudentSubjectService _service = StudentSubjectService();
  Future<Map<String, dynamic>>? _detailFuture;
  List<_QuestionItem> _questions = [];
  final Map<int, dynamic> _answers = {};
  Map<String, dynamic> _detail = {};

  @override
  void initState() {
    super.initState();
    _detailFuture = _service.fetchAssignmentDetail(widget.assignmentId);
    _detailFuture?.then((detail) {
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail;
        _questions = _buildQuestions(detail['questions']);
      });
    });
  }

  @override
  void dispose() {
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final answersPayload = _questions.asMap().entries.map((entry) {
      final index = entry.key;
      final question = entry.value;
      return {
        'question': question.prompt,
        'answer': _answers[index],
      };
    }).toList();

    try {
      await _service.submitAssignment(
        id: widget.assignmentId,
        answers: answersPayload,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ответы отправлены.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.assignmentTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: _detailFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Ошибка: ${snapshot.error}');
                }
                final detail = snapshot.data ?? _detail;
                return Card(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail['title']?.toString() ?? widget.assignmentTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(detail['description']?.toString() ?? ''),
                        if (detail['questions'] != null) ...[
                          const SizedBox(height: 12),
                          _QuestionList(
                            questions: _questions,
                            onAnswerChanged: (index, value) {
                              setState(() => _answers[index] = value);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Отправить'),
            ),
          ],
        ),
      ),
    );
  }
}

List<_QuestionItem> _buildQuestions(dynamic raw) {
  if (raw is! List) {
    return [];
  }
  return raw.map((item) {
    if (item is Map<String, dynamic>) {
      final type = item['type']?.toString() ?? 'text';
      final prompt = item['question']?.toString() ??
          item['title']?.toString() ??
          'Вопрос';
      final options = item['options'] is List
          ? List<String>.from(item['options'].map((e) => e.toString()))
          : <String>[];
      return _QuestionItem(type: type, prompt: prompt, options: options);
    }
    return _QuestionItem(type: 'text', prompt: item.toString());
  }).toList();
}

class _QuestionItem {
  _QuestionItem({
    required this.type,
    required this.prompt,
    this.options = const [],
  }) : textController = TextEditingController();

  final String type;
  final String prompt;
  final List<String> options;
  final TextEditingController textController;
  final Set<String> checkboxSelection = {};

  void dispose() {
    textController.dispose();
  }
}

class _QuestionList extends StatelessWidget {
  const _QuestionList({
    required this.questions,
    required this.onAnswerChanged,
  });

  final List<_QuestionItem> questions;
  final void Function(int index, dynamic value) onAnswerChanged;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Text('Вопросов нет.');
    }
    return Column(
      children: [
        for (var index = 0; index < questions.length; index++)
          _QuestionField(
            index: index,
            question: questions[index],
            onAnswerChanged: onAnswerChanged,
          ),
      ],
    );
  }
}

class _QuestionField extends StatelessWidget {
  const _QuestionField({
    required this.index,
    required this.question,
    required this.onAnswerChanged,
  });

  final int index;
  final _QuestionItem question;
  final void Function(int index, dynamic value) onAnswerChanged;

  @override
  Widget build(BuildContext context) {
    final type = question.type;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.prompt, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (type == 'text')
            TextField(
              controller: question.textController,
              decoration: const InputDecoration(labelText: 'Ответ'),
              onChanged: (value) => onAnswerChanged(index, value),
            )
          else if (type == 'select')
            DropdownButtonFormField<String>(
              items: question.options
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    ),
                  )
                  .toList(),
              onChanged: (value) => onAnswerChanged(index, value),
              decoration: const InputDecoration(labelText: 'Выберите ответ'),
            )
          else
            Column(
              children: question.options
                  .map(
                    (option) => CheckboxListTile(
                      value: question.checkboxSelection.contains(option),
                      onChanged: (value) {
                        if (value == true) {
                          question.checkboxSelection.add(option);
                        } else {
                          question.checkboxSelection.remove(option);
                        }
                        onAnswerChanged(
                          index,
                          question.checkboxSelection.toList(),
                        );
                      },
                      title: Text(option),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
