import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../services/haptic_service.dart';
import '../services/voice_assistant_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_detail_screen.dart';
import '../widgets/lulistrack_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryNavy = Color(0xFF1E3A8A);
  static const Color accentPink = Color(0xFFC23B75);
  static const Color statusYellow = Color(0xFFFEF08A);
  static const Color statusYellowText = Color(0xFF854D0E);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textGray = Color(0xFF64748B);

  late Future<List<List<OrderModel>>> _futureOrders;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _lastActiveOrderCount;
  int? _lastAvailableOrderCount;

  @override
  void initState() {
    super.initState();
    _futureOrders = _loadOrders();
    _futureOrders.then((orders) {
      _lastActiveOrderCount = orders[0].length;
      _lastAvailableOrderCount = orders[1].length;
    }).catchError((_) {});
  }

  Future<List<List<OrderModel>>> _loadOrders() {
    return Future.wait<List<OrderModel>>([
      ApiService.getActiveOrders(),
      ApiService.getAvailableOrders(),
    ]);
  }

  Future<void> _refreshOrders() async {
    final future = _loadOrders();
    setState(() {
      _futureOrders = future;
    });
    try {
      final orders = await future;
      final activeCount = orders[0].length;
      final availableCount = orders[1].length;

      if (_lastActiveOrderCount != null &&
          activeCount > _lastActiveOrderCount!) {
        await HapticService.success();
      } else if (_lastAvailableOrderCount != null &&
          availableCount > _lastAvailableOrderCount!) {
        await HapticService.light();
      }

      _lastActiveOrderCount = activeCount;
      _lastAvailableOrderCount = availableCount;
    } catch (_) {
      // El FutureBuilder mostrara el error en pantalla.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_transito':
      case 'en tránsito':
        return 'En Tránsito';
      case 'entregado':
        return 'Entregado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return status.isEmpty ? 'Sin estado' : status;
    }
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    if (_searchQuery.trim().isEmpty) return orders;
    final query = _searchQuery.toLowerCase().trim();
    return orders.where((order) {
      return order.clientName.toLowerCase().contains(query) ||
          order.trackingNumber.toLowerCase().contains(query) ||
          order.address.toLowerCase().contains(query) ||
          order.colony.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _claimOrder(OrderModel order) async {
    try {
      await ApiService.claimOrder(order.id);
      await HapticService.success();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Pedido asignado correctamente!'),
          backgroundColor: Colors.green,
        ),
      );
      await _refreshOrders();
    } catch (e) {
      await HapticService.error();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
      await _refreshOrders();
    }
  }

  Future<void> _openOrderDetail(OrderModel order) async {
    final Map<String, dynamic> orderMap = {
      'id': order.id,
      'tracking_number': order.trackingNumber,
      'client_name': order.clientName,
      'address': order.address,
      'colony': order.colony,
      'estimated_time': order.estimatedTime,
      'status': order.status,
      'latitude': order.latitude,
      'longitude': order.longitude,
    };

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OrderDetailScreen(orderData: orderMap)),
    );
    if (mounted) await _refreshOrders();
  }

  Future<void> _activateVoiceAssistant() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('immersive_voice_assistant_enabled') ?? false;
    if (!enabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activa el asistente en Perfil > Experiencia inmersiva.')),
      );
      return;
    }
    final started = await VoiceAssistantService.instance.startListening(
      onCommand: _handleVoiceCommand,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(started
            ? 'Te escucho. Di “cuántos pedidos tengo”, “siguiente pedido” o “repetir información”.'
            : 'No se pudo iniciar el micrófono. Revisa el permiso de audio.'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleVoiceCommand(String command) async {
    final normalized = command.toLowerCase();
    try {
      if (normalized.contains('cuántos') ||
          normalized.contains('cuantos') ||
          normalized.contains('mis pedidos') ||
          normalized.contains('pedidos tengo')) {
        final results = await _loadOrders();
        await VoiceAssistantService.instance.speak(
          'Tienes ' + results[0].length.toString() +
          ' pedidos activos y ' + results[1].length.toString() +
          ' pedidos disponibles.',
        );
        return;
      }
      if (normalized.contains('siguiente') ||
          normalized.contains('abrir pedido') ||
          normalized.contains('ver pedido')) {
        final orders = await ApiService.getActiveOrders();
        if (orders.isEmpty) {
          await VoiceAssistantService.instance.speak('No tienes pedidos activos por ahora.');
          return;
        }
        final order = orders.first;
        await VoiceAssistantService.instance.speak(
          'Abriendo el pedido ' + order.trackingNumber + ', de ' + order.clientName + '.',
        );
        if (!mounted) return;
        await _openOrderDetail(order);
        return;
      }
      if (normalized.contains('repetir') ||
          normalized.contains('información') ||
          normalized.contains('informacion')) {
        final orders = await ApiService.getActiveOrders();
        if (orders.isEmpty) {
          await VoiceAssistantService.instance.speak('No hay información de pedidos activos para repetir.');
        } else {
          final order = orders.first;
          await VoiceAssistantService.instance.speak(
            'Tu primer pedido activo es ' + order.trackingNumber +
            ', cliente ' + order.clientName + '. Dirección: ' +
            order.address + ', colonia ' + order.colony + '.',
          );
        }
        return;
      }
      await VoiceAssistantService.instance.speak(
        'No reconocí ese comando. Puedes preguntar cuántos pedidos tienes, abrir el siguiente pedido o repetir la información.',
      );
    } catch (_) {
      await VoiceAssistantService.instance.speak(
        'No pude consultar tus pedidos. Intenta de nuevo cuando tengas conexión.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshOrders,
          color: accentPink,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: const BoxDecoration(
                  color: primaryNavy,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: Text(
                                ApiService.currentDriver?.initials ?? 'R',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hola, Conductor',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ApiService.currentDriver?.name ?? 'Repartidor',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: const InputDecoration(
                          hintText: 'Buscar ID de paquete o cliente',
                          hintStyle: TextStyle(color: textGray, fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: textGray),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<List<OrderModel>>>(
                  future: _futureOrders,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LulistrackLoading(
                        title: 'Cargando tus entregas',
                        subtitle: 'Estamos organizando pedidos y rutas disponibles.',
                        icon: Icons.local_shipping_rounded,
                      );
                    }
                    if (snapshot.hasError) {
                      return ListView(
                        children: [
                          const SizedBox(height: 100),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  const Icon(Icons.cloud_off_outlined, size: 45, color: textGray),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Error al cargar pedidos:\n${snapshot.error}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(onPressed: _refreshOrders, child: const Text('Reintentar')),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    final orders = snapshot.data?[0] ?? [];
                    final availableOrders = snapshot.data?[1] ?? [];
                    final filteredOrders = _filterOrders(orders);
                    final filteredAvailable = _filterOrders(availableOrders);

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tus entregas',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryNavy),
                            ),
                            Text(
                              '${orders.length} ACTIVAS',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textGray),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: primaryNavy,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Activas ${orders.length}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (filteredOrders.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(25),
                            child: Center(
                              child: Text(
                                'No tienes entregas asignadas.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: textGray),
                              ),
                            ),
                          )
                        else
                          ...filteredOrders.map(
                            (order) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildDeliveryCard(order: order, isAvailable: false),
                            ),
                          ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Pedidos disponibles',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryNavy),
                            ),
                            Text(
                              '${availableOrders.length} NUEVOS',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textGray),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (filteredAvailable.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(25),
                            child: Center(
                              child: Text(
                                'No hay pedidos disponibles por el momento.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: textGray),
                              ),
                            ),
                          )
                        else
                          ...filteredAvailable.map(
                            (order) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildDeliveryCard(order: order, isAvailable: true),
                            ),
                          ),
                        const SizedBox(height: 100),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.small(
              heroTag: 'lulistrack_voice_assistant',
              onPressed: _activateVoiceAssistant,
              backgroundColor: primaryNavy,
              foregroundColor: Colors.white,
              tooltip: 'Asistente de voz',
              child: const Icon(Icons.mic_rounded),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'lulistrack_refresh_orders',
              onPressed: _refreshOrders,
              backgroundColor: accentPink,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              label: const Text(
                'Actualizar Pedidos',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildDeliveryCard({
    required OrderModel order,
    required bool isAvailable,
  }) {
    final statusLabel = _getStatusLabel(order.status);
    return InkWell(
      onTap: () => _openOrderDetail(order),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.clientName.isEmpty ? 'Cliente no disponible' : order.clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.trackingNumber,
                        style: const TextStyle(fontSize: 12, color: textGray, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: statusYellow, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(color: statusYellowText, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: textGray),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.address.isEmpty ? 'Dirección no disponible' : order.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primaryNavy),
                      ),
                      if (order.colony.isNotEmpty)
                        Text(order.colony, style: const TextStyle(fontSize: 11, color: textGray)),
                    ],
                  ),
                ),
                if (order.estimatedTime.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    order.estimatedTime,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryNavy),
                  ),
                ],
                const Icon(Icons.chevron_right, size: 18, color: textGray),
              ],
            ),
            if (isAvailable) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _claimOrder(order),
                  icon: const Icon(Icons.add_task_rounded, size: 18),
                  label: const Text('Tomar pedido'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentPink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
