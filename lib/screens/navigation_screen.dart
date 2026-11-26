import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../widgets/lulistrack_loading.dart';
import 'photo_evidence_screen.dart';

class NavigationScreen extends StatefulWidget {
  final OrderModel order;
  const NavigationScreen({super.key, required this.order});
  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  static const navy = Color(0xFF1E3A8A);
  static const pink = Color(0xFFC23B75);
  static const page = Color(0xFFF8FAFC);
  static const arrivalRadius = 60.0;
  GoogleMapController? _map;
  StreamSubscription<Position>? _gps;
  Position? _position;
  List<LatLng> _points = [];
  List<Map<String, dynamic>> _steps = [];
  double? _routeMeters, _routeMinutes, _destinationMeters;
  String _preference = 'recommended';
  bool _loading = true, _routeLoading = false, _openingProof = false;
  String? _error;
  DateTime? _lastRequest;
  LatLng? _lastOrigin;

  LatLng? get _destination {
    final lat = widget.order.latitude, lon = widget.order.longitude;
    if (lat == null || lon == null || lat.abs() > 90 || lon.abs() > 180) return null;
    return LatLng(lat, lon);
  }

  bool get _nearDestination => _destinationMeters != null &&
      _destinationMeters! <= arrivalRadius &&
      (_position?.accuracy ?? 999) <= 35;

  @override
  void initState() {
    super.initState();
    _startNavigation();
  }

  @override
  void dispose() {
    _gps?.cancel();
    _map?.dispose();
    super.dispose();
  }

  Future<void> _startNavigation() async {
    if (_destination == null) {
      setState(() {
        _loading = false;
        _error = 'Este pedido no tiene coordenadas de entrega. Solicita al administrador que confirme la ubicación.';
      });
      return;
    }
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Activa la ubicación del dispositivo para iniciar la navegación.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Necesitamos permiso de ubicación para guiarte al domicilio.');
      }
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
      );
      if (!mounted) return;
      _updatePosition(current);
      await _requestRoute(current);
      _gps = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 15),
      ).listen(_onPosition, onError: (Object e) => debugPrint('GPS navigation: ' + e.toString()));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _updatePosition(Position p) {
    if (_destination == null) return;
    setState(() {
      _position = p;
      _destinationMeters = Geolocator.distanceBetween(
        p.latitude, p.longitude, _destination!.latitude, _destination!.longitude,
      );
    });
  }

  void _onPosition(Position p) {
    if (!mounted) return;
    _updatePosition(p);
    final old = _lastOrigin;
    final moved = old == null || Geolocator.distanceBetween(
      old.latitude, old.longitude, p.latitude, p.longitude,
    ) >= 100;
    final stale = _lastRequest == null ||
        DateTime.now().difference(_lastRequest!) >= const Duration(minutes: 2);
    if (moved || stale) unawaited(_requestRoute(p));
  }

  Future<void> _requestRoute(Position origin) async {
    if (_routeLoading) return;
    setState(() { _routeLoading = true; _error = null; });
    try {
      final data = await ApiService.previewRoute(
        orderId: widget.order.id,
        originLatitude: origin.latitude,
        originLongitude: origin.longitude,
        preference: _preference,
      );
      final geometry = (data['geometry'] as List? ?? [])
          .whereType<List>().where((p) => p.length >= 2)
          .map((p) => LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble()))
          .toList();
      if (!mounted) return;
      setState(() {
        _points = geometry;
        _steps = (data['steps'] as List? ?? []).whereType<Map>()
            .map((s) => Map<String, dynamic>.from(s)).toList();
        _routeMeters = (data['distance_meters'] as num?)?.toDouble();
        _routeMinutes = (data['duration_minutes'] as num?)?.toDouble();
        _lastRequest = DateTime.now();
        _lastOrigin = LatLng(origin.latitude, origin.longitude);
      });
      if (geometry.isNotEmpty) _fitRoute(geometry);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _routeLoading = false);
    }
  }

  Future<void> _fitRoute(List<LatLng> points) async {
    if (_map == null || points.isEmpty) return;
    var minLat = points.first.latitude, maxLat = minLat;
    var minLon = points.first.longitude, maxLon = minLon;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude); maxLat = math.max(maxLat, p.latitude);
      minLon = math.min(minLon, p.longitude); maxLon = math.max(maxLon, p.longitude);
    }
    try {
      await _map!.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(minLat, minLon), northeast: LatLng(maxLat, maxLon)), 64,
      ));
    } catch (_) {}
  }

  Future<void> _selectPreference(String? value) async {
    if (value == null || value == _preference) return;
    setState(() => _preference = value);
    if (_position != null) await _requestRoute(_position!);
  }

  Future<void> _recenter() async {
    final p = _position;
    if (p == null) return;
    await _map?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(p.latitude, p.longitude), zoom: 17, tilt: 35,
    )));
  }

  String _distance(double? meters) {
    if (meters == null) return '--';
    return meters < 1000 ? meters.round().toString() + ' m' : (meters / 1000).toStringAsFixed(1) + ' km';
  }

  String get _instruction {
    if (_steps.isEmpty) return 'Sigue la ruta hacia el domicilio';
    for (final step in _steps) {
      final value = (step['instruction'] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return 'Continúa por la ruta';
  }

  Future<void> _confirmArrival() async {
    if (_openingProof) return;
    final far = _destinationMeters != null && _destinationMeters! > 120;
    final weakGps = (_position?.accuracy ?? 999) > 35;
    final message = far
        ? 'El GPS indica que todavía estás a ' + _distance(_destinationMeters) + ' del domicilio. ¿Confirmas que ya llegaste?'
        : weakGps
            ? 'La precisión del GPS es limitada. ¿Confirmas que estás en el domicilio?'
            : 'Al confirmar, abrirás el registro de fotografía y firma de la entrega.';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(far || weakGps ? 'Verifica tu llegada' : '¿Ya estás en el domicilio?'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Seguir navegando')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, ya llegué')),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() => _openingProof = true);
    await _gps?.cancel();
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => PhotoEvidenceScreen(
      orderId: widget.order.id,
      trackingNumber: widget.order.trackingNumber,
      clientName: widget.order.clientName,
      address: widget.order.address,
      colony: widget.order.colony,
    )));
    if (mounted) setState(() => _openingProof = false);
  }

  @override
  Widget build(BuildContext context) {
    final destination = _destination;
    final markers = <Marker>{
      if (_position != null) Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(_position!.latitude, _position!.longitude),
        infoWindow: const InfoWindow(title: 'Tu ubicación'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      if (destination != null) Marker(
        markerId: const MarkerId('destination'), position: destination,
        infoWindow: InfoWindow(title: widget.order.clientName, snippet: 'Destino de entrega'),
      ),
    };

    return Scaffold(
      backgroundColor: page,
      body: SafeArea(child: _loading
          ? const LulistrackLoading(title: 'Preparando navegación', subtitle: 'Obteniendo tu ubicación y trazando el recorrido.', icon: Icons.navigation_rounded)
          : Column(children: [
              Container(
                color: navy,
                padding: const EdgeInsets.fromLTRB(12, 8, 16, 14),
                child: Row(children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('NAVEGACIÓN ACTIVA', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
                    SizedBox(height: 3),
                    Text('Tu siguiente entrega', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ])),
                  const Icon(Icons.gps_fixed_rounded, color: Color(0xFF86EFAC)),
                  const SizedBox(width: 5),
                  const Text('GPS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ]),
              ),
              if (_error != null) Container(
                width: double.infinity, color: const Color(0xFFFFF7ED),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(_error!, style: const TextStyle(color: Color(0xFF9A3412), fontSize: 12)),
              ),
              Expanded(child: destination == null
                  ? const Center(child: Text('No hay coordenadas para mostrar el mapa.'))
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _position == null ? destination : LatLng(_position!.latitude, _position!.longitude),
                        zoom: 15,
                      ),
                      onMapCreated: (controller) { _map = controller; if (_points.isNotEmpty) _fitRoute(_points); },
                      myLocationEnabled: _position != null,
                      myLocationButtonEnabled: false,
                      compassEnabled: true,
                      mapToolbarEnabled: false,
                      markers: markers,
                      polylines: {
                        if (_points.length >= 2) Polyline(
                          polylineId: const PolylineId('route'), points: _points, color: navy, width: 6,
                        ),
                      },
                    )),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 15, 18, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 18, offset: Offset(0, -5))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.turn_right_rounded, color: navy, size: 25)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('SIGUIENTE INDICACIÓN', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: .7)),
                      const SizedBox(height: 3),
                      Text(_instruction, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 14)),
                    ])),
                    IconButton(onPressed: _recenter, tooltip: 'Centrar mi ubicación', icon: const Icon(Icons.my_location_rounded, color: navy)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    _Metric(label: 'RUTA', value: _distance(_routeMeters)),
                    const SizedBox(width: 24),
                    _Metric(label: 'TIEMPO EST.', value: _routeMinutes == null ? '--' : _routeMinutes!.round().toString() + ' min'),
                    const Spacer(),
                    if (_routeLoading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    else DropdownButton<String>(
                      value: _preference, underline: const SizedBox.shrink(),
                      borderRadius: BorderRadius.circular(12),
                      items: const [
                        DropdownMenuItem(value: 'recommended', child: Text('Recomendada')),
                        DropdownMenuItem(value: 'fastest', child: Text('Más rápida')),
                        DropdownMenuItem(value: 'shortest', child: Text('Más corta')),
                      ],
                      onChanged: _selectPreference,
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _nearDestination ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(children: [
                      Icon(_nearDestination ? Icons.location_on_rounded : Icons.flag_outlined,
                        color: _nearDestination ? const Color(0xFF15803D) : navy, size: 19),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        _nearDestination
                            ? 'Estás cerca del domicilio. Confirma cuando estés en el lugar.'
                            : 'Destino: ' + widget.order.address + (widget.order.colony.isEmpty ? '' : ', ' + widget.order.colony),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _nearDestination ? const Color(0xFF166534) : const Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w600),
                      )),
                      if (_destinationMeters != null) Text(_distance(_destinationMeters), style: const TextStyle(color: navy, fontSize: 11, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, height: 54, child: ElevatedButton.icon(
                    onPressed: _openingProof ? null : _confirmArrival,
                    icon: _openingProof
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                    label: Text(_openingProof ? 'Abriendo comprobante...' : 'Ya llegué al domicilio',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pink, disabledBackgroundColor: pink.withOpacity(.6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 2,
                    ),
                  )),
                ]),
              ),
            ])),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label, value;
  const _Metric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: .5)),
    const SizedBox(height: 3),
    Text(value, style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 17, fontWeight: FontWeight.bold)),
  ]);
}
