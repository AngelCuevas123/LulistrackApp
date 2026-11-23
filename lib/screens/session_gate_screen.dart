import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/api_service.dart';
import '../services/biometric_service.dart';
import '../services/notification_service.dart';
import '../widgets/lulistrack_loading.dart';
import 'login_screen.dart';
import 'main_navigation.dart';

class SessionGateScreen extends StatefulWidget {
  const SessionGateScreen({super.key});

  @override
  State<SessionGateScreen> createState() => _SessionGateScreenState();
}

class _SessionGateScreenState extends State<SessionGateScreen> {
  bool _loading = true;
  bool _locked = false;
  bool _authenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      _goToLogin();
      return;
    }

    ApiService.authToken = session.accessToken;
    ApiService.currentDriver = null;

    // La sesión persistida y su renovación pertenecen a Supabase Auth.
    // Un fallo temporal del backend no debe borrar una sesión válida.
    try {
      await ApiService.getMyDriverProfile(forceRefresh: true);
    } catch (error) {
      debugPrint('No se pudo actualizar el perfil al restaurar la sesión: $error');
    }

    try {
      await NotificationService.initializeAndRegister();
    } catch (error) {
      debugPrint('No se pudo registrar FCM al restaurar la sesión: $error');
    }

    if (!mounted) return;

    if (await BiometricService.instance.isEnabled()) {
      setState(() {
        _loading = false;
        _locked = true;
      });
      await _unlock();
    } else {
      _goToApp();
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _goToApp() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  Future<void> _unlock() async {
    if (_authenticating || !mounted) return;
    setState(() {
      _authenticating = true;
      _error = null;
    });

    final authenticated = await BiometricService.instance.authenticate(
      reason: 'Desbloquea Lulistrack para acceder a tu cuenta.',
    );

    if (!mounted) return;
    setState(() => _authenticating = false);

    if (authenticated) {
      _goToApp();
    } else {
      setState(() {
        _error = 'No se pudo verificar tu identidad. Inténtalo nuevamente.';
      });
    }
  }

  Future<void> _usePasswordInstead() async {
    await Supabase.instance.client.auth.signOut();
    await BiometricService.instance.clearForSignOut();
    ApiService.authToken = null;
    ApiService.currentDriver = null;
    _goToLogin();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF213A81);
    const pink = Color(0xFFBA4078);

    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: LulistrackLoading(
          title: 'Verificando tu sesión',
          subtitle: 'Estamos preparando tu espacio de trabajo seguro.',
          icon: Icons.fingerprint_rounded,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.fingerprint_rounded,
                  color: navy,
                  size: 82,
                ),
                const SizedBox(height: 22),
                const Text(
                  'Bienvenido de nuevo',
                  style: TextStyle(
                    color: navy,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Confirma tu identidad para continuar en Lulistrack.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _authenticating ? null : _unlock,
                    icon: _authenticating
                        ? const LulistrackActionLoading(color: Colors.white, size: 19)
                        : const Icon(Icons.lock_open_rounded),
                    label: Text(
                      _authenticating ? 'Verificando...' : 'Desbloquear',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: pink,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _authenticating ? null : _usePasswordInstead,
                  child: const Text('Cerrar sesión e ingresar con contraseña'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
