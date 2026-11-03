import 'package:flutter/material.dart';

class DeliveryReceiptScreen extends StatelessWidget {
  final String orderId;

  const DeliveryReceiptScreen({
    super.key,
    this.orderId = '#LT-543210',
  });

  // Paleta de colores oficial
  static const Color primaryNavy = Color(0xFF1E3A8A);
  static const Color accentPink = Color(0xFFC23B75);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textGray = Color(0xFF64748B);
  static const Color statusYellow = Color(0xFFFEF08A);
  static const Color statusGreenBg = Color(0xFF1E3B8A); // O azul oscuro para entregado

  @override
  Widget build(BuildContext context) {
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
          'Recibo entrega',
          style: TextStyle(
            color: primaryNavy,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, color: primaryNavy, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    // Círculo de éxito y Título "Entrega Completada"
                    const SizedBox(height: 10),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: statusYellow,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusYellow.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.check_rounded,
                          color: primaryNavy, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Entrega Completada',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Otro pedido entregado satisfactoriamente',
                      style: TextStyle(
                        fontSize: 13,
                        color: textGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tarjeta Principal de Recibo
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: cardBorder, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ID de Orden y Etiqueta ENTREGADO
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                orderId,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryNavy,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: statusGreenBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check, size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'ENTREGADO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '27 Oct 2026 · 10:24 AM',
                            style: TextStyle(
                              fontSize: 12,
                              color: textGray,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),

                          // Información del Cliente y Dirección
                          const Text(
                            'Maria Oliveira',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '214 W 16th St, Apt 3B\nNew York, NY 10011',
                            style: TextStyle(
                              fontSize: 13,
                              color: textGray,
                              height: 1.4,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),

                          // Detalles del Paquete y Comprobante
                          _buildDetailRow(label: 'Paquete', value: '1 paquete · 2.4 kg'),
                          const SizedBox(height: 10),
                          _buildDetailRow(label: 'Entregado por', value: 'Juan Cuevas'),
                          const SizedBox(height: 10),
                          _buildDetailRow(label: 'Comprobante de Entrega', value: 'foto + firma'),
                          
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),

                          // Sincronización segura
                          const Row(
                            children: [
                              Icon(Icons.verified_user_outlined, size: 16, color: textGray),
                              SizedBox(width: 8),
                              Text(
                                'Sincronizado de manera segura',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tarjeta de Próxima Parada (Siguiente entrega)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cardBorder, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.alt_route_rounded,
                                color: primaryNavy, size: 20),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Proxima parada',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: textGray,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Daniel Kim',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: primaryNavy,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '85 10th Ave, Floor 2 · #LT-543211',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: textGray, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Botón Inferior: Volver a Entregas
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Regresar a la pantalla principal de Home
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
                    shadowColor: accentPink.withOpacity(0.4),
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

  // Widget auxiliar para filas de detalle
  Widget _buildDetailRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: textGray,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: primaryNavy,
          ),
        ),
      ],
    );
  }
}
