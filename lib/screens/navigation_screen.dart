import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
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

  final MapController _map = MapController();
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
  bool _mapReady = false;

  LatLng? get _destination {
    final lat = widget.order.latitude;
    final lon = widget.order.longitude;
    if (lat == null || lon == null || lat.abs() > 90 || lon.abs() > 180) {
      return null;
    }
    return LatLng(lat, lon);
  }

  bool get _nearDestination =>
      _destinationMeters != null &&
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
    _map.dispose();
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
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Necesitamos permiso de ubicación para guiarte al domicilio.');
      }

      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;

      _updatePosition(current);
      await _requestRoute(current);

      _gps = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        ),
      ).listen(
        _onPosition,
        onError: (Object e) => debugPrint('GPS navigation: $e'),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _updatePosition(Position p) {
    if (_destination == null) return;
    setState(() {
      _position = p;
      _destinationMeters = Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
        _destination!.latitude,
        _destination!.longitude,
      );
    });
  }

  void _onPosition(Position p) {
    if (!mounted) return;
    _updatePosition(p);

    final old = _lastOrigin;
    final moved = old == null ||
        Geolocator.distanceBetween(
              old.latitude,
              old.longitude,
              p.latitude,
              p.longitude,
            ) >=
            100;
    final stale = _lastRequest == null ||
        DateTime.now().difference(_lastRequest!) >= const Duration(minutes: 2);

    if (moved || stale) unawaited(_requestRoute(p));
  }

  Future<void> _requestRoute(Position origin) async {
    if (_routeLoading) return;
    setState(() {
      _routeLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.previewRoute(
        orderId: widget.order.id,
        originLatitude: origin.latitude,
        originLongitude: origin.longitude,
        preference: _preference,
      );

      // OpenRouteService returns GeoJSON coordinates as [longitude, latitude].
      final geometry = (data['geometry'] as List? ?? [])
          .whereType<List>()
          .where((point) => point.length >= 2)
          .map(
            (point) => LatLng(
              (point[1] as num).toDouble(),
              (point[0] as num).toDouble(),
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _points = geometry;
        _steps = (data['steps'] as List? ?? [])
            .whereType<Map>()
            .map((step) => Map<String, dynamic>.from(step))
            .toList();
        _routeMeters = (data['distance_meters'] as num?)?.toDouble();
        _routeMinutes = (data['duration_minutes'] as num?)?.toDouble();
        _lastRequest = DateTime.now();
        _lastOrigin = LatLng(origin.latitude, origin.longitude);
      });

      if (geometry.length >= 2 && _mapReady) _fitRoute(geometry);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _routeLoading = false);
    }
  }

  void _fitRoute(List<LatLng> points) {
    if (!_mapReady || points.length < 2) return;
    _map.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.fromLTRB(48, 72, 48, 72),
        maxZoom: 17,
      ),
    );
  }

  Future<void> _selectPreference(String? value) async {
    if (value == null || value == _preference) return;
    setState(() => _preference = value);
    if (_position != null) await _requestRoute(_position!);
  }

  void _recenter() {
    final p = _position;
    if (p == null || !_mapReady) return;
    _map.move(LatLng(p.latitude, p.longitude), 17);
  }

  String _distance(double? meters) {
    if (meters == null) return '--';
    return meters < 1000
        ? '${meters.round()} m'
        : '${(meters / 1000).toStringAsFixed(1)} km';
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
        ? 'El GPS indica que todavía estás a ${_distance(_destinationMeters)} del domicilio. ¿Confirmas que ya llegaste?'
        : weakGps
            ? 'La precisión del GPS es limitada. ¿Confirmas que estás en el domicilio?'
            : 'Al confirmar, abrirás el registro de fotografía y firma de la entrega.';

    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(far || weakGps ? 'Verifica tu llegada' : '¿Ya estás en el domicilio?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir navegando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, ya llegué'),
          ),
        ],
      ),
    );

    if (accepted != true || !mounted) return;
    setState(() => _openingProof = true);
    await _gps?.cancel();
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoEvidenceScreen(
          orderId: widget.order.id,
          trackingNumber: widget.order.trackingNumber,
          clientName: widget.order.clientName,
          address: widget.order.address,
          colony: widget.order.colony,
        ),
      ),
    );

    if (mounted) setState(() => _openingProof = false);
  }

  Widget _buildMap() {
    final destination = _destination;
    final currentPoint = _position == null
        ? null
        : LatLng(_position!.latitude, _position!.longitude);

    if (destination == null) {
      return const Center(child: Text('No hay coordenadas para mostrar el mapa.'));
    }

    final markers = <Marker>[
      if (currentPoint != null)
        Marker(
          point: currentPoint,
          width: 52,
          height: 58,
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2563EB), width: 3),
              boxShadow: const [
                BoxShadow(color: Color(0x26000000), blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: const Icon(Icons.delivery_dining_rounded, color: Color(0xFF2563EB), size: 30),
          ),
        ),
      Marker(
        point: destination,
        width: 52,
        height: 58,
        alignment: Alignment.bottomCenter,
        child: const Icon(Icons.location_pin, color: pink, size: 48),
      ),
    ];

    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: currentPoint ?? destination,
        initialZoom: 15,
        maxZoom: 19,
        onMapReady: () {
          _mapReady = true;
          if (_points.length >= 2) _fitRoute(_points);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.juanangelcuevas.lulistrack',
          maxNativeZoom: 19,
          errorTileCallback: (tile, error, stackTrace) {
            debugPrint('OpenStreetMap tile error: $error');
          },
        ),
        if (_points.length >= 2)
          PolylineLayer(
            polylines: [
              // Halo exterior para dar profundidad visual a la ruta.
              Polyline(
                points: _points,
                color: const Color(0x553B82F6),
                strokeWidth: 13,
              ),
              Polyline(
                points: _points,
                color: const Color(0xFF2563EB),
                strokeWidth: 6,
              ),
              Polyline(
                points: _points,
                color: const Color(0xFFEFF6FF),
                strokeWidth: 1.4,
              ),
            ],
          ),
        MarkerLayer(markers: markers),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              '© OpenStreetMap contributors',
              onTap: () {
                launchUrl(Uri.parse('https://www.openstreetmap.org/copyright'));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _glassPanel({required Widget child, EdgeInsets padding = const EdgeInsets.all(14)}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.88),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(.85), width: 1.2),
            boxShadow: const [
              BoxShadow(color: Color(0x260F172A), blurRadius: 24, offset: Offset(0, 10)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _roundMapButton({required IconData icon, required VoidCallback onTap, String? tooltip}) {
    return Material(
      color: Colors.white.withOpacity(.94),
      shape: const CircleBorder(),
      elevation: 5,
      shadowColor: const Color(0x330F172A),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: navy, size: 22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF7),
      body: _loading
          ? const SafeArea(
              child: LulistrackLoading(
                title: 'Preparando navegación',
                subtitle: 'Obteniendo tu ubicación y trazando el recorrido.',
                icon: Icons.navigation_rounded,
              ),
            )
          : Stack(
              children: [
                Positioned.fill(child: _buildMap()),
                // Degradado superior para separar visualmente los controles del mapa.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 190,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [const Color(0xB30B1738), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: _glassPanel(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                          child: Row(
                            children: [
                              Material(
                                color: navy,
                                borderRadius: BorderRadius.circular(16),
                                child: IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'LULISTRACK NAV',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 9,
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Entrega en camino',
                                      style: TextStyle(
                                        color: Color(0xFF142B62),
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.gps_fixed_rounded, color: Color(0xFF15803D), size: 14),
                                    SizedBox(width: 5),
                                    Text(
                                      'GPS',
                                      style: TextStyle(
                                        color: Color(0xFF166534),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: _glassPanel(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: Color(0xFF92400E), fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(right: 16, bottom: 14),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _roundMapButton(
                                icon: Icons.my_location_rounded,
                                onTap: _recenter,
                                tooltip: 'Centrar mi ubicación',
                              ),
                              const SizedBox(height: 10),
                              _roundMapButton(
                                icon: Icons.route_rounded,
                                onTap: () {
                                  if (_position != null) _fitRoute(_points);
                                },
                                tooltip: 'Ver ruta completa',
                              ),
                            ],
                          ),
                        ),
                      ),
                      _glassPanel(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF3156B8), Color(0xFF172D70)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(color: Color(0x44315AB8), blurRadius: 12, offset: Offset(0, 5)),
                                    ],
                                  ),
                                  child: const Icon(Icons.turn_right_rounded, color: Colors.white, size: 27),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'SIGUIENTE MANIOBRA',
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 9,
                                          letterSpacing: 1,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _instruction,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF172D70),
                                          fontSize: 14,
                                          height: 1.2,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_routeLoading)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2.3, color: Color(0xFF3156B8)),
                                  )
                                else
                                  const Icon(Icons.navigation_rounded, color: Color(0xFF3156B8), size: 22),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 13),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5FF),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFE1E9FF)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: _Metric(label: 'DISTANCIA TOTAL', value: _distance(_routeMeters))),
                                  Container(width: 1, height: 34, color: const Color(0xFFD8E1F2)),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _Metric(
                                      label: 'TIEMPO ESTIMADO',
                                      value: _routeMinutes == null ? '--' : '${_routeMinutes!.round()} min',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    tooltip: 'Preferencia de ruta',
                                    initialValue: _preference,
                                    onSelected: _selectPreference,
                                    icon: const Icon(Icons.tune_rounded, color: Color(0xFF3156B8)),
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'recommended', child: Text('Recomendada')),
                                      PopupMenuItem(value: 'fastest', child: Text('Más rápida')),
                                      PopupMenuItem(value: 'shortest', child: Text('Más corta')),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 11),
                            Row(
                              children: [
                                Icon(
                                  _nearDestination ? Icons.near_me_rounded : Icons.location_on_rounded,
                                  color: _nearDestination ? const Color(0xFF15803D) : const Color(0xFFC23B75),
                                  size: 18,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    _nearDestination
                                        ? '¡Ya estás cerca! Confirma al llegar al domicilio.'
                                        : '${widget.order.address}${widget.order.colony.isEmpty ? '' : ', ${widget.order.colony}'}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF475569),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (_destinationMeters != null)
                                  Text(
                                    _distance(_destinationMeters),
                                    style: const TextStyle(
                                      color: Color(0xFF172D70),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 13),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFD64B83), Color(0xFFB72F6C)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(17),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x33C23B75), blurRadius: 14, offset: Offset(0, 6)),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _openingProof ? null : _confirmArrival,
                                  icon: _openingProof
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Icon(Icons.check_circle_rounded, color: Colors.white),
                                  label: Text(
                                    _openingProof ? 'Abriendo comprobante...' : 'Ya llegué al domicilio',
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    disabledBackgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      );
}
