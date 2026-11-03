import 'package:flutter/material.dart';
import 'tech_support_screen.dart';
import 'driver_manual_screen.dart';
import 'bug_report_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
        title: const Text(
          'Ayuda y Soporte',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildSupportOption(
            context,
            icon: Icons.support_agent_rounded,
            title: 'Contactar Soporte Técnico',
            subtitle: 'Habla con un operador en línea',
            destination: const TechSupportScreen(),
          ),
          const SizedBox(height: 12),
          _buildSupportOption(
            context,
            icon: Icons.menu_book_rounded,
            title: 'Manual del Conductor',
            subtitle: 'Guía rápida para entrega de paquetes y evidencias',
            destination: const DriverManualScreen(),
          ),
          const SizedBox(height: 12),
          _buildSupportOption(
            context,
            icon: Icons.bug_report_rounded,
            title: 'Reportar un Error',
            subtitle: 'Informa fallas de sincronización con FastAPI',
            destination: const BugReportScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget destination,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destination),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: primaryNavy, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
                const Icon(Icons.chevron_right, color: textGray, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
