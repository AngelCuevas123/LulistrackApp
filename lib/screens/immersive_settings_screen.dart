import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImmersiveSettingsScreen extends StatefulWidget {
  const ImmersiveSettingsScreen({super.key});

  @override
  State<ImmersiveSettingsScreen> createState() =>
      _ImmersiveSettingsScreenState();
}

class _ImmersiveSettingsScreenState extends State<ImmersiveSettingsScreen> {
  static const Color primaryNavy = Color(0xFF1E3A8A);
  static const Color accentPink = Color(0xFFC23B75);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color textGray = Color(0xFF64748B);

  bool _hapticsEnabled = true;
  bool _voiceAssistantEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _hapticsEnabled = prefs.getBool('immersive_haptics_enabled') ?? true;
      _voiceAssistantEnabled =
          prefs.getBool('immersive_voice_assistant_enabled') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _setHaptics(bool value) async {
    setState(() => _hapticsEnabled = value);
    await _savePreference('immersive_haptics_enabled', value);
  }

  Future<void> _setVoiceAssistant(bool value) async {
    setState(() => _voiceAssistantEnabled = value);
    await _savePreference('immersive_voice_assistant_enabled', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: primaryNavy,
        elevation: 0,
        title: const Text(
          'Experiencia inmersiva',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentPink))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: primaryNavy,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.spatial_audio_off_rounded,
                          color: Colors.white, size: 34),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Interactúa con Lulistrack',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Configura vibraciones y comandos de voz. La escucha se detiene automáticamente al terminar cada frase.',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'RETROALIMENTACIÓN',
                  style: TextStyle(
                    color: textGray,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                _settingTile(
                  icon: Icons.vibration_rounded,
                  title: 'Vibraciones hápticas',
                  subtitle: 'Patrones distintos para pedidos nuevos, entregas, incidencias y errores de sincronización.',
                  value: _hapticsEnabled,
                  onChanged: _setHaptics,
                ),
                const SizedBox(height: 22),
                const Text(
                  'ASISTENCIA POR VOZ',
                  style: TextStyle(
                    color: textGray,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                _settingTile(
                  icon: Icons.record_voice_over_rounded,
                  title: 'Asistente de voz',
                  subtitle: 'Permite reconocer comandos y escuchar respuestas de Lulistrack.',
                  value: _voiceAssistantEnabled,
                  onChanged: _setVoiceAssistant,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_outlined,
                          color: Color(0xFF92400E), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Por seguridad, utiliza los comandos de voz únicamente cuando estés detenido. Las entregas y el registro de evidencias siempre requieren confirmación en pantalla.',
                          style: TextStyle(
                            color: Color(0xFF92400E),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        secondary: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryNavy),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: primaryNavy,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: textGray, fontSize: 11, height: 1.35),
        ),
        value: value,
        activeColor: accentPink,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
