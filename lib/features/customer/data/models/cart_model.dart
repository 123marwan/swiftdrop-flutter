

class MenuItemModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final String restaurantName;
  final int restaurantId;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.restaurantName,
    required this.restaurantId,
  });

  /// Mirrors the backend menu item entity returned by
  /// `/api/restaurants/{id}/menu`. Accepts common key aliases.
  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'Item',
      description: json['description']?.toString() ?? '',
      price: json['price'] is num
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      imageUrl: json['imageUrl']?.toString() ??
          json['image']?.toString() ??
          json['imagePath']?.toString() ??
          '',
      category: json['category']?.toString() ??
          json['type']?.toString() ??
          '',
      restaurantName: json['restaurantName']?.toString() ??
          json['restaurant']?.toString() ??
          '',
      restaurantId: json['restaurantId'] is int
          ? json['restaurantId']
          : int.tryParse(json['restaurantId']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      'category': category,
      'restaurantName': restaurantName,
      'restaurantId': restaurantId,
    };
  }

  MenuItemModel copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    String? restaurantName,
    int? restaurantId,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantId: restaurantId ?? this.restaurantId,
    );
  }
}

class CartItem {
  final MenuItemModel menuItem;
  int quantity;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
  });

  double get totalPrice => menuItem.price * quantity;

  CartItem copyWith({
    MenuItemModel? menuItem,
    int? quantity,
  }) {
    return CartItem(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartState {
  final List<CartItem> items;
  final bool isLoading;

  CartState({
    required this.items,
    this.isLoading = false,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  double get deliveryFee => items.isEmpty ? 0 : 25.0;
  double get total => subtotal + deliveryFee;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}