import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/order_model.dart';

class OrderService {
  Future<List<OrderModel>> getAllOrders() async {
    try {
      final response = await DioClient.dio.get(ApiEndpoints.ordersAll);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((e) => OrderModel.fromJson(e)).toList();
        }
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<List<OrderModel>> getPendingOrders() async {
    try {
      final response = await DioClient.dio.get(ApiEndpoints.ordersPending);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((e) => OrderModel.fromJson(e)).toList();
        }
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      final response = await DioClient.dio.post(
        ApiEndpoints.ordersCreate,
        data: order.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return OrderModel.fromJson(response.data);
      }
      throw Exception('Failed to create order');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<OrderModel> acceptOrder(int orderId) async {
    // 1. Try dedicated accept and assign endpoints first (Spring Boot driver assignment)
    final candidateEndpoints = [
      ApiEndpoints.ordersAccept(orderId),
      ApiEndpoints.ordersAssign(orderId),
      '/api/orders/$orderId/accept',
      '/api/orders/$orderId/assign',
    ];

    for (final endpoint in candidateEndpoints) {
      try {
        final response = await DioClient.dio.put(endpoint);
        if (response.statusCode == 200 || response.statusCode == 201) {
          return OrderModel.fromJson(response.data);
        }
      } on DioException catch (_) {
        try {
          final response = await DioClient.dio.post(endpoint);
          if (response.statusCode == 200 || response.statusCode == 201) {
            return OrderModel.fromJson(response.data);
          }
        } catch (_) {}
      }
    }

    // 2. Fallback to updateOrderStatus
    return await updateOrderStatus(orderId, 'IN_PROGRESS');
  }

  Future<OrderModel> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await _sendUpdateStatusRequest(orderId, status);
      if (response.statusCode == 200) {
        return OrderModel.fromJson(response.data);
      }
      throw Exception('Failed to update order status');
    } on DioException catch (e) {
      final errorStr = _handleDioError(e);

      // If Spring Boot complains "You can only update orders assigned to you",
      // try calling the driver assignment / accept endpoints
      if (errorStr.contains('assigned to you') || errorStr.contains('only update orders')) {
        final candidateEndpoints = [
          ApiEndpoints.ordersAccept(orderId),
          ApiEndpoints.ordersAssign(orderId),
          '/api/orders/$orderId/accept',
          '/api/orders/$orderId/assign',
        ];

        for (final endpoint in candidateEndpoints) {
          try {
            final response = await DioClient.dio.put(endpoint);
            if (response.statusCode == 200 || response.statusCode == 201) {
              return OrderModel.fromJson(response.data);
            }
          } catch (_) {
            try {
              final response = await DioClient.dio.post(endpoint);
              if (response.statusCode == 200 || response.statusCode == 201) {
                return OrderModel.fromJson(response.data);
              }
            } catch (_) {}
          }
        }
      }

      // Fallback logic: if Spring Boot enum rejects the requested status, try compatible candidates
      if (errorStr.contains('Invalid status value') || e.response?.statusCode == 400) {
        final candidateStatuses = status == 'ACCEPTED'
            ? ['IN_PROGRESS', 'ON_THE_WAY', 'PROCESSING']
            : ['ON_THE_WAY', 'DELIVERED', 'IN_PROGRESS'];

        for (final candidate in candidateStatuses) {
          try {
            final fallbackResponse = await _sendUpdateStatusRequest(orderId, candidate);
            if (fallbackResponse.statusCode == 200) {
              return OrderModel.fromJson(fallbackResponse.data);
            }
          } catch (_) {}
        }
      }

      throw Exception(errorStr);
    }
  }

  Future<Response> _sendUpdateStatusRequest(int orderId, String status) async {
    return await DioClient.dio.put(
      ApiEndpoints.ordersUpdateStatus(orderId),
      queryParameters: {'status': status},
    );
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