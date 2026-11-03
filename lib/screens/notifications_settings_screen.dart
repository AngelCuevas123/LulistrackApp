import 'package:flutter/material.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  static const Color primaryNavy = Color(0xFF1E3A8A);
  static const Color accentPink = Color(0xFFC23B75);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color textGray = Color(0xFF64748B);

  bool pushAlerts = true;
  bool emailAlerts = false;
  bool routeUpdates = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: primaryNavy,
        elevation: 0,
        title: const Text('Notificaciones', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            title: const Text('Alertas Push de Nuevos Paquetes', style: TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
            subtitle: const Text('Avisos inmediatos al asignar rutas', style: TextStyle(fontSize: 12, color: textGray)),
            value: pushAlerts,
            activeColor: accentPink,
            onChanged: (val) => setState(() => pushAlerts = val),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Resumen por Correo', style: TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
            subtitle: const Text('Reportes diarios de entregas completadas', style: TextStyle(fontSize: 12, color: textGray)),
            value: emailAlerts,
            activeColor: accentPink,
            onChanged: (val) => setState(() => emailAlerts = val),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Actualizaciones en Vivo', style: TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
            subtitle: const Text('Cambios de estatus y sincronización', style: TextStyle(fontSize: 12, color: textGray)),
            value: routeUpdates,
            activeColor: accentPink,
            onChanged: (val) => setState(() => routeUpdates = val),
          ),
        ],
      ),
    );
  }
}
