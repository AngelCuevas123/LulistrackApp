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

  bool _isSyncing = false;

  Future<DeliverySyncResult> syncPendingDeliveries() async {
    if (_isSyncing) {
      return const DeliverySyncResult(
        syncedIds: <String>{},
        pendingIds: <String>{},
        rejected: <String, String>{},
      );
    }

    _isSyncing = true;
    try {
      return await _syncPendingDeliveries();
    } finally {
      _isSyncing = false;
    }
  }

  Future<DeliverySyncResult> _syncPendingDeliveries() async {
    if (ApiService.authToken == null || ApiService.authToken!.isEmpty) {
      final pending = await OfflineDatabase.instance.getPendingDeliveries();
      return DeliverySyncResult(
        syncedIds: <String>{},
        pendingIds: {
          for (final item in pending)
            if (item['local_id'] != null) item['local_id'].toString(),
        },
        rejected: <String, String>{},
      );
    }

    // La reclamación es transaccional en SQLite: otra instancia no puede
    // procesar al mismo tiempo los mismos comprobantes.
    final pending =
        await OfflineDatabase.instance.claimPendingDeliveries();
    if (pending.isEmpty) {
      return const DeliverySyncResult(
        syncedIds: <String>{},
        pendingIds: <String>{},
        rejected: <String, String>{},
      );
    }
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
        if (localId != null) {
          await OfflineDatabase.instance.markDeliveryNeedsAttention(
            localId,
            'El registro local está incompleto y requiere revisión.',
          );
          rejected[localId] = 'El registro local está incompleto y requiere revisión.';
        }
        continue;
      }

      try {
        final photoFile = File(photoPath);
        final signatureFile = File(signaturePath);
        if (!await photoFile.exists() || !await signatureFile.exists()) {
          const message = 'No se encontraron los archivos de evidencia en el dispositivo.';
          await OfflineDatabase.instance.markDeliveryNeedsAttention(
            localId,
            message,
          );
          rejected[localId] = message;
          continue;
        }

        final photoBase64 = base64Encode(await photoFile.readAsBytes());
        final signatureBase64 =
            base64Encode(await signatureFile.readAsBytes());

        final deliveredAt = DateTime.tryParse(
          item['timestamp']?.toString() ?? '',
        );
        if (deliveredAt == null) {
          const message = 'La fecha original de entrega no es válida. Revisa esta evidencia.';
          await OfflineDatabase.instance.markDeliveryNeedsAttention(
            localId,
            message,
          );
          rejected[localId] = message;
          continue;
        }

        final success = await ApiService.submitProofOfDelivery(
          orderId: orderId,
          photoBase64: photoBase64,
          signatureBase64: signatureBase64,
          deliveredAt: deliveredAt,
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
        if (permanentHttpError) {
          await OfflineDatabase.instance.recordDeliveryFailure(
            localId,
            error.toString(),
          );
          if (error is DeliverySubmissionException &&
              error.statusCode != 401 &&
              error.statusCode != 403) {
            await OfflineDatabase.instance.markDeliveryNeedsAttention(
              localId,
              error.toString(),
            );
          }
          rejected[localId] = error is DeliverySubmissionException &&
                  error.statusCode == 401
              ? 'Tu sesión ha expirado. Inicia sesión nuevamente para sincronizar.'
              : error is DeliverySubmissionException &&
                      error.statusCode == 403
                  ? 'Tu cuenta no tiene permiso para completar esta entrega.'
                  : 'El servidor rechazó la evidencia. Revisa los datos de la entrega.';
        } else {
          await OfflineDatabase.instance.recordDeliveryFailure(
            localId,
            error.toString(),
          );
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
