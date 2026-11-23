import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Administra la preferencia biométrica del dispositivo.
/// Supabase conserva y renueva su propia sesión; aquí no se guarda la contraseña
/// ni se copia manualmente el refresh token.
class BiometricService {
  BiometricService._();

  static final BiometricService instance = BiometricService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final LocalAuthentication _auth = LocalAuthentication();

  static const String _enabledKey = 'lulistrack_biometric_enabled';
  static const String _promptedKey = 'lulistrack_biometric_prompted';

  Future<bool> isEnabled() async {
    return await _storage.read(key: _enabledKey) == 'true';
  }

  Future<void> setEnabled(bool enabled) async {
    await _storage.write(key: _enabledKey, value: enabled ? 'true' : 'false');
  }

  Future<bool> wasPrompted() async {
    return await _storage.read(key: _promptedKey) == 'true';
  }

  Future<void> markPrompted() async {
    await _storage.write(key: _promptedKey, value: 'true');
  }

  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      final biometrics = await _auth.getAvailableBiometrics();
      return supported && canCheck && biometrics.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticate({
    String reason = 'Desbloquea Lulistrack para continuar.',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Se utiliza al cerrar sesión explícitamente o cambiar de cuenta.
  Future<void> clearForSignOut() async {
    await _storage.delete(key: _enabledKey);
    await _storage.delete(key: _promptedKey);
  }
}
