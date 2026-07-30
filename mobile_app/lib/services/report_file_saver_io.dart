import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';

import 'report_file_saver_stub.dart';

Future<SavedReport> saveReportBytes({
  required String fileName,
  required String mimeType,
  required Uint8List bytes,
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final reportsDirectory = Directory('${directory.path}/relatorios');
  if (!await reportsDirectory.exists()) {
    await reportsDirectory.create(recursive: true);
  }

  final file = File('${reportsDirectory.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);

  return SavedReport(
    fileName: fileName,
    mimeType: mimeType,
    path: file.path,
    xFile: XFile(file.path, name: fileName, mimeType: mimeType),
  );
}

Future<void> downloadSavedReport(SavedReport report) async {}
