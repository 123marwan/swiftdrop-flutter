import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiEndpoints {
  static const String authLogin = '/api/auth/login';
  static const String authRegister = '/api/auth/register';
  static const String authRegisterCustomer = '/api/auth/register/customer';
  static const String authRegisterDriver = '/api/auth/register/driver';

  static const String orders = '/api/orders';
  static const String ordersCreate = '/api/orders/create';
  static const String ordersAll = '/api/orders/all';
  static const String ordersPending = '/api/orders/pending';
  static String ordersUpdateStatus(int orderId) =>
      '/api/orders/update-status/$orderId';
  static String ordersAccept(int orderId) =>
      '/api/orders/accept/$orderId';
  static String ordersAssign(int orderId) =>
      '/api/orders/assign/$orderId';

  static const String restaurants = '/api/restaurants';
  static String restaurantMenu(int restaurantId) =>
      '/api/restaurants/$restaurantId/menu';
}

class DioClient {
  // Host:port only — ApiEndpoints carries the full "/api/..." path.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    } else {
      return 'http://localhost:8080';
    }
  }

  static final Dio dio = _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('jwt_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );

    return dio;
  }
}