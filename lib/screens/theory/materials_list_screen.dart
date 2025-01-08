import 'package:flutter/material.dart';
import 'package:school_test_app/screens/theory/pdf_view_screen.dart';
import 'package:school_test_app/screens/theory/upload_materials_screen.dart';
import 'package:school_test_app/services/materials_service.dart';
import 'package:school_test_app/services/auth_service.dart';
import 'package:school_test_app/config.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Список материалов"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
            return const Center(child: Text("Нет материалов"));
          }
          return ListView.builder(
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final mat = materials[index];
              return ListTile(
                title: Text(mat["title"] ?? "Без названия"),
                onTap: () {
                  final id = mat["id"] as int;
                  // Открываем PdfViewScreen
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
      // Если _isTeacher == true, показываем FAB. Иначе - null
      floatingActionButton: _isTeacher
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const UploadMaterialScreen()),
                );
                if (updated == true) {
                  _loadMaterials();
                }
              },
            )
          : null,
    );
  }
}
