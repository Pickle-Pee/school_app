import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_test_app/theme/app_theme.dart';
import 'package:school_test_app/services/teacher_api_service.dart';
import 'package:school_test_app/widgets/app_navigator.dart';
import 'package:school_test_app/utils/web_file.dart'; // <-- новый helper

class TeacherMaterialDetailScreen extends StatelessWidget {
  const TeacherMaterialDetailScreen({Key? key}) : super(key: key);

  int? _extractTheoryId(Map<String, dynamic> item) {
    final raw = item["id"];
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final item = Map<String, dynamic>.from(args["item"] as Map);

    final topicTitle = item["topic_title"]?.toString() ?? "Материал";
    final kind = item["kind"]?.toString() ?? "text";
    final text = item["text"]?.toString() ?? "";
    final fileUrl = item["file_url"]?.toString();

    final theoryId = _extractTheoryId(item);

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
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: (theoryId == null)
                                    ? null
                                    : () async {
                                        try {
                                          final res = await TeacherApiService
                                              .downloadTheoryFileWeb(theoryId);

                                          final isPdf = res.contentType
                                                  .toLowerCase()
                                                  .contains("pdf") ||
                                              res.filename
                                                  .toLowerCase()
                                                  .endsWith(".pdf");

                                          openOrDownloadBytesWeb(
                                            bytes: res.bytes,
                                            filename: res.filename,
                                            contentType: res.contentType,
                                            openInNewTab: isPdf,
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    "Ошибка открытия файла: $e")),
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: const Text("Открыть"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: () async {
                                // На web “ссылка” без токена бесполезна (401),
                                // но если всё же хочешь оставим копирование как "тех.ссылка":
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
                        if (theoryId == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text(
                              "Не удалось определить id материала (item['id']).",
                              style: TextStyle(color: Colors.redAccent),
                            ),
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
