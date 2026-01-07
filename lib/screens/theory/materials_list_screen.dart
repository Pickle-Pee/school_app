import 'package:flutter/material.dart';
import 'package:school_test_app/screens/theory/pdf_view_screen.dart';
import 'package:school_test_app/screens/theory/upload_materials_screen.dart';
import 'package:school_test_app/services/materials_service.dart';
import 'package:school_test_app/services/auth_service.dart';
import 'package:school_test_app/config.dart';
import 'package:school_test_app/theme/app_theme.dart';

class MaterialsListScreen extends StatefulWidget {
  const MaterialsListScreen({Key? key}) : super(key: key);

  @override
  State<MaterialsListScreen> createState() => _MaterialsListScreenState();
}

class _MaterialsListScreenState extends State<MaterialsListScreen> {
  late final MaterialsService _materialsService;
  late Future<List<Map<String, dynamic>>> _futureMaterials;

  bool _isTeacher = false; // по умолчанию считаем, что пользователь не учитель

  @override
  void initState() {
    super.initState();
    _materialsService = MaterialsService(Config.baseUrl);

    // Загружаем роль пользователя
    _checkUserType();

    _loadMaterials();
  }

  Future<void> _checkUserType() async {
    // Метод, который определит "teacher" или "student"
    // (например, через /me либо декодируя токен)
    final role = await AuthService.getUserType();
    setState(() {
      _isTeacher = (role == 'teacher');
    });
  }

  void _loadMaterials() {
    setState(() {
      _futureMaterials = _materialsService.listMaterials();
    });
  }

  Future<void> _openUploadFlow() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadMaterialScreen()),
    );
    if (updated == true) {
      _loadMaterials();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _futureMaterials,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Ошибка: ${snapshot.error}"));
                      }
                      final materials = snapshot.data ?? [];
                      if (materials.isEmpty) {
                        return _EmptyState(
                          isTeacher: _isTeacher,
                          onAdd: () => _openUploadFlow(),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                        itemCount: materials.length,
                        itemBuilder: (context, index) {
                          final mat = materials[index];
                          final id = mat["id"] as int;
                          return _MaterialCard(
                            title: mat["title"] ?? "Без названия",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PdfViewScreen(materialId: id),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _isTeacher
          ? FloatingActionButton.extended(
              onPressed: _openUploadFlow,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Добавить материал'),
            )
          : null,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: Icon(Icons.menu_book_rounded, color: Colors.white),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Теория и материалы',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Собраны конспекты, методички и файлы для уроков и занятий.',
            style: TextStyle(color: Colors.white70),
          )
        ],
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _MaterialCard({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded,
                color: AppTheme.primaryColor),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: const Text(
            'PDF · Теория',
            style: TextStyle(color: Colors.black54),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black38),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isTeacher;
  final VoidCallback onAdd;

  const _EmptyState({required this.isTeacher, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_books_outlined,
                color: AppTheme.primaryColor, size: 64),
            const SizedBox(height: 12),
            Text(
              isTeacher
                  ? 'Добавьте материалы для уроков.'
                  : 'Материалы пока не добавлены.',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isTeacher
                  ? 'Загрузите конспекты или методички, чтобы ученики могли изучать темы.'
                  : 'Попросите преподавателя поделиться материалами по теме.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            if (isTeacher)
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Загрузить материал'),
              ),
          ],
        ),
      ),
    );
  }
}
