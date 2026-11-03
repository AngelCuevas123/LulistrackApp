
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../models/user_model.dart';

class ApiService {
  // Tomo la direccion del backend desde .env para poder cambiar de entorno sin editar el codigo.
  static String get baseUrl => dotenv.env['API_BASE_URL']!;

  // Guardo el token de la sesion para identificar mis solicitudes ante el backend.
  static String? authToken;

  // Aqui consulto los pedidos que tiene asignados el repartidor.
  static Future<List<OrderModel>> getActiveOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/my'),
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null)
          'Authorization': 'Bearer $authToken',
      },
    ).timeout(const Duration(seconds: 45));

    print('Respuesta de pedidos: ${response.statusCode}');
    print('Detalle: ${response.body}');

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);

      return data
          .map((model) => OrderModel.fromJson(model))
          .toList();
    }

    throw Exception(
      'Error al cargar mis pedidos: ${response.statusCode} - ${response.body}',
    );
  }

  // Aqui recupero los pedidos que todavia puede aceptar el repartidor.
  static Future<List<OrderModel>> getAvailableOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/available'),
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null)
          'Authorization': 'Bearer $authToken',
      },
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);

      return data
          .map((order) => OrderModel.fromJson(order))
          .toList();
    }

    throw Exception(
      'Error al obtener pedidos disponibles: ${response.statusCode} - ${response.body}',
    );
  }

  // Aqui envio la solicitud para que el repartidor tome un pedido disponible.
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
      'No se pudo tomar el pedido: ${response.statusCode} - ${response.body}',
    );
  }

  // Aqui envio la fotografia y la firma para dejar registrado el comprobante de entrega.
  static Future<bool> submitProofOfDelivery({
    required String orderId,
    required String photoBase64,
    required String signatureBase64,
  }) async {
    try {
      final String cleanId = orderId.replaceAll('#', '').trim();

      final response = await http.post(
        Uri.parse('$baseUrl/orders/$cleanId/complete'),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null)
            'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'photo_base64': photoBase64,
          'signature_base64': signatureBase64,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 90));

      print('Respuesta de FastAPI: ${response.statusCode}');
      print('Detalle: ${response.body}');

      return response.statusCode == 200 ||
          response.statusCode == 201;
    } catch (e) {
      print('Error al enviar evidencia: $e');
      return false;
    }
  }

  // Aqui consulto la informacion del perfil del repartidor.
  static Future<UserModel?> getDriverProfile(
      String driverId) async {
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

