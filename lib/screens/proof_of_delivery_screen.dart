import 'package:flutter/material.dart';

class ProofOfDeliveryScreen extends StatelessWidget {
  final String orderId;

  const ProofOfDeliveryScreen({
    super.key,
    this.orderId = 'LT-543210',
  });

  // Paleta de colores oficial
  static const Color primaryNavy = Color(0xFF1E3A8A);
  static const Color accentPink = Color(0xFFC23B75);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textGray = Color(0xFF64748B);
  static const Color textLightGray = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Comprobante de entrega',
          style: TextStyle(
            color: primaryNavy,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, color: primaryNavy),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título y subtítulo principal
                    Text(
                      'Completar Entrega\n$orderId',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryNavy,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Maria Oliveira · Calle del Agua, Apt 3B',
                      style: TextStyle(
                        fontSize: 13,
                        color: textGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Indicador de Pasos (Steps: 1 Foto, 2 Firma, 3 Revision)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStepItem(stepNumber: '1', title: 'Foto', isActive: true),
                          Container(height: 20, width: 1, color: cardBorder),
                          _buildStepItem(stepNumber: '2', title: 'Firma', isActive: false),
                          Container(height: 20, width: 1, color: cardBorder),
                          _buildStepItem(stepNumber: '3', title: 'Revision', isActive: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tarjeta: Evidencia Fotográfica
                    _buildRequirementCard(
                      icon: Icons.camera_alt_outlined,
                      title: 'Evidencia Fotografica',
                      subtitle: 'Show the package and delivery location.',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),

                    // Tarjeta: Firma Digital
                    _buildRequirementCard(
                      icon: Icons.edit_outlined,
                      title: 'Firma Digital',
                      subtitle: 'Ask the recipient to sign with their finger.',
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),

                    // Nota informativa inferior
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_user_outlined, color: primaryNavy, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ambos elementos son requeridos. Su entrega permanece en tránsito hasta que se revise y confirme.',
                              style: TextStyle(
                                fontSize: 11,
                                color: primaryNavy,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Pie de página y botón de confirmación (Desactivado inicialmente por requerir elementos)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Elementos añadidos · Aun no enviado',
                    style: TextStyle(
                      fontSize: 12,
                      color: textGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: null, // Desactivado hasta completar los pasos
                      icon: const Icon(Icons.lock_outline_rounded, size: 18),
                      label: const Text(
                        'Confirmar Entrega',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        disabledForegroundColor: textLightGray,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para cada paso superior
  Widget _buildStepItem({required String stepNumber, required String title, required bool isActive}) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFEF08A) : cardBorder,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            stepNumber,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? const Color(0xFF854D0E) : textGray,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? primaryNavy : textGray,
          ),
        ),
      ],
    );
  }

  // Widget para las tarjetas de requisitos (Foto y Firma)
  Widget _buildRequirementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accentPink, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '',
                        style: TextStyle(fontSize: 0),
                      ),
                      Text(
                        'REQUERIDO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: textLightGray,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: textGray,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.north_east_rounded, color: accentPink, size: 18),
          ],
        ),
      ),
    );
  }
}
