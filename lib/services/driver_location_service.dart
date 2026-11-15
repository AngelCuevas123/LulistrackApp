import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../services/api_service.dart';

/// Comparte la ubicación mientras el repartidor tenga pedidos en tránsito
/// y la aplicación permanezca en primer plano.
class DriverLocationService {
  DriverLocationService._();

  static final DriverLocationService instance = DriverLocationService._();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _refreshTimer;
  bool _running = false;
  bool _checkingOrders = false;
  bool _permissionBlocked = false;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    _scheduleRefresh();
    await _refreshTrackingState();
  }

  Future<void> resume() async {
    if (!_running) return;
    _permissionBlocked = false;
    _scheduleRefresh();
    await _refreshTrackingState();
  }

  Future<void> pause() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    await _stopPositionStream();
  }

  Future<void> stop() async {
    _running = false;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    await _stopPositionStream();
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => unawaited(_refreshTrackingState()),
    );
  }

  Future<void> _refreshTrackingState() async {
    if (!_running || _checkingOrders || ApiService.authToken == null) {
      return;
    }

    _checkingOrders = true;
    try {
      final orders = await ApiService.getActiveOrders();
      final hasOrdersInTransit = orders.any(
        (order) => order.status.toLowerCase() == 'en_transito',
      );

      if (!hasOrdersInTransit) {
        await _stopPositionStream();
        return;
      }

      if (!await _hasLocationPermission()) return;
      if (_positionSubscription != null) return;

      final currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await _sendPosition(currentPosition);

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (position) => unawaited(_sendPosition(position)),
        onError: (Object error) {
          debugPrint('Error en seguimiento GPS: $error');
        },
      );
    } catch (error) {
      debugPrint('No se pudo iniciar el seguimiento GPS: $error');
    } finally {
      _checkingOrders = false;
    }
  }

  Future<bool> _hasLocationPermission() async {
    if (_permissionBlocked) return false;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('El servicio de ubicación está desactivado.');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _permissionBlocked = true;
      debugPrint('El permiso de ubicación no fue concedido.');
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<void> _sendPosition(Position position) async {
    if (!_running || ApiService.authToken == null) return;

    try {
      await ApiService.updateMyLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } catch (error) {
      // El siguiente cambio de posición volverá a intentar la sincronización.
      debugPrint('No se pudo sincronizar la ubicación: $error');
    }
  }

  Future<void> _stopPositionStream() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
