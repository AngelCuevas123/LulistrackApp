
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../models/user_model.dart';
import 'offline_database.dart';

class DeliverySubmissionException implements Exception {
  final int statusCode;
  final String responseBody;
  const DeliverySubmissionException(this.statusCode, this.responseBody);
  @override
  String toString() => 'El servidor rechazó la entrega ($statusCode).';
}

class ApiService {
  // Dirección del backend configurada en .env.
  static String get baseUrl => dotenv.env['API_BASE_URL']!;

  // Token de autenticación de Supabase.
  static String? authToken;

  // Perfil del repartidor autenticado.
  static UserModel? currentDriver;

  // Registra el Firebase Installation ID del dispositivo.
  static Future<bool> registerFirebaseInstallationId({
    required String firebaseInstallationId,
    required String platform,
  }) async {
    if (authToken == null || authToken!.isEmpty) {
      throw Exception(
        'No hay una sesión activa para registrar el dispositivo.',
      );
    }

    final response = await http.post(
      Uri.parse('$baseUrl/drivers/me/fcm-token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: json.encode({
        'firebase_installation_id': firebaseInstallationId,
        'platform': platform,
      }),
    ).timeout(const Duration(seconds: 30));

    print('Registro FID: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }

    throw Exception(
      'No se pudo registrar el dispositivo: '
          '${response.statusCode} - ${response.body}',
    );
  }

  // Desactiva el Firebase Installation ID al cerrar sesión.
  static Future<bool> unregisterFirebaseInstallationId(
      String firebaseInstallationId,
      ) async {
    if (authToken == null || authToken!.isEmpty) {
      return false;
    }

    final uri = Uri.parse('$baseUrl/drivers/me/fcm-token')
        .replace(queryParameters: {
      'firebase_installation_id': firebaseInstallationId,
    });

    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $authToken',
      },
    ).timeout(const Duration(seconds: 30));

    print('Desregistro FID: ${response.statusCode}');

    return response.statusCode == 200 ||
        response.statusCode == 204;
  }

  // Consulta los pedidos asignados al repartidor.
  static Future<List<OrderModel>> getActiveOrders() async {
    late http.Response response;

    try {
      response = await http.get(
        Uri.parse('$baseUrl/orders/my'),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 45));
    } catch (_) {
      final cached = await OfflineDatabase.instance
          .getCachedOrders(group: 'active');

      return cached;
    }

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      final orders = data
          .map((model) => OrderModel.fromJson(model))
          .toList();

      await OfflineDatabase.instance.cacheOrders(
        orders,
        group: 'active',
      );

      return orders;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception(
        'No tienes autorización para consultar tus pedidos '
            '(${response.statusCode}).',
      );
    }

    final cached = await OfflineDatabase.instance
        .getCachedOrders(group: 'active');

    if (response.statusCode >= 500) {
      return cached;
    }

    throw Exception(
      'Error al cargar mis pedidos: '
          '${response.statusCode} - ${response.body}',
    );
  }

  // Consulta pedidos disponibles y conserva la última respuesta sin conexión.
  static Future<List<OrderModel>> getAvailableOrders() async {
    late http.Response response;

    try {
      response = await http.get(
        Uri.parse('$baseUrl/orders/available'),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 45));
    } catch (_) {
      final cached = await OfflineDatabase.instance
          .getCachedOrders(group: 'available');

      return cached;
    }

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      final orders = data
          .map((order) => OrderModel.fromJson(order))
          .toList();

      await OfflineDatabase.instance.cacheOrders(
        orders,
        group: 'available',
      );

      return orders;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception(
        'No tienes autorización para consultar pedidos disponibles '
            '(${response.statusCode}).',
      );
    }

    final cached = await OfflineDatabase.instance
        .getCachedOrders(group: 'available');

    if (response.statusCode >= 500) {
      return cached;
    }

    throw Exception(
      'Error al obtener pedidos disponibles: '
          '${response.statusCode} - ${response.body}',
    );
  }

  // Permite al repartidor tomar un pedido disponible.
  static Future<OrderModel> claimOrder(String orderId) async {
    final cleanId = orderId.replaceAll('#', '').trim();

    final response = await http.post(
      Uri.parse(
        '$baseUrl/orders/${Uri.encodeComponent(cleanId)}/claim',
      ),
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null)
          'Authorization': 'Bearer $authToken',
      },
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      return OrderModel.fromJson(json.decode(response.body));
    }

    if (response.statusCode == 409) {
      throw Exception(
        'Este pedido ya fue tomado por otro repartidor.',
      );
    }

    throw Exception(
      'No se pudo tomar el pedido: '
          '${response.statusCode} - ${response.body}',
    );
  }

  // Los errores de red se propagan; los HTTP conservan su código para clasificarlos.
  static Future<bool> submitProofOfDelivery({
    required String orderId,
    required String photoBase64,
    required String signatureBase64,
  }) async {
    final cleanId = orderId.replaceAll('#', '').trim();
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$cleanId/complete'),
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
      body: json.encode({
        'photo_base64': photoBase64,
        'signature_base64': signatureBase64,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    ).timeout(const Duration(seconds: 90));
    print('Respuesta de FastAPI: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }
    throw DeliverySubmissionException(response.statusCode, response.body);
  }

  // Recupera el perfil del repartidor autenticado.
  static Future<UserModel> getMyDriverProfile({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && currentDriver != null) {
      return currentDriver!;
    }

    if (authToken == null || authToken!.isEmpty) {
      throw Exception(
        'No hay una sesión activa. Inicia sesión nuevamente.',
      );
    }

    final response = await http.get(
      Uri.parse('$baseUrl/drivers/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'El servidor devolvió un perfil inválido.',
        );
      }

      final profile = UserModel.fromJson(decoded);

      if (profile.driverId.isEmpty || profile.name.trim().isEmpty) {
        throw Exception(
          'El perfil del repartidor está incompleto.',
        );
      }

      currentDriver = profile;
      return profile;
    }

    if (response.statusCode == 404) {
      throw Exception(
        'Esta cuenta no tiene un perfil de repartidor asociado. '
            'Contacta al administrador.',
      );
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Tu sesión ha expirado. Inicia sesión nuevamente.',
      );
    }

    throw Exception(
      'No se pudo cargar el perfil del repartidor '
          '(${response.statusCode}).',
    );
  }

  // Consulta la información de un repartidor.
  static Future<UserModel?> getDriverProfile(
      String driverId,
      ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/drivers/$driverId'),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null)
            'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return UserModel.fromJson(
          json.decode(response.body),
        );
      }

      print('Error al obtener perfil: ${response.body}');
      return null;
    } catch (e) {
      print('Error al obtener perfil: $e');
      return null;
    }
  }
}
