import 'dart:convert';
import 'dart:io';

import 'api_service.dart';
import 'offline_database.dart';
import 'offline_evidence_storage.dart';

class OfflineSyncService {
  OfflineSyncService._();

  static final OfflineSyncService instance = OfflineSyncService._();

  Future<Set<String>> syncPendingDeliveries() async {
    if (ApiService.authToken == null || ApiService.authToken!.isEmpty) {
      return <String>{};
    }

    final pending = await OfflineDatabase.instance.getPendingDeliveries();
    final syncedIds = <String>{};

    for (final item in pending) {
      final localId = item['local_id']?.toString();
      final orderId = item['order_id']?.toString();
      final photoPath = item['photo_path']?.toString();
      final signaturePath = item['signature_path']?.toString();

      if (localId == null ||
          orderId == null ||
          photoPath == null ||
          signaturePath == null) {
        continue;
      }

      try {
        final photoFile = File(photoPath);
        final signatureFile = File(signaturePath);
        if (!await photoFile.exists() || !await signatureFile.exists()) {
          await OfflineDatabase.instance.recordDeliveryFailure(
            localId,
            'No se encontraron los archivos de evidencia en el dispositivo.',
          );
          continue;
        }

        final photoBase64 = base64Encode(await photoFile.readAsBytes());
        final signatureBase64 =
            base64Encode(await signatureFile.readAsBytes());

        final success = await ApiService.submitProofOfDelivery(
          orderId: orderId,
          photoBase64: photoBase64,
          signatureBase64: signatureBase64,
        );

        if (!success) {
          await OfflineDatabase.instance.recordDeliveryFailure(
            localId,
            'El servidor no confirmó la entrega. Se reintentará más tarde.',
          );
          continue;
        }

        await OfflineDatabase.instance.markDeliverySynced(localId);
        await OfflineEvidenceStorage.instance.deleteFileIfExists(photoPath);
        await OfflineEvidenceStorage.instance
            .deleteFileIfExists(signaturePath);
        syncedIds.add(localId);
      } catch (error) {
        await OfflineDatabase.instance.recordDeliveryFailure(
          localId,
          error.toString(),
        );
      }
    }

    return syncedIds;
  }
}
