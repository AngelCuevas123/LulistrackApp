import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class OfflineEvidenceStorage {
  OfflineEvidenceStorage._();

  static final OfflineEvidenceStorage instance = OfflineEvidenceStorage._();

  Future<String> saveBase64({
    required String orderId,
    required String kind,
    required String value,
    required String extension,
  }) async {
    final normalized = value.contains(',') && value.startsWith('data:')
        ? value.substring(value.indexOf(',') + 1)
        : value;
    final bytes = base64Decode(normalized);
    return saveBytes(
      orderId: orderId,
      kind: kind,
      bytes: bytes,
      extension: extension,
    );
  }

  Future<String> saveBytes({
    required String orderId,
    required String kind,
    required List<int> bytes,
    required String extension,
  }) async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(root.path, 'lulistrack', 'evidence'));
    await directory.create(recursive: true);

    final safeOrderId = orderId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final filename =
        '${safeOrderId}_${kind}_${DateTime.now().microsecondsSinceEpoch}.$extension';
    final file = File(p.join(directory.path, filename));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> deleteFileIfExists(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
