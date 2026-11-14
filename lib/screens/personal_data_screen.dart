import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';

class PersonalDataScreen extends StatelessWidget {
  const PersonalDataScreen({super.key});

  static const Color primaryNavy = Color(0xFF1E3A8A);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textGray = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final driver = ApiService.currentDriver;
    final authUser = Supabase.instance.client.auth.currentUser;
    final phone = authUser?.phone?.isNotEmpty == true
        ? authUser!.phone!
        : (authUser?.userMetadata?['phone']?.toString() ?? 'No registrado');

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: primaryNavy,
        elevation: 0,
        title: const Text('Datos Personales', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: primaryNavy,
                child: Text(
                  driver?.initials ?? 'R',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildField('Nombre Completo', driver?.name ?? 'No disponible'),
            _buildField('Correo Electrónico', authUser?.email ?? 'No disponible'),
            _buildField('Teléfono', phone),
            _buildField('Vehículo', driver?.vehicle ?? 'No registrado'),
            _buildField('ID de repartidor', driver?.driverId ?? 'No disponible'),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textGray)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryNavy)),
        ],
      ),
    );
  }
}
