class StompDestinations {
  static const String orderStatusTopic = '/topic/order.status';
  static const String pendingOrdersTopic = '/topic/order.pending';
  static const String deliveriesTopic = '/topic/order.deliveries';

  static String appStatusUpdate(int orderId) =>
      '/app/orders/$orderId/status';

  static String appAcceptOrder(int orderId) =>
      '/app/orders/$orderId/accept';

  static const String appNewOrder = '/app/orders/new';
}

class RealtimeConfig {
  static const String wsPath = '/ws';
  static const Duration reconnectDelay = Duration(seconds: 5);
  static const Duration heartbeatOutgoing = Duration(seconds: 10);
  static const Duration heartbeatIncoming = Duration(seconds: 10);
  static const Duration connectionTimeout = Duration(seconds: 10);
}