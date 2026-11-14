class UserModel {
  final String driverId;
  final String name;
  final String vehicle;
  final int completedDeliveries;
  final String averageTime;

  UserModel({
    required this.driverId,
    required this.name,
    required this.vehicle,
    required this.completedDeliveries,
    required this.averageTime,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final deliveriesValue = json['completed_deliveries'];

    return UserModel(
      driverId: json['driver_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      vehicle: json['vehicle']?.toString() ?? '',
      completedDeliveries: deliveriesValue is num
          ? deliveriesValue.toInt()
          : int.tryParse(deliveriesValue?.toString() ?? '') ?? 0,
      averageTime: json['average_time']?.toString() ?? '',
    );
  }

  // Iniciales para mostrar la identidad del repartidor sin nombres fijos.
  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'R';
    if (parts.length == 1) {
      final value = parts.first;
      return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'name': name,
      'vehicle': vehicle,
      'completed_deliveries': completedDeliveries,
      'average_time': averageTime,
    };
  }
}
