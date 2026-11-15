import 'dart:async';
import 'dart:ui';
import '../services/driver_location_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../services/offline_sync_service.dart';
import 'home_screen.dart';
import 'my_route_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'photo_evidence_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection =
          results.any((result) => result != ConnectivityResult.none);
      if (hasConnection) {
        unawaited(OfflineSyncService.instance.syncPendingDeliveries().then((_) {}));
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(OfflineSyncService.instance.syncPendingDeliveries().then((_) {}));
      unawaited(DriverLocationService.instance.start());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(DriverLocationService.instance.resume());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(DriverLocationService.instance.pause());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    unawaited(DriverLocationService.instance.stop());
    super.dispose();
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const MyRouteScreen(),
    const HistoryScreen(), // Corresponde al índice 2
    const ProfileScreen(),
  ];

  static const Color primaryNavy = Color(0xFF1E3A8A);
  static const Color accentPink = Color(0xFFC23B75);

  Future<void> _openEvidenceForOrder() async {
    try {
      final orders = await ApiService.getActiveOrders();

      if (!mounted) return;

      if (orders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes pedidos activos para registrar evidencia.'),
          ),
        );
        return;
      }

      final selectedOrder = await showModalBottomSheet<OrderModel>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona el pedido',
                  style: TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetContext).size.height * 0.55,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFEEF2FF),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        title: Text(
                          order.clientName.isEmpty
                              ? 'Cliente'
                              : order.clientName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          order.trackingNumber.isEmpty
                              ? order.id
                              : order.trackingNumber,
                        ),
                        onTap: () => Navigator.pop(sheetContext, order),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (selectedOrder == null || !mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PhotoEvidenceScreen(orderId: selectedOrder.id),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron consultar tus pedidos: ${error.toString()}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          alignment: Alignment.center,
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cápsula flotante central translúcida expandida y accesible
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      height: 72,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: primaryNavy.withOpacity(0.90),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(index: 0, icon: Icons.home_rounded, label: 'Inicio'),
                          _buildNavItem(index: 1, icon: Icons.inventory_2_rounded, label: 'Entregas'),
                          // Cambiado al icono y etiqueta de Historial para que coincida con HistoryScreen
                          _buildNavItem(index: 2, icon: Icons.history_rounded, label: 'Historial'),
                          _buildNavItem(index: 3, icon: Icons.person_rounded, label: 'Perfil'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Botón flotante independiente de la cámara
              GestureDetector(
                onTap: _openEvidenceForOrder,
                child: Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    color: accentPink,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentPink.withOpacity(0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required int index, required IconData icon, required String label}) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}