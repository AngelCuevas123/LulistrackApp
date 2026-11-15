class OrderModel {
  final String id;
  final String trackingNumber;
  final String clientName;
  final String address;
  final String colony;
  final String estimatedTime;
  final String status;
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

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    double? parseCoordinate(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return OrderModel(
      id: json['id']?.toString() ?? '',
      trackingNumber: json['tracking_number']?.toString() ?? '',
      clientName: json['client_name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      colony: json['colony']?.toString() ?? '',
      estimatedTime: json['estimated_time']?.toString() ?? '',
      status: json['status']?.toString() ?? 'en_transito',
      latitude: parseCoordinate(json['latitude']),
      longitude: parseCoordinate(json['longitude']),
    );
  }

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
