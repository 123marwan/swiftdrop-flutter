import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/cart_model.dart';
import '../models/restaurant_model.dart';

class RestaurantService {
  /// GET /api/restaurants → list of restaurants.
  /// Accepts either a plain JSON array or a Spring Data Page wrapper.
  Future<List<RestaurantModel>> getRestaurants() async {
    try {
      final response = await DioClient.dio.get(ApiEndpoints.restaurants);
      if (response.statusCode == 200) {
        final items = _extractItems(response.data);
        return items
            .map((e) => RestaurantModel.fromJson(e))
            .toList(growable: false);
      }
      return const [];
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  /// GET /api/restaurants/{id}/menu → menu items for one restaurant.
  Future<List<MenuItemModel>> getRestaurantMenu(int restaurantId) async {
    try {
      final response =
          await DioClient.dio.get(ApiEndpoints.restaurantMenu(restaurantId));
      if (response.statusCode == 200) {
        final items = _extractItems(response.data);
        return items
            .map((e) {
              final item = MenuItemModel.fromJson(e);
              // The menu endpoint may omit the restaurant id/name.
              return item.restaurantId == 0
                  ? item.copyWith(restaurantId: restaurantId)
                  : item;
            })
            .toList(growable: false);
      }
      return const [];
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  List<Map<String, dynamic>> _extractItems(dynamic data) {
    if (data is List) {
      return data.map((e) => _asMap(e)).toList();
    }
    if (data is Map) {
      // Spring Data Page: { content: [...], totalElements, ... }
      final content = data['content'];
      if (content is List) {
        return content.map((e) => _asMap(e)).toList();
      }
      if (data['data'] is List) {
        return (data['data'] as List).map((e) => _asMap(e)).toList();
      }
    }
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic e) {
    if (e is Map<String, dynamic>) return e;
    if (e is Map) return e.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  String _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map) {
        return data['message']?.toString() ??
            data['error']?.toString() ??
            'Server error (${e.response?.statusCode})';
      } else if (data is String && data.isNotEmpty) {
        return data;
      }
      return 'Server error (${e.response?.statusCode})';
    }
    return e.message ?? 'Connection failed';
  }
}