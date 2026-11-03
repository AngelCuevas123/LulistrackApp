import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/order_model.dart';
import '../services/api_service.dart';
import 'order_detail_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  static const Color primaryNavy = Color(0xFF1E3A8A);
  static const Color accentPink = Color(0xFFC23B75);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textGray = Color(0xFF64748B);

  late Future<List<OrderModel>> _futureOrders;

  @override
  void initState() {
    super.initState();
    _futureOrders = ApiService.getActiveOrders();
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _futureOrders = ApiService.getActiveOrders();
    });

    try {
      await _futureOrders;
    } catch (_) {
      // El FutureBuilder muestra el error en pantalla.
    }
  }

  Future<void> _openMap(
    double? latitude,
    double? longitude,
    String address,
  ) async {
    final Uri googleMapsUri;

    if (latitude != null && longitude != null) {
      googleMapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );
    } else {
      googleMapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
      );
    }

    try {
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(
          googleMapsUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir Google Maps'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al abrir el mapa'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: primaryNavy,
        elevation: 0,
        title: const Text(
          'Lista de Entregas (En Vivo)',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
            ),
            onPressed: _refreshOrders,
            tooltip: 'Actualizar lista',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        color: accentPink,
        child: FutureBuilder<List<OrderModel>>(
          future: _futureOrders,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
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
                  const SizedBox(height: 150),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: accentPink,
                          size: 45,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No se pudieron cargar las entregas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: primaryNavy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: textGray,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: _refreshOrders,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentPink,
                          ),
                          child: const Text(
                            'Intentar nuevamente',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final deliveries = snapshot.data ?? [];

            if (deliveries.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 150),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No hay entregas pendientes asignadas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: deliveries.length,
              itemBuilder: (context, index) {
                final item = deliveries[index];
                final bool isNext = index == 0;

                final String addressText =
                    '${item.address}, ${item.colony}';

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isNext
                          ? accentPink.withOpacity(0.5)
                          : cardBorder,
                      width: isNext ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.clientName.isNotEmpty
                                ? item.clientName
                                : 'Sin Cliente',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryNavy,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.estimatedTime,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textGray,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.trackingNumber.isNotEmpty ? item.trackingNumber : item.id} · $addressText',
                            style: const TextStyle(
                              color: textGray,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isNext
                                      ? accentPink.withOpacity(0.1)
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.status,
                                  style: TextStyle(
                                    color: isNext
                                        ? accentPink
                                        : textGray,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _openMap(
                                  item.latitude,
                                  item.longitude,
                                  addressText,
                                ),
                                icon: const Icon(
                                  Icons.map_rounded,
                                  size: 16,
                                  color: accentPink,
                                ),
                                label: const Text(
                                  'Ver Mapa',
                                  style: TextStyle(
                                    color: accentPink,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: primaryNavy,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailScreen(
                            orderData: item.toJson(),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}