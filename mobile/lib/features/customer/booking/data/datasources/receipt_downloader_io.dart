import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveReceiptPdf({
  required Uint8List bytes,
  required String fileName,
}) async {
  final directory = await getTemporaryDirectory();

  final file = File('${directory.path}/$fileName');

  await file.writeAsBytes(
    bytes,
    flush: true,
  );

  await Share.shareXFiles(
    [XFile(file.path)],
    text: 'Comprobante de reserva',
    subject: 'Comprobante de reserva AndanDO',
  );
}