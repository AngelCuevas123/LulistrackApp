import 'dart:convert';
import 'dart:io';

import 'api_service.dart';
import 'offline_database.dart';
import 'offline_evidence_storage.dart';

class DeliverySyncResult {
  final Set<String> syncedIds;
  final Set<String> pendingIds;
  final Map<String, String> rejected;
  const DeliverySyncResult({
    required this.syncedIds,
    required this.pendingIds,
    required this.rejected,
  });
}

class OfflineSyncService {
  OfflineSyncService._();

  static final OfflineSyncService instance = OfflineSyncService._();

  Future<DeliverySyncResult> syncPendingDeliveries() async {
    if (ApiService.authToken == null || ApiService.authToken!.isEmpty) {
      return const DeliverySyncResult(
        syncedIds: <String>{},
        pendingIds: <String>{},
        rejected: <String, String>{},
      );
    }

    final pending = await OfflineDatabase.instance.getPendingDeliveries();
    final syncedIds = <String>{};
    final pendingIds = <String>{};
    final rejected = <String, String>{};

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
          const message = 'No se encontraron los archivos de evidencia en el dispositivo.';
          await OfflineDatabase.instance.recordDeliveryFailure(localId, message);
          rejected[localId] = message;
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
          const message = 'El servidor no confirmó la entrega. Se reintentará más tarde.';
          await OfflineDatabase.instance.recordDeliveryFailure(localId, message);
          pendingIds.add(localId);
          continue;
        }

        await OfflineDatabase.instance.markDeliverySynced(localId);
        await OfflineEvidenceStorage.instance.deleteFileIfExists(photoPath);
        await OfflineEvidenceStorage.instance
            .deleteFileIfExists(signaturePath);
        syncedIds.add(localId);
      } catch (error) {
        final permanentHttpError =
            error is DeliverySubmissionException &&
            error.statusCode >= 400 &&
            error.statusCode < 500 &&
            error.statusCode != 408 &&
            error.statusCode != 429;
        await OfflineDatabase.instance.recordDeliveryFailure(
          localId,
          error.toString(),
        );
        if (permanentHttpError) {
          rejected[localId] = error.toString();
        } else {
          pendingIds.add(localId);
        }
      }
    }

    return DeliverySyncResult(
      syncedIds: syncedIds,
      pendingIds: pendingIds,
      rejected: rejected,
    );
  }
}
