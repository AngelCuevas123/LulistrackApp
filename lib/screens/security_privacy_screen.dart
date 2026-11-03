import 'package:flutter/material.dart';

class SecurityPrivacyScreen extends StatelessWidget {
  const SecurityPrivacyScreen({super.key});

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
        title: const Text('Seguridad y Privacidad', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: cardBorder)),
              leading: const Icon(Icons.lock_reset_rounded, color: primaryNavy),
              title: const Text('Cambiar Contraseña', style: TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: textGray),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlace de restablecimiento enviado')));
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: cardBorder)),
              leading: const Icon(Icons.fingerprint_rounded, color: primaryNavy),
              title: const Text('Autenticación Biométrica', style: TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
              subtitle: const Text('Usar huella dactilar para acceder', style: TextStyle(fontSize: 12, color: textGray)),
              trailing: Switch(value: true, activeColor: accentPink, onChanged: (val) {}),
            ),
          ],
        ),
      ),
    );
  }
}
