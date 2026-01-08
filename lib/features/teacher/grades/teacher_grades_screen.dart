import 'package:flutter/material.dart';
import 'package:school_test_app/features/teacher/classes/models/class_group.dart';
import 'package:school_test_app/features/teacher/services/teacher_grades_service.dart';
import 'package:school_test_app/theme/app_theme.dart';

class TeacherGradesScreen extends StatefulWidget {
  const TeacherGradesScreen({
    super.key,
    required this.classGroup,
  });

  final ClassGroup classGroup;

  @override
  State<TeacherGradesScreen> createState() => _TeacherGradesScreenState();
}

class _TeacherGradesScreenState extends State<TeacherGradesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TeacherGradesService _service = TeacherGradesService();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _topicIdController = TextEditingController();
  String _assignmentType = 'practice';
  int _page = 1;
  int _pageSize = 20;
  Future<List<Map<String, dynamic>>>? _summaryFuture;
  Future<List<Map<String, dynamic>>>? _topicFuture;

  final TextEditingController _pageController =
      TextEditingController(text: '1');
  final TextEditingController _pageSizeController =
      TextEditingController(text: '20');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _topicIdController.dispose();
    _pageController.dispose();
    _pageSizeController.dispose();
    super.dispose();
  }

  void _loadSummary() {
    setState(() {
      _summaryFuture = _service.fetchGradesSummary(
        classId: widget.classGroup.id,
        subject: _subjectController.text.trim().isEmpty
            ? null
            : _subjectController.text.trim(),
      );
    });
  }

  void _loadByTopic() {
    final topicId = int.tryParse(_topicIdController.text.trim());
    if (topicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите корректный ID темы.')),
      );
      return;
    }

    setState(() {
      _topicFuture = _service.fetchGradesByTopic(
        classId: widget.classGroup.id,
        topicId: topicId,
        type: _assignmentType,
        page: _page,
        pageSize: _pageSize,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Класс ${widget.classGroup.title}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Сводка'),
            Tab(text: 'По теме'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SummaryTab(
            future: _summaryFuture,
            subjectController: _subjectController,
            onReload: _loadSummary,
          ),
          _ByTopicTab(
            pageController: _pageController,
            pageSizeController: _pageSizeController,
            future: _topicFuture,
            topicIdController: _topicIdController,
            assignmentType: _assignmentType,
            page: _page,
            pageSize: _pageSize,
            onTypeChanged: (value) => setState(() => _assignmentType = value),
            onPageChanged: (value) => setState(() => _page = value),
            onPageSizeChanged: (value) => setState(() => _pageSize = value),
            onLoad: _loadByTopic,
            onReset: (
                {required int studentId, required int assignmentId}) async {
              await _service.resetAttempts(
                studentId: studentId,
                assignmentId: assignmentId,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Попытки сброшены.')),
              );
              _loadByTopic();
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({
    required this.future,
    required this.subjectController,
    required this.onReload,
  });

  final Future<List<Map<String, dynamic>>>? future;
  final TextEditingController subjectController;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: subjectController,
            decoration: const InputDecoration(
              labelText: 'Предмет (необязательно)',
              prefixIcon: Icon(Icons.menu_book_outlined),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onReload,
            icon: const Icon(Icons.refresh),
            label: const Text('Обновить сводку'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: future == null
                ? const _EmptyState(
                    message: 'Нажмите «Обновить», чтобы получить сводку.',
                  )
                : FutureBuilder<List<Map<String, dynamic>>>(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return _EmptyState(
                          message: 'Ошибка загрузки: ${snapshot.error}',
                        );
                      }
                      final data = snapshot.data ?? [];
                      if (data.isEmpty) {
                        return const _EmptyState(
                          message: 'Пока нет данных для отображения.',
                        );
                      }
                      return ListView.separated(
                        itemCount: data.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = data[index];
                          return _GradeCard(
                            title: item['student_name']?.toString() ?? 'Ученик',
                            subtitle: 'Средний балл: '
                                '${item['average'] ?? item['avg'] ?? '-'}',
                            details: item,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ByTopicTab extends StatelessWidget {
  const _ByTopicTab({
    required this.future,
    required this.topicIdController,
    required this.assignmentType,
    required this.page,
    required this.pageSize,
    required this.onTypeChanged,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    required this.onLoad,
    required this.onReset,
    required this.pageController,
    required this.pageSizeController,
  });

  final Future<List<Map<String, dynamic>>>? future;
  final TextEditingController topicIdController;
  final String assignmentType;
  final int page;
  final int pageSize;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;
  final VoidCallback onLoad;
  final TextEditingController pageController;
  final TextEditingController pageSizeController;
  final Future<void> Function({
    required int studentId,
    required int assignmentId,
  }) onReset;

  static const types = ['practice', 'homework'];
  String get safeType => types.contains(assignmentType) ? assignmentType : 'practice';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: topicIdController,
            decoration: const InputDecoration(
              labelText: 'ID темы',
              prefixIcon: Icon(Icons.tag_outlined),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: safeType,
            items: const [
              DropdownMenuItem(value: 'practice', child: Text('Практика')),
              DropdownMenuItem(value: 'homework', child: Text('ДЗ')),
            ],
            onChanged: (value) {
              if (value != null) onTypeChanged(value);
            },
            decoration: const InputDecoration(
              labelText: 'Тип работы',
              prefixIcon: Icon(Icons.fact_check_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: pageController,
                  decoration: const InputDecoration(labelText: 'Страница'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed >= 1) {
                      onPageChanged(parsed);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: pageSizeController,
                  decoration: const InputDecoration(labelText: 'Размер'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed >= 1 && parsed <= 100) {
                      onPageSizeChanged(parsed);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onLoad,
            icon: const Icon(Icons.search),
            label: const Text('Загрузить оценки'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: future == null
                ? const _EmptyState(
                    message: 'Введите параметры и нажмите «Загрузить».',
                  )
                : FutureBuilder<List<Map<String, dynamic>>>(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return _EmptyState(
                          message: 'Ошибка загрузки: ${snapshot.error}',
                        );
                      }
                      final data = snapshot.data ?? [];
                      if (data.isEmpty) {
                        return const _EmptyState(
                          message: 'Оценок пока нет.',
                        );
                      }
                      return ListView.separated(
                        itemCount: data.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = data[index];
                          final studentId = item['student_id'];
                          final assignmentId = item['assignment_id'];
                          return _GradeCard(
                            title: item['student_name']?.toString() ?? 'Ученик',
                            subtitle: 'Оценка: ${item['grade'] ?? '-'}',
                            details: item,
                            trailing: (studentId is int && assignmentId is int)
                                ? TextButton(
                                    onPressed: () => onReset(
                                      studentId: studentId,
                                      assignmentId: assignmentId,
                                    ),
                                    child: const Text('Сбросить'),
                                  )
                                : null,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({
    required this.title,
    required this.subtitle,
    required this.details,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Map<String, dynamic> details;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle),
            const SizedBox(height: 12),
            Text(
              details.entries
                  .map((entry) => '${entry.key}: ${entry.value}')
                  .join(' · '),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Colors.black54),
      ),
    );
  }
}
