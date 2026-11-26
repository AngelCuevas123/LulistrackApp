
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'api_service.dart';
import 'haptic_service.dart';

class NotificationService {
  static StreamSubscription<String>? _installationSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;

  static String? _currentInstallationId;
  static String? _lastRegisteredInstallationId;
  static String? _registrationInProgressId;
  static bool _initializationComplete = false;
  static bool _initializing = false;

  static String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  // Solicita permisos y registra el Firebase Installation ID.
  static Future<void> initializeAndRegister() async {
    if (ApiService.authToken == null ||
        ApiService.authToken!.isEmpty ||
        _initializationComplete ||
        _initializing) {
      return;
    }

    _initializing = true;
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('El usuario rechazó las notificaciones.');
        _initializationComplete = true;
        return;
      }

      // Las suscripciones son únicas durante la sesión de la aplicación.
      _listenInstallationRegistration();
      _listenForegroundMessages();

      await messaging.register();
      _initializationComplete = true;
    } finally {
      _initializing = false;
    }
  }

  // Escucha los Firebase Installation IDs generados por Firebase.
  static void _listenInstallationRegistration() {
    if (_installationSubscription != null) return;

    _installationSubscription =
        FirebaseMessaging.instance.onRegistered.listen(
              (installationId) async {
            _currentInstallationId = installationId;

            if (ApiService.authToken == null ||
                ApiService.authToken!.isEmpty ||
                installationId == _lastRegisteredInstallationId ||
                installationId == _registrationInProgressId) {
              return;
            }

            _registrationInProgressId = installationId;
            try {
              await ApiService.registerFirebaseInstallationId(
                firebaseInstallationId: installationId,
                platform: _platform,
              );
              _lastRegisteredInstallationId = installationId;

              debugPrint(
                'Firebase Installation ID registrado correctamente.',
              );
            } catch (e) {
              debugPrint(
                'Error al registrar el Firebase Installation ID: $e',
              );
            } finally {
              if (_registrationInProgressId == installationId) {
                _registrationInProgressId = null;
              }
            }
          },
          onError: (error) {
            debugPrint(
              'Error escuchando el registro de Firebase: $error',
            );
          },
        );
  }

  // Escucha notificaciones recibidas mientras la app está abierta.
  static void _listenForegroundMessages() {
    if (_foregroundSubscription != null) return;

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
          (RemoteMessage message) async {
        debugPrint(
          'Notificación recibida: ${message.notification?.title}',
        );

        debugPrint(
          'Contenido: ${message.notification?.body}',
        );

        if (message.notification != null || message.data.isNotEmpty) {
          await HapticService.notificationReceived();
        }
      },
    );
  }

  // Desactiva el dispositivo en el backend al cerrar sesión.
  static Future<void> unregisterCurrentInstallation() async {
    try {
      final installationId = _currentInstallationId;

      if (installationId != null &&
          installationId.isNotEmpty &&
          ApiService.authToken != null &&
          ApiService.authToken!.isNotEmpty) {
        await ApiService.unregisterFirebaseInstallationId(
          installationId,
        );
      }
    } catch (e) {
      debugPrint('Error al desactivar el dispositivo: $e');
    } finally {
      await _installationSubscription?.cancel();
      _installationSubscription = null;

      await _foregroundSubscription?.cancel();
      _foregroundSubscription = null;

      _currentInstallationId = null;
      _lastRegisteredInstallationId = null;
      _registrationInProgressId = null;
      _initializationComplete = false;
      _initializing = false;
    }
  }
}
