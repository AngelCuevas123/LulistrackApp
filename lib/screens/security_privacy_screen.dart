import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/biometric_service.dart';
import '../widgets/lulistrack_loading.dart';

class SecurityPrivacyScreen extends StatefulWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  State<SecurityPrivacyScreen> createState() => _SecurityPrivacyScreenState();
}

class _SecurityPrivacyScreenState extends State<SecurityPrivacyScreen> {
  static const Color primaryNavy = Color(0xFF1E3A8A);
  static const Color accentPink = Color(0xFFC23B75);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textGray = Color(0xFF64748B);

  bool _biometricEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final enabled = await BiometricService.instance.isEnabled();
    if (!mounted) return;
    setState(() {
      _biometricEnabled = enabled;
      _loading = false;
    });
  }

  Future<void> _sendPasswordReset() async {
    final emailController = TextEditingController(
      text: Supabase.instance.client.auth.currentUser?.email ?? '',
    );
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restablecer contraseña'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            hintText: 'nombre@correo.com',
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              emailController.text.trim(),
            ),
            child: const Text('Enviar enlace'),
          ),
        ],
      ),
    );
    emailController.dispose();

    if (email == null || email.isEmpty || !mounted) return;
    final validEmail = email.contains('@') &&
        email.split('@').last.contains('.');
    if (!validEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un correo electrónico válido.')),
      );
      return;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Si la cuenta está registrada, recibirás instrucciones para restablecer tu contraseña.',
          ),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar el enlace: ${error.message}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo completar la solicitud. Inténtalo nuevamente.'),
        ),
      );
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    final service = BiometricService.instance;

    if (value) {
      if (!await service.isAvailable()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Este dispositivo no tiene biometría configurada o disponible.',
            ),
          ),
        );
        return;
      }

      final authenticated = await service.authenticate(
        reason: 'Confirma tu identidad para activar el acceso biométrico.',
      );
      if (!authenticated) return;
    }

    await service.setEnabled(value);
    if (!mounted) return;
    setState(() => _biometricEnabled = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Acceso biométrico activado.'
              : 'Acceso biométrico desactivado.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: primaryNavy,
        elevation: 0,
        title: const Text(
          'Seguridad y Privacidad',
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: cardBorder),
              ),
              leading: const Icon(
                Icons.lock_reset_rounded,
                color: primaryNavy,
              ),
              title: const Text(
                'Cambiar Contraseña',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryNavy,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: textGray,
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enlace de restablecimiento enviado'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: cardBorder),
              ),
              leading: const Icon(
                Icons.fingerprint_rounded,
                color: primaryNavy,
              ),
              title: const Text(
                'Autenticación Biométrica',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryNavy,
                ),
              ),
              subtitle: const Text(
                'Desbloquea Lulistrack con huella o reconocimiento facial',
                style: TextStyle(fontSize: 12, color: textGray),
              ),
              trailing: _loading
                  ? const LulistrackActionLoading(color: accentPink, size: 22)
                  : Switch(
                      value: _biometricEnabled,
                      activeColor: accentPink,
                      onChanged: _toggleBiometrics,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
