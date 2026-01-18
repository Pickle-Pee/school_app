import 'dart:html' as html; // web-only сейчас ок
import 'package:flutter/material.dart';
import 'package:school_test_app/services/student_api_service.dart';
import 'package:school_test_app/theme/app_theme.dart';
import 'package:school_test_app/widgets/app_navigator.dart';

class StudentMaterialDetailScreen extends StatelessWidget {
  const StudentMaterialDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final item = Map<String, dynamic>.from(args["item"] as Map);

    final kind = item["kind"]?.toString() ?? "text";
    final text = item["text"]?.toString() ?? "";
    final fileUrl = item["file_url"]?.toString();

    return Scaffold(
      appBar: appHeader("Материал", context: context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        fileUrl != null ? Icons.attach_file_rounded : Icons.notes_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        kind == "file" ? "Файл" : "Конспект",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (fileUrl != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.download_rounded, color: AppTheme.primaryColor),
                    title: const Text("Открыть файл", style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(fileUrl),
                    onTap: () {
                      final url = StudentApiService.resolveFileUrl(fileUrl);
                      html.window.open(url, "_blank");
                    },
                  ),
                ),

              if (kind == "text") ...[
                const SizedBox(height: 10),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: SingleChildScrollView(
                        child: Text(text.isEmpty ? "Пусто" : text),
                      ),
                    ),
                  ),
                )
              ] else
                const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
