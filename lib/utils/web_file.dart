import 'dart:typed_data';
import 'dart:async';
import 'dart:html' as html;

void openOrDownloadBytesWeb({
  required Uint8List bytes,
  required String filename,
  required String contentType,
  bool openInNewTab = true,
}) {
  final blob = html.Blob([bytes], contentType);
  final url = html.Url.createObjectUrlFromBlob(blob);

  if (openInNewTab) {
    // Открываем в новой вкладке (PDF / изображения)
    html.window.open(url, "_blank");

    // Освобождаем URL через минуту
    Timer(const Duration(minutes: 1), () {
      html.Url.revokeObjectUrl(url);
    });
  } else {
    // Принудительная загрузка
    final a = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = "none";

    html.document.body!.append(a);
    a.click();
    a.remove();
    html.Url.revokeObjectUrl(url);
  }
}
