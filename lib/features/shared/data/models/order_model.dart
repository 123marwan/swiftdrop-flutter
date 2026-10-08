class OrderModel {
  final int? id;
  final String orderDetails;
  final double totalPrice;
  final String status;
  final int? customerId;
  final int? driverId;
  final String? createdAt;
  final String? updatedAt;
  final double? latitude;
  final double? longitude;

  OrderModel({
    this.id,
    required this.orderDetails,
    required this.totalPrice,
    required this.status,
    this.customerId,
    this.driverId,
    this.createdAt,
    this.updatedAt,
    this.latitude,
    this.longitude,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      orderDetails: json['orderDetails']?.toString() ?? '',
      totalPrice: (json['totalPrice'] is num)
          ? (json['totalPrice'] as num).toDouble()
          : double.tryParse(json['totalPrice']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'PENDING',
      customerId: json['customerId'],
      driverId: json['driverId'],
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      latitude: (json['latitude'] is num)
          ? (json['latitude'] as num).toDouble()
          : double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: (json['longitude'] is num)
          ? (json['longitude'] as num).toDouble()
          : double.tryParse(json['longitude']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderDetails': orderDetails,
      'totalPrice': totalPrice,
      'status': status,
      if (customerId != null) 'customerId': customerId,
      if (driverId != null) 'driverId': driverId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  OrderModel copyWith({
    int? id,
    String? orderDetails,
    double? totalPrice,
    String? status,
    int? customerId,
    int? driverId,
    String? createdAt,
    String? updatedAt,
    double? latitude,
    double? longitude,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderDetails: orderDetails ?? this.orderDetails,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      customerId: customerId ?? this.customerId,
      driverId: driverId ?? this.driverId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}