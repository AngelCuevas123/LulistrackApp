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
    return UserModel(
      driverId: json['driver_id'] ?? '',
      name: json['name'] ?? '',
      vehicle: json['vehicle'] ?? '',
      completedDeliveries: json['completed_deliveries'] ?? 0,
      averageTime: json['average_time'] ?? '',
    );
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
