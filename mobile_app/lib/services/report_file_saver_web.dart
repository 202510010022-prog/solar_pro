import 'dart:js_interop';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:web/web.dart' as web;

import 'report_file_saver_stub.dart';

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

Future<void> downloadSavedReport(SavedReport report) async {
  final bytes = await report.xFile.readAsBytes();
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: report.mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..download = report.fileName
    ..href = url;
  anchor.style.display = 'none';

  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
