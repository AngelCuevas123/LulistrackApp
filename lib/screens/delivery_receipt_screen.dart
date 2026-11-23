import 'package:flutter/material.dart';

class DeliveryReceiptScreen extends StatelessWidget {
  final String orderId;
  final String trackingNumber;
  final String clientName;
  final String address;
  final String colony;
  final String deliveredBy;
  final DateTime? deliveredAt;
  final bool pendingSync;
  final String? syncError;

  const DeliveryReceiptScreen({
    super.key,
    required this.orderId,
    this.trackingNumber = '',
    this.clientName = '',
    this.address = '',
    this.colony = '',
    this.deliveredBy = '',
    this.deliveredAt,
    this.pendingSync = false,
    this.syncError,
  });

  static const Color primaryNavy = Color(0xFF1E3A8A);
  static const Color accentPink = Color(0xFFC23B75);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textGray = Color(0xFF64748B);

  String _formatDate(DateTime value) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'p. m.' : 'a. m.';
    return value.day.toString() + ' ' + months[value.month - 1] + ' ' +
        value.year.toString() + ' · ' + hour.toString() + ':' + minute + ' ' + period;
  }

  @override
  Widget build(BuildContext context) {
    final hasSyncIssue = syncError != null || pendingSync;
    final displayOrder = trackingNumber.trim().isNotEmpty
        ? trackingNumber
        : orderId;
    final displayClient = clientName.trim().isNotEmpty
        ? clientName
        : 'Cliente no disponible';
    final addressParts = [
      address.trim(),
      colony.trim(),
    ].where((part) => part.isNotEmpty).toList();
    final displayAddress = addressParts.join(' · ');
    final displayDriver = deliveredBy.trim().isNotEmpty
        ? deliveredBy
        : 'Repartidor no disponible';
    final date = deliveredAt ?? DateTime.now();

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: primaryNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Recibo de entrega',
          style: TextStyle(
            color: primaryNavy,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: hasSyncIssue
                            ? const Color(0xFFFFEDD5)
                            : const Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasSyncIssue
                            ? Icons.cloud_upload_outlined
                            : Icons.check_rounded,
                        color: hasSyncIssue
                            ? const Color(0xFF9A3412)
                            : const Color(0xFF15803D),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      hasSyncIssue ? 'Entrega guardada' : 'Entrega completada',
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      syncError ??
                          (pendingSync
                              ? 'La evidencia está guardada en el dispositivo y se sincronizará cuando haya conexión.'
                              : 'El comprobante de esta entrega se registró correctamente.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: textGray,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'PEDIDO',
                                style: TextStyle(
                                  color: textGray,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: hasSyncIssue
                                      ? const Color(0xFFFFEDD5)
                                      : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  hasSyncIssue ? 'PENDIENTE' : 'ENTREGADO',
                                  style: TextStyle(
                                    color: hasSyncIssue
                                        ? const Color(0xFF9A3412)
                                        : const Color(0xFF166534),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            displayOrder,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatDate(date),
                            style: const TextStyle(fontSize: 12, color: textGray),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                          const Text(
                            'DESTINATARIO',
                            style: TextStyle(
                              color: textGray,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            displayClient,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayAddress.isEmpty
                                ? 'Dirección no disponible'
                                : displayAddress,
                            style: const TextStyle(
                              fontSize: 13,
                              color: textGray,
                              height: 1.4,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                          _buildDetailRow('Entregado por', displayDriver),
                          const SizedBox(height: 14),
                          _buildDetailRow('Evidencia', 'Fotografía + firma'),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                          Row(
                            children: [
                              Icon(
                                hasSyncIssue
                                    ? Icons.cloud_off_outlined
                                    : Icons.verified_user_outlined,
                                size: 17,
                                color: textGray,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  hasSyncIssue
                                      ? 'Pendiente de sincronización con el servidor'
                                      : 'Comprobante sincronizado con el servidor',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: textGray,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 18),
                  label: const Text(
                    'Volver a Entregas',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentPink,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: textGray),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: primaryNavy,
            ),
          ),
        ),
      ],
    );
  }
}
