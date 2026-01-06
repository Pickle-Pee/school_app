import 'package:flutter/material.dart';
import 'package:school_test_app/features/common/models/submission.dart';
import 'package:school_test_app/features/teacher/practice/teacher_submissions_service.dart';
import 'package:school_test_app/theme/app_theme.dart';

class TeacherSubmissionsScreen extends StatefulWidget {
  const TeacherSubmissionsScreen({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
  });

  final int assignmentId;
  final String assignmentTitle;

  @override
  State<TeacherSubmissionsScreen> createState() =>
      _TeacherSubmissionsScreenState();
}

class _TeacherSubmissionsScreenState extends State<TeacherSubmissionsScreen> {
  final TeacherSubmissionsService _service = TeacherSubmissionsService();
  final TextEditingController _pageController = TextEditingController(text: '1');
  final TextEditingController _pageSizeController =
      TextEditingController(text: '20');
  Future<List<Submission>>? _submissionsFuture;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageSizeController.dispose();
    super.dispose();
  }

  void _loadSubmissions() {
    final page = int.tryParse(_pageController.text.trim()) ?? 1;
    final pageSize = int.tryParse(_pageSizeController.text.trim()) ?? 20;

    setState(() {
      _submissionsFuture = _service.fetchSubmissions(
        assignmentId: widget.assignmentId,
        page: page,
        pageSize: pageSize,
      );
    });
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
                child: Row(
                  children: [
                    Expanded(
                      child: _buildField('Страница', _pageController),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField('Размер', _pageSizeController),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _loadSubmissions,
                      child: const Text('Обновить'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Submission>>(
                future: _submissionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Ошибка: ${snapshot.error}'),
                    );
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const Center(
                      child: Text('Сабмишены не найдены.'),
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
                          title: Text(
                            item.studentName ??
                                'Ученик ${item.studentId ?? '-'}',
                          ),
                          subtitle: Text(
                            'Статус: ${item.status ?? '-'} · Балл: ${item.score ?? '-'}',
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
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
    );
  }
}
