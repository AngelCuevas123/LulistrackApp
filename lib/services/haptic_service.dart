import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centraliza la retroalimentación háptica de Lulistrack.
///
/// Los patrones usan las APIs estándar de Flutter; su intensidad real depende
/// del motor háptico y de las capacidades del dispositivo.
class HapticService {
  HapticService._();

  static const String preferenceKey = 'immersive_haptics_enabled';
  static final Map<String, DateTime> _lastFeedback = <String, DateTime>{};

  static Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(preferenceKey) ?? true;
  }

  static Future<bool> _canPlay(String event, {int cooldownMs = 450}) async {
    if (!await isEnabled) return false;
    final now = DateTime.now();
    final previous = _lastFeedback[event];
    if (previous != null &&
        now.difference(previous).inMilliseconds < cooldownMs) {
      return false;
    }
    _lastFeedback[event] = now;
    return true;
  }

  /// Pedido nuevo disponible: toque breve y discreto.
  static Future<void> newOrder() async {
    if (await _canPlay('new_order', cooldownMs: 1800)) {
      await HapticFeedback.selectionClick();
    }
  }

  /// Notificación push recibida con la app en primer plano.
  static Future<void> notificationReceived() async {
    if (await _canPlay('notification_received', cooldownMs: 1800)) {
      await HapticFeedback.selectionClick();
    }
  }

  /// Pedido asignado al repartidor: confirmación media.
  static Future<void> orderAccepted() async {
    if (await _canPlay('order_accepted')) {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Entrega confirmada y sincronizada: confirmación firme única.
  static Future<void> deliveryCompleted() async {
    if (await _canPlay('delivery_completed')) {
      await HapticFeedback.heavyImpact();
    }
  }

  /// Evidencia guardada localmente, pendiente de sincronización.
  static Future<void> deliveryPending() async {
    if (await _canPlay('delivery_pending')) {
      await HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 140));
      await HapticFeedback.mediumImpact();
    }
  }

  /// Incidencia reportada: patrón de atención de dos pulsos firmes.
  static Future<void> incidentReported() async {
    if (await _canPlay('incident_reported', cooldownMs: 1200)) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 160));
      await HapticFeedback.heavyImpact();
    }
  }

  /// Error que requiere atención: vibración larga y repetida.
  static Future<void> failure() async {
    if (await _canPlay('failure')) {
      await HapticFeedback.vibrate();
      await Future<void>.delayed(const Duration(milliseconds: 220));
      await HapticFeedback.vibrate();
    }
  }

  /// Evidencia pendiente que finalmente se sincronizó.
  static Future<void> syncRecovered() async {
    if (await _canPlay('sync_recovered')) {
      await HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.selectionClick();
    }
  }

  // Compatibilidad con los nombres anteriores mientras se migran pantallas.
  static Future<void> light() => newOrder();
  static Future<void> success() => orderAccepted();
  static Future<void> warning() => deliveryPending();
  static Future<void> error() => failure();
}
