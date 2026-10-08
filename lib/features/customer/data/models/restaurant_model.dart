/// Mirrors the backend `Restaurant` entity returned by `/api/restaurants`.
///
/// Parsing is defensive: it accepts several key aliases so it keeps working
/// whether the backend serializes `image`, `rating`, `cuisineType` or the
/// canonical snake_case/camelCase forms.
class RestaurantModel {
  final int id;
  final String name;
  final String imageUrl;
  final String category;
  final double rating;
  final String deliveryTime;
  final double minOrder;
  final String? address;
  final double? latitude;
  final double? longitude;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.rating,
    required this.deliveryTime,
    required this.minOrder,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: _asInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? 'Restaurant',
      imageUrl: json['imageUrl']?.toString() ??
          json['image']?.toString() ??
          json['imagePath']?.toString() ??
          '',
      category: json['category']?.toString() ??
          json['cuisineType']?.toString() ??
          json['type']?.toString() ??
          '',
      rating: _asDouble(json['rating']) ??
          _asDouble(json['averageRating']) ??
          0.0,
      deliveryTime: _asString(json['deliveryTime']) ??
          _asString(json['estimatedDeliveryTime']) ??
          _asString(json['estimatedTimeMinutes']) ??
          '30-45 min',
      minOrder: _asDouble(json['minOrder']) ??
          _asDouble(json['minimumOrderValue']) ??
          _asDouble(json['minOrderValue']) ??
          0.0,
      address: json['address']?.toString(),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      'category': category,
      'rating': rating,
      'deliveryTime': deliveryTime,
      'minOrder': minOrder,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    if (value is num) return '${value.toInt()} min';
    return value.toString();
  }
}