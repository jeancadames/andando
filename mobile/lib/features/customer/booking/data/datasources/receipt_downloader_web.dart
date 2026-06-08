import 'dart:html' as html;
import 'dart:typed_data';

Future<void> saveReceiptPdf({
  required Uint8List bytes,
  required String fileName,
}) async {
  final blob = html.Blob(
    [bytes],
    'application/pdf',
  );

  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  html.Url.revokeObjectUrl(url);
}