import 'package:flutter/material.dart';
import 'package:school_test_app/services/teacher_api_service.dart';
import 'package:school_test_app/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:school_test_app/widgets/app_navigator.dart';

class TeacherAddMaterialScreen extends StatefulWidget {
  const TeacherAddMaterialScreen({Key? key}) : super(key: key);

  @override
  State<TeacherAddMaterialScreen> createState() =>
      _TeacherAddMaterialScreenState();
}

class _TeacherAddMaterialScreenState extends State<TeacherAddMaterialScreen> {
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _classGroup;
  String? _subject;

  List<Map<String, dynamic>> _topics = [];
  int? _selectedTopicId;

  bool _isFile = false;
  final TextEditingController _textController = TextEditingController();

  PlatformFile? _pickedFile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map) {
      setState(() => _error = "Не переданы аргументы экрана");
      return;
    }

    if (_classGroup == null) {
      _classGroup = Map<String, dynamic>.from(args["class"] as Map);
      _subject = args["subject"] as String?;

      if (_subject == null || _subject!.isEmpty) {
        setState(() => _error = "Не передан предмет");
        return;
      }

      _init();
    }
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final classId = (_classGroup!["id"] as num).toInt();
      final topicsRaw = await TeacherApiService.getTopics(
        classId: classId,
        subject: _subject!,
      );

      final topics =
          topicsRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      setState(() {
        _topics = topics;
        _selectedTopicId =
            topics.isNotEmpty ? (topics.first["id"] as num).toInt() : null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_classGroup == null || _subject == null || _selectedTopicId == null) {
      setState(() => _error = "Не выбраны все параметры");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final classId = (_classGroup!["id"] as num).toInt();
      final topicId = _selectedTopicId!;

      if (_isFile) {
        if (_pickedFile == null) {
          throw Exception("Выберите файл для загрузки");
        }
        await TeacherApiService.createTheoryFile(
          classId: classId,
          subject: _subject!,
          topicId: topicId,
          file: _pickedFile!,
        );
      } else {
        final text = _textController.text.trim();
        if (text.isEmpty) throw Exception("Введите текст материала");
        await TeacherApiService.createTheoryText(
          classId: classId,
          subject: _subject!,
          topicId: topicId,
          text: text,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Материал добавлен")),
      );
      Navigator.pop(context, true);
    } catch (e, st) {
      setState(() => _error = "$e\n$st");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: appHeader("Добавить материал", context: context),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.add_to_photos_rounded,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isFile ? 'Загрузка файла' : 'Текстовый конспект',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_loading)
                const _InlineLoading()
              else if (_error != null)
                _InlineError(text: _error!)
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Параметры', style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: _selectedTopicId,
                          items: _topics.map((t) {
                            final id = (t["id"] as num).toInt();
                            final title = t["title"]?.toString() ?? "Тема";
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(title),
                            );
                          }).toList(),
                          onChanged: (id) =>
                              setState(() => _selectedTopicId = id),
                          decoration: const InputDecoration(
                            labelText: 'Тема',
                            prefixIcon: Icon(Icons.topic_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_isFile ? 'Файл' : 'Текст',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Switch(
                              value: _isFile,
                              activeColor: AppTheme.accentColor,
                              onChanged: (v) => setState(() => _isFile = v),
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (!_isFile)
                          TextField(
                            controller: _textController,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              labelText: 'Текст материала',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.notes_rounded),
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.10),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.attach_file_rounded,
                                    color: AppTheme.primaryColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _pickedFile?.name ?? 'Файл не выбран',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final res =
                                        await FilePicker.platform.pickFiles(
                                      withData: true,
                                    );
                                    if (res == null || res.files.isEmpty)
                                      return;
                                    setState(
                                        () => _pickedFile = res.files.first);
                                  },
                                  child: const Text('Выбрать'),
                                )
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _submit,
                          icon: const Icon(Icons.cloud_upload_rounded),
                          label: const Text('Сохранить'),
                        ),
                      ],
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

class _InlineLoading extends StatelessWidget {
  const _InlineLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: const [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Expanded(child: Text('Загрузка…')),
        ],
      ),
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
