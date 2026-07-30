import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';

class SavedReport {
  const SavedReport({
    required this.fileName,
    required this.mimeType,
    required this.xFile,
    this.path,
  });

  final String fileName;
  final String mimeType;
  final XFile xFile;
  final String? path;
}

Future<SavedReport> saveReportBytes({
  required String fileName,
  required String mimeType,
  required Uint8List bytes,
}) async {
  return SavedReport(
    fileName: fileName,
    mimeType: mimeType,
    xFile: XFile.fromData(bytes, name: fileName, mimeType: mimeType),
  );
}

Future<void> downloadSavedReport(SavedReport report) async {}
