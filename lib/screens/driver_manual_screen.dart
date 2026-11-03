import 'package:flutter/material.dart';

class DriverManualScreen extends StatelessWidget {
  const DriverManualScreen({super.key});

  static const Color primaryNavy = Color(0xFF1E3A8A);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textGray = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: primaryNavy,
        elevation: 0,
        title: const Text('Manual del Conductor', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildManualStep('1. Sincronización de Ruta', 'Desliza hacia abajo en la pantalla principal o presiona el botón de recarga para obtener los paquetes más recientes desde FastAPI.'),
          _buildManualStep('2. Consulta de Mapas', 'Toca el botón "Ver Mapa" en cualquier entrega para abrir la ubicación exacta de manera automática en Google Maps.'),
          _buildManualStep('3. Captura de Evidencias', 'Al llegar con el cliente, inicia el comprobante para tomar la foto de entrega y capturar su firma digital obligatoria.'),
          _buildManualStep('4. Historial Automático', 'Una vez completada la entrega, el pedido se moverá de forma dinámica al apartado de Historial en el servidor.'),
        ],
      ),
    );
  }

  Widget _buildManualStep(String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryNavy)),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(fontSize: 13, color: textGray, height: 1.4)),
        ],
      ),
    );
  }
}
