import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:school_test_app/services/materials_service.dart';
import 'package:school_test_app/config.dart';

class UploadMaterialScreen extends StatefulWidget {
  const UploadMaterialScreen({Key? key}) : super(key: key);

  @override
  State<UploadMaterialScreen> createState() => _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends State<UploadMaterialScreen> {
  final TextEditingController _titleController = TextEditingController();
  String? _selectedFilePath;

  late final MaterialsService _materialsService;

  @override
  void initState() {
    super.initState();
    _materialsService = MaterialsService(Config.baseUrl);
  }

  /// Открываем диалог выбора файла (file_picker)
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFilePath = result.files.single.path;
      });
    }
  }

  /// Отправляем файл на сервер
  Future<void> _upload() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Введите название материала")),
      );
      return;
    }
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Выберите PDF-файл")),
      );
      return;
    }

    try {
      // Вызываем наш сервис, который делает multipart POST
      await _materialsService.uploadMaterial(title, _selectedFilePath!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Файл успешно загружен")),
      );
      // Возвращаемся на предыдущий экран
      Navigator.pop(context, true); // сигнализируем, что что-то изменилось
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Загрузить материал (PDF)"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration:
                  const InputDecoration(labelText: "Название материала"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text("Выбрать PDF"),
            ),
            if (_selectedFilePath != null)
              Text("Выбран файл: $_selectedFilePath"),
            const Spacer(),
            ElevatedButton(
              onPressed: _upload,
              child: const Text("Загрузить"),
            ),
          ],
        ),
      ),
    );
  }
}
