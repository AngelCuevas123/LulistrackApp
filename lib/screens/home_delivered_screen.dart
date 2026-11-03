
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';

class HomeDeliveredScreen extends StatefulWidget {
  const HomeDeliveredScreen({super.key});

  @override
  State<HomeDeliveredScreen> createState() =>
      _HomeDeliveredScreenState();
}

class _HomeDeliveredScreenState extends State<HomeDeliveredScreen> {
  // Colores de Lulistrack
  static const Color primaryNavy = Color(0xFF1E3A8A);
  static const Color accentPink = Color(0xFFC23B75);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textGray = Color(0xFF64748B);

  List<OrderModel> orders = [];

  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  // Consultar pedidos del repartidor
  Future<void> loadOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getActiveOrders();

      if (!mounted) return;

      setState(() {
        orders = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // Buscador
  List<OrderModel> get filteredOrders {
    if (searchQuery.trim().isEmpty) {
      return orders;
    }

    final query = searchQuery.toLowerCase();

    return orders.where((order) {
      return order.clientName.toLowerCase().contains(query) ||
          order.trackingNumber.toLowerCase().contains(query) ||
          order.address.toLowerCase().contains(query) ||
          order.colony.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCounters(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: loadOrders,
        backgroundColor: accentPink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text(
          'Actualizar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Encabezado
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryNavy,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lulistrack',
                  style: TextStyle(
                    color: primaryNavy,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Mis pedidos asignados',
                  style: TextStyle(
                    color: textGray,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: loadOrders,
            icon: const Icon(
              Icons.refresh,
              color: primaryNavy,
            ),
          ),
        ],
      ),
    );
  }

  // Buscador
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Buscar pedido...',
          hintStyle: const TextStyle(color: textGray),
          prefixIcon: const Icon(
            Icons.search,
            color: textGray,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: primaryNavy),
          ),
        ),
      ),
    );
  }

  // Contadores
  Widget _buildCounters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: _buildCounterCard(
              'Pedidos asignados',
              orders.length.toString(),
              Icons.inventory_2_rounded,
              const Color(0xFFDBEAFE),
              primaryNavy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCounterCard(
              'Entregados',
              '—',
              Icons.check_circle_rounded,
              const Color(0xFFDCFCE7),
              const Color(0xFF166534),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterCard(
    String title,
    String value,
    IconData icon,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: foreground,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: primaryNavy,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: textGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Contenido
  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryNavy,
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 55,
                color: textGray,
              ),
              const SizedBox(height: 15),
              const Text(
                'No se pudieron cargar los pedidos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: primaryNavy,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: textGray),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: loadOrders,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryNavy,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 65,
              color: textGray,
            ),
            const SizedBox(height: 15),
            Text(
              searchQuery.isEmpty
                  ? 'No tienes pedidos asignados'
                  : 'No se encontraron resultados',
              style: const TextStyle(
                color: primaryNavy,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadOrders,
      color: primaryNavy,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(filteredOrders[index]);
        },
      ),
    );
  }

  // Tarjeta de pedido
  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.clientName.isEmpty
                      ? 'Cliente sin nombre'
                      : order.clientName,
                  style: const TextStyle(
                    color: primaryNavy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _buildStatus(order.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Tracking: ${order.trackingNumber}',
            style: const TextStyle(
              color: textGray,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: accentPink,
                size: 19,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  [
                    order.address,
                    order.colony,
                  ].where((value) => value.isNotEmpty).join(', '),
                  style: const TextStyle(
                    color: textGray,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (order.estimatedTime.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: textGray,
                  size: 17,
                ),
                const SizedBox(width: 7),
                Text(
                  order.estimatedTime,
                  style: const TextStyle(
                    color: textGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Estado del pedido
  Widget _buildStatus(String status) {
    final delivered = status.toLowerCase() == 'entregado';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: delivered
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        delivered ? 'ENTREGADA' : 'EN PROCESO',
        style: TextStyle(
          color: delivered
              ? const Color(0xFF166534)
              : const Color(0xFF854D0E),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
