import 'package:flutter/material.dart';

class TechSupportScreen extends StatelessWidget {
  const TechSupportScreen({super.key});

  static const Color primaryNavy = Color(0xFF1E3A8A);
  static const Color accentPink = Color(0xFFC23B75);
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
        title: const Text('Soporte Técnico', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  const CircleAvatar(radius: 32, backgroundColor: Color(0xFFEEF2FF), child: Icon(Icons.headset_mic_rounded, color: primaryNavy, size: 32)),
                  const SizedBox(height: 14),
                  const Text('Centro de Atención Lulistrack', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primaryNavy)),
                  const SizedBox(height: 6),
                  const Text('Estado del sistema: Conectado a Render y FastAPI', style: TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conectando con un operador en línea...')));
                      },
                      icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 18),
                      label: const Text('Iniciar Chat con Operador', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: accentPink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
}