import 'package:flutter/material.dart';
import 'package:school_test_app/features/common/models/theory_material.dart';
import 'package:school_test_app/features/common/models/topic.dart';
import 'package:school_test_app/features/teacher/classes/models/class_group.dart';
import 'package:school_test_app/features/teacher/services/teacher_grades_service.dart';
import 'package:school_test_app/features/teacher/services/teacher_topics_service.dart';
import 'package:school_test_app/features/teacher/theory/teacher_theory_service.dart';
import 'package:school_test_app/theme/app_theme.dart';

class TeacherTheoryScreen extends StatefulWidget {
  const TeacherTheoryScreen({super.key});

  @override
  State<TeacherTheoryScreen> createState() => _TeacherTheoryScreenState();
}

class _TeacherTheoryScreenState extends State<TeacherTheoryScreen> {
  final TeacherTheoryService _service = TeacherTheoryService();
  final TeacherTopicsService _topicsService = TeacherTopicsService();
  final TeacherGradesService _gradesService = TeacherGradesService();
  final TextEditingController _subjectController = TextEditingController();
  Future<List<TheoryMaterial>>? _theoryFuture;
  List<ClassGroup> _classes = [];
  ClassGroup? _selectedClass;
  bool _classesLoading = false;
  List<Topic> _topics = [];
  Topic? _selectedTopic;
  bool _topicsLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _classesLoading = true);
    try {
      final classes = await _gradesService.fetchClasses();
      setState(() {
        _classes = classes;
        _selectedClass = classes.isNotEmpty ? classes.first : null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить классы: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _classesLoading = false);
      }
    }
  }

  Future<void> _loadTopics() async {
    final classId = _selectedClass?.id;
    if (classId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите класс.')),
      );
      return;
    }
    final subject = _subjectController.text.trim();
    if (subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите предмет для загрузки тем.')),
      );
      return;
    }

    setState(() => _topicsLoading = true);
    try {
      final topics = await _topicsService.fetchTopics(
        classId: classId,
        subject: subject,
      );
      setState(() {
        _topics = topics;
        _selectedTopic = topics.isNotEmpty ? topics.first : null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить темы: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _topicsLoading = false);
      }
    }
  }

  void _loadTheory() {
    setState(() {
      _theoryFuture = _service.fetchTheory(
        classId: _selectedClass?.id,
        subject: _subjectController.text.trim().isEmpty
            ? null
            : _subjectController.text.trim(),
        topicId: _selectedTopic?.id,
      );
    });
  }

  Future<void> _openTheoryForm({TheoryMaterial? existing}) async {
    final titleController =
        TextEditingController(text: existing?.title ?? '');
    final contentController =
        TextEditingController(text: existing?.content ?? '');
    final fileController =
        TextEditingController(text: existing?.fileUrl ?? '');
    ClassGroup? selectedClass;
    if (_classes.isNotEmpty) {
      selectedClass = _classes.firstWhere(
        (item) => item.id == existing?.classId,
        orElse: () => _selectedClass ?? _classes.first,
      );
    }
    int? selectedTopicId = existing?.topicId ?? _selectedTopic?.id;

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title:
              Text(existing == null ? 'Новая теория' : 'Редактировать теорию'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField('Название', titleController),
                _buildField('Текст', contentController, maxLines: 4),
                _buildField('Ссылка на файл', fileController),
                DropdownButtonFormField<ClassGroup>(
                  value: selectedClass,
                  decoration: const InputDecoration(labelText: 'Класс'),
                  items: _classes
                      .map(
                        (classGroup) => DropdownMenuItem(
                          value: classGroup,
                          child: Text('Класс ${classGroup.title}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedClass = value);
                  },
                ),
                DropdownButtonFormField<int>(
                  value: selectedTopicId,
                  decoration: const InputDecoration(labelText: 'Тема'),
                  items: _topics
                      .map(
                        (topic) => DropdownMenuItem(
                          value: topic.id,
                          child: Text(topic.title),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedTopicId = value);
                  },
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
                  'content': contentController.text.trim(),
                  'file_url': fileController.text.trim(),
                  'class_id': selectedClass?.id,
                  'topic_id': selectedTopicId,
                });
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    contentController.dispose();
    fileController.dispose();
    if (payload == null) {
      return;
    }

    final classId = payload['class_id'] as int?;
    final topicId = payload['topic_id'] as int?;

    if (classId == null || topicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите класс и тему.')),
      );
      return;
    }

    final data = {
      'title': payload['title'],
      'content': (payload['content'] as String).isEmpty
          ? null
          : payload['content'],
      'file_url': (payload['file_url'] as String).isEmpty
          ? null
          : payload['file_url'],
      'class_id': classId,
      'topic_id': topicId,
    };

    try {
      if (existing == null) {
        await _service.createTheory(data);
      } else {
        await _service.updateTheory(existing.id, data);
      }
      _loadTheory();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  }

  Future<void> _deleteTheory(TheoryMaterial material) async {
    try {
      await _service.deleteTheory(material.id);
      _loadTheory();
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
                          child: DropdownButtonFormField<ClassGroup>(
                            value: _selectedClass,
                            decoration: const InputDecoration(
                              labelText: 'Класс',
                            ),
                            items: _classes
                                .map(
                                  (classGroup) => DropdownMenuItem(
                                    value: classGroup,
                                    child: Text('Класс ${classGroup.title}'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedClass = value;
                                _topics = [];
                                _selectedTopic = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<Topic>(
                            value: _selectedTopic,
                            decoration: const InputDecoration(
                              labelText: 'Тема',
                            ),
                            items: _topics
                                .map(
                                  (topic) => DropdownMenuItem(
                                    value: topic,
                                    child: Text(topic.title),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedTopic = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildField('Предмет', _subjectController),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _classesLoading ? null : _loadClasses,
                          icon: _classesLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.groups_2_outlined),
                          label: const Text('Классы'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _topicsLoading ? null : _loadTopics,
                          icon: _topicsLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: const Text('Темы'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _loadTheory,
                          icon: const Icon(Icons.search),
                          label: const Text('Загрузить'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _theoryFuture == null
                  ? const Center(
                      child: Text('Укажите фильтры и загрузите материалы.'),
                    )
                  : FutureBuilder<List<TheoryMaterial>>(
                      future: _theoryFuture,
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
                            child: Text('Материалы не найдены.'),
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
                                  item.content ??
                                      item.fileUrl ??
                                      'Без описания',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _openTheoryForm(existing: item);
                                    }
                                    if (value == 'delete') {
                                      _deleteTheory(item);
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
        onPressed: () => _openTheoryForm(),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
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
