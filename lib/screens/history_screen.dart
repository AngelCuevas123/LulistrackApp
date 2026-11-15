
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../services/offline_database.dart';
import 'order_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // El historial usa la misma URL configurable que el resto de los servicios.

  // Colores de Lulistrack
  static const Color primaryNavy = Color(0xFF1E3A8A);
  static const Color accentPink = Color(0xFFC23B75);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textGray = Color(0xFF64748B);

  late Future<List<Map<String, dynamic>>> futureHistory;

  @override
  void initState() {
    super.initState();
    futureHistory = fetchHistory();
  }

  // Actualizar historial
  Future<void> refreshHistory() async {
    setState(() {
      futureHistory = fetchHistory();
    });

    try {
      await futureHistory;
    } catch (_) {
      // El FutureBuilder muestra el error en pantalla.
    }
  }

  // Consulta el historial y conserva la última respuesta válida en SQLite.
  Future<List<Map<String, dynamic>>> fetchHistory() async {
    final token = ApiService.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('No hay una sesión activa. Inicia sesión nuevamente.');
    }
    final cached = await OfflineDatabase.instance.getCachedCompletedOrders();

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/orders/my/completed'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<Map<String, dynamic>> orders;
        if (decoded is List) {
          orders = decoded.whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item)).toList();
        } else if (decoded is Map && decoded['data'] is List) {
          orders = (decoded['data'] as List).whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item)).toList();
        } else {
          orders = [];
        }
        await OfflineDatabase.instance.cacheCompletedOrders(orders);
        return orders;
      }
      if (response.statusCode == 401) {
        throw Exception('Tu sesión ha expirado. Inicia sesión nuevamente.');
      }
      if (response.statusCode == 403) {
        throw Exception('Tu cuenta no tiene un perfil de repartidor autorizado.');
      }
      if (response.statusCode >= 500) return cached;
      throw Exception('Error ${response.statusCode}: ${response.body}');
    } catch (error) {
      final message = error.toString();
      if (message.contains('sesión ha expirado') ||
          message.contains('perfil de repartidor autorizado') ||
          message.contains('Error 4')) {
        rethrow;
      }
      return cached;
    }
  }

  // Obtener texto seguro desde el JSON
  String readText(Map<String, dynamic> item, String key) {
    final value = item[key];
    return value?.toString() ?? '';
  }

  // Construir dirección
  String getAddress(Map<String, dynamic> item) {
    final address = readText(item, 'address');
    final colony = readText(item, 'colony');

    if (address.isEmpty) return colony;
    if (colony.isEmpty) return address;

    return '$address, $colony';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Cabecera
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              decoration: const BoxDecoration(
                color: primaryNavy,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Historial',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Entregas realizadas y verificadas',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                    ),
                    onPressed: refreshHistory,
                    tooltip: 'Actualizar historial',
                  ),
                ],
              ),
            ),

            // Lista de entregas
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: futureHistory,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: accentPink,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 55,
                          color: textGray,
                        ),
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Error al cargar el historial:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: textGray,
                            ),
                          ),
                        ),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: refreshHistory,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryNavy,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final historyList = snapshot.data ?? [];

                  if (historyList.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 55,
                          color: textGray,
                        ),
                        SizedBox(height: 15),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Aún no hay entregas registradas en tu historial.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: textGray),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: refreshHistory,
                    color: accentPink,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      itemCount: historyList.length,
                      itemBuilder: (context, index) {
                        final item = historyList[index];

                        final clientName =
                            readText(item, 'client_name').isEmpty
                                ? 'Cliente'
                                : readText(item, 'client_name');

                        final trackingNumber =
                            readText(item, 'tracking_number').isEmpty
                                ? readText(item, 'id')
                                : readText(item, 'tracking_number');

                        final address = getAddress(item);

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderDetailScreen(
                                  orderData: item,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: cardBorder,
                                width: 1,
                              ),
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
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            clientName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: primaryNavy,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            trackingNumber,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: textGray,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Entregado',
                                        style: TextStyle(
                                          color: Color(0xFF15803D),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: textGray,
                                      size: 20,
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(
                                    height: 1,
                                    color: Color(0xFFF1F5F9),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: textGray,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        address.isEmpty
                                            ? 'Dirección no disponible'
                                            : address,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: textGray,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

