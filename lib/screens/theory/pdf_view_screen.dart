import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // для getApplicationDocumentsDirectory / getTemporaryDirectory
import 'package:flutter_pdfview/flutter_pdfview.dart'; // из flutter_pdfview
import 'package:school_test_app/services/materials_service.dart';
import 'package:school_test_app/config.dart';

class PdfViewScreen extends StatefulWidget {
  final int materialId;

  const PdfViewScreen({Key? key, required this.materialId}) : super(key: key);

  @override
  State<PdfViewScreen> createState() => _PdfViewScreenState();
}

class _PdfViewScreenState extends State<PdfViewScreen> {
  late final MaterialsService _materialsService;

  /// Путь к локальному файлу, который откроем в PDFView
  String? _localPdfPath;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _materialsService = MaterialsService(Config.baseUrl);

    _loadPdf();
  }

  /// 1) Запрашиваем байты PDF с бэкенда
  /// 2) Сохраняем во временный файл
  /// 3) Запоминаем путь в _localPdfPath
  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1) Получаем байты
      Uint8List pdfBytes =
          await _materialsService.getMaterialPdfBytes(widget.materialId);

      // 2) Сохраняем во временный файл (например, getTemporaryDirectory)
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/temp_pdf_${widget.materialId}.pdf';

      File file = File(tempPath);
      await file.writeAsBytes(pdfBytes, flush: true);

      // 3) Сохраняем путь
      setState(() {
        _localPdfPath = file.path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Ошибка: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Просмотр PDF (flutter_pdfview)"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _localPdfPath == null
                  ? const Center(child: Text("Файл не найден"))
                  : PDFView(
                      filePath: _localPdfPath!,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      onError: (error) {
                        debugPrint(error.toString());
                      },
                      onRender: (pages) {
                        debugPrint("PDF rendered with $pages pages");
                      },
                      onViewCreated: (PDFViewController pdfViewController) {
                        // Можно сохранить контроллер, если нужно
                      },
                      onPageChanged: (page, total) {
                        debugPrint('Current page: $page/$total');
                      },
                    ),
    );
  }
}
