import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:school_test_app/services/materials_service.dart';
import 'package:school_test_app/config.dart';
import 'package:school_test_app/theme/app_theme.dart';

class UploadMaterialScreen extends StatefulWidget {
  final int classId;
  final String subject;
  final int topicId;

  const UploadMaterialScreen({
    Key? key,
    required this.classId,
    required this.subject,
    required this.topicId,
  }) : super(key: key);

  @override
  State<UploadMaterialScreen> createState() => _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends State<UploadMaterialScreen> {
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
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Выберите PDF-файл")),
      );
      return;
    }

    try {
      // Вызываем наш сервис, который делает multipart POST
      await _materialsService.uploadTheoryFile(
        classId: widget.classId,
        subject: widget.subject,
        topicId: widget.topicId,
        filePath: _selectedFilePath!,
      );

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
                  children: const [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white24,
                      child:
                          Icon(Icons.upload_file_rounded, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Новый материал',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Основное',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _selectedFilePath != null
                                      ? 'Выбран файл: $_selectedFilePath'
                                      : 'Прикрепите PDF-файл для урока.',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _pickFile,
                                  icon: const Icon(Icons.attach_file),
                                  label: const Text('Выбрать PDF'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _upload,
                            icon: const Icon(Icons.cloud_upload_outlined),
                            label: const Text("Загрузить"),
                          ),
                        ),
                      ],
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
}
