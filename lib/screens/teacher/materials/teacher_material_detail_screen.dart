import 'dart:html' as html; // Web only (пока ок, ты тестишь на web)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_test_app/theme/app_theme.dart';
import 'package:school_test_app/services/teacher_api_service.dart';
import 'package:school_test_app/widgets/app_navigator.dart';

class TeacherMaterialDetailScreen extends StatelessWidget {
  const TeacherMaterialDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final item = Map<String, dynamic>.from(args["item"] as Map);

    final topicTitle = item["topic_title"]?.toString() ?? "Материал";
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
                        fileUrl != null
                            ? Icons.attach_file_rounded
                            : Icons.notes_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        topicTitle,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (fileUrl != null)
                if (fileUrl != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Файл",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            fileUrl,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    final url =
                                        TeacherApiService.resolveFileUrl(
                                            fileUrl);
                                    html.window.open(url, "_blank");
                                  },
                                  icon: const Icon(Icons.open_in_new_rounded),
                                  label: const Text("Открыть"),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final url =
                                      TeacherApiService.resolveFileUrl(fileUrl);
                                  await Clipboard.setData(
                                      ClipboardData(text: url));
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Ссылка скопирована")),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded),
                                label: const Text("Скопировать"),
                              ),
                            ],
                          ),
                        ],
                      ),
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
