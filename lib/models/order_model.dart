class OrderModel {
  final String id;
  final String trackingNumber;
  final String clientName;
  final String address;
  final String colony;
  final String estimatedTime;
  final String status; // 'en_transito', 'entregado', 'cancelado'
  final double? latitude;
  final double? longitude;

  OrderModel({
    required this.id,
    required this.trackingNumber,
    required this.clientName,
    required this.address,
    required this.colony,
    required this.estimatedTime,
    required this.status,
    this.latitude,
    this.longitude,
  });

  // Constructor para convertir JSON (cuando te conectes a tu API de FastAPI)
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      trackingNumber: json['tracking_number'] ?? '',
      clientName: json['client_name'] ?? '',
      address: json['address'] ?? '',
      colony: json['colony'] ?? '',
      estimatedTime: json['estimated_time'] ?? '',
      status: json['status'] ?? 'en_transito',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  // Convertir a JSON para enviar datos al backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tracking_number': trackingNumber,
      'client_name': clientName,
      'address': address,
      'colony': colony,
      'estimated_time': estimatedTime,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
