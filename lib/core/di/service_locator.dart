import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../features/customer/data/services/restaurant_service.dart';
import '../../features/shared/data/services/order_service.dart';
import '../network/dio_client.dart';
import '../network/realtime_service.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  sl
    ..registerLazySingleton<Dio>(() => DioClient.dio)
    ..registerLazySingleton<OrderService>(() => OrderService())
    ..registerLazySingleton<RestaurantService>(() => RestaurantService())
    ..registerLazySingleton<RealtimeService>(() => RealtimeService());
}