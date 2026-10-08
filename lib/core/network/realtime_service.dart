import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../constants/realtime_constants.dart';
import 'dio_client.dart';
import '../../features/shared/data/models/order_model.dart';

/// Owns the STOMP (WebSocket) connection to the Spring Boot backend.
/// Re-subscribes automatically after every (re)connect and pipes server
/// broadcasts into typed [Stream]s that the UI widgets can listen to.
///
/// REST remains the source of truth; this layer only accelerates updates that
/// would otherwise wait for the next polling tick.
///
/// Register via [setupServiceLocator] (single shared instance app-wide).
class RealtimeService {
  RealtimeService();

  StompClient? _client;
  bool _activated = false;

  final Map<String, StompFrameCallback> _registrations = {};
  final Map<String, List<StompUnsubscribe>> _activeSubscriptions = {};
  final Set<String> _subscribedTopics = {};

  final _orderUpdatesController = StreamController<OrderModel>.broadcast();
  final _pendingOrdersController = StreamController<OrderModel>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<OrderModel> get orderUpdates => _orderUpdatesController.stream;
  Stream<OrderModel> get pendingOrderUpdates => _pendingOrdersController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;

  bool get isConnected => _client?.connected ?? false;

  Future<void> connect() async {
    if (_activated) return;
    _activated = true;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final connectHeaders = <String, String>{
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final socketUrl = token.isNotEmpty
        ? '${_socketUrl()}?token=$token'
        : _socketUrl();

    _client = StompClient(
      config: StompConfig(
        url: socketUrl,
        reconnectDelay: RealtimeConfig.reconnectDelay,
        connectionTimeout: RealtimeConfig.connectionTimeout,
        heartbeatOutgoing: RealtimeConfig.heartbeatOutgoing,
        heartbeatIncoming: RealtimeConfig.heartbeatIncoming,
        stompConnectHeaders: connectHeaders,
        onConnect: _onConnect,
        onDisconnect: (_) => _connectionController.add(false),
        onStompError: (frame) =>
            debugPrint('[STOMP] Server error: ${frame.body}'),
        onWebSocketError: (error) =>
            debugPrint('[STOMP] WebSocket error: $error'),
        onDebugMessage: (message) => debugPrint('[STOMP] $message'),
      ),
    );
    _client!.activate();
  }

  void deactivate() {
    _activated = false;
    if (_client == null) return;
    for (final unsubs in _activeSubscriptions.values) {
      for (final unsub in unsubs) {
        unsub();
      }
    }
    _activeSubscriptions.clear();
    _subscribedTopics.clear();
    _client!.deactivate();
    _client = null;
  }

  /// Full teardown: closes the socket and flags it disconnected. Used on
  /// logout / account switch so the socket never keeps a previous user's JWT.
  void disconnect() {
    deactivate();
    _connectionController.add(false);
  }

  void watchOrderStatus() {
    _ensureSubscription(
      StompDestinations.orderStatusTopic,
      _onOrderStatusFrame,
    );
  }

  void watchPendingOrders() {
    _ensureSubscription(
      StompDestinations.pendingOrdersTopic,
      _onPendingOrdersFrame,
    );
  }

  void acceptOrder(int orderId) {
    _send(
      StompDestinations.appAcceptOrder(orderId),
      {'status': 'ACCEPTED'},
    );
  }

  void publishOrderStatus(int orderId, String status) {
    _send(
      StompDestinations.appStatusUpdate(orderId),
      {'status': status, 'orderId': orderId},
    );
  }

  void announceOrderCreated(OrderModel order) {
    _send(StompDestinations.appNewOrder, order.toJson());
  }

  void _ensureSubscription(String topic, StompFrameCallback callback) {
    _registrations[topic] = callback;
    if (isConnected) {
      _subscribeTo(topic, callback);
    }
  }

  void _subscribeTo(String topic, StompFrameCallback callback) {
    if (!_subscribedTopics.add(topic)) return;
    final unsub = _client!.subscribe(destination: topic, callback: callback);
    _activeSubscriptions.putIfAbsent(topic, () => []).add(unsub);
  }

  void _onConnect(StompFrame frame) {
    _subscribedTopics.clear();
    _activeSubscriptions.clear();
    _registrations.forEach((topic, callback) {
      _subscribeTo(topic, callback);
    });
    _connectionController.add(true);
  }

  void _onOrderStatusFrame(StompFrame frame) {
    for (final order in _parseOrders(frame)) {
      _orderUpdatesController.add(order);
    }
  }

  void _onPendingOrdersFrame(StompFrame frame) {
    for (final order in _parseOrders(frame)) {
      _pendingOrdersController.add(order);
    }
  }

  List<OrderModel> _parseOrders(StompFrame frame) {
    final body = frame.body?.trim();
    if (body == null || body.isEmpty) return const [];
    try {
      final decoded = jsonDecode(body);
      if (decoded is List) {
        return decoded
            .map((e) => OrderModel.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      }
      if (decoded is Map) {
        return [
          OrderModel.fromJson(decoded.cast<String, dynamic>()),
        ];
      }
    } catch (e) {
      debugPrint('[STOMP] Failed to parse payload: $e');
    }
    return const [];
  }

  void _send(String destination, Map<String, dynamic> payload) {
    final client = _client;
    if (client == null || !client.connected) return;
    client.send(
      destination: destination,
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(payload),
    );
  }

  String _socketUrl() {
    var base = DioClient.baseUrl;
    final scheme = base.startsWith('https://') ? 'wss://' : 'ws://';
    final withoutScheme = base.replaceFirst(RegExp(r'^https?://'), '');
    final hostPort = withoutScheme.split('/').first;
    return '$scheme$hostPort${RealtimeConfig.wsPath}';
  }
}