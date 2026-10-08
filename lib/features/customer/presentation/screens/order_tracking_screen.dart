import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/realtime_service.dart';
import '../../../shared/data/models/order_model.dart';
import '../../../shared/data/services/order_service.dart';
import '../../../shared/presentation/components/status_chip.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  static const _statusFlow = [
    ('PENDING', Icons.receipt_long, 'Placed'),
    ('ACCEPTED', Icons.check_circle, 'Accepted'),
    ('ON_THE_WAY', Icons.local_shipping, 'On the Way'),
    ('DELIVERED', Icons.home_rounded, 'Delivered'),
  ];

  final OrderService _orderService = sl<OrderService>();

  late OrderModel _order;
  Timer? _pollTimer;
  Timer? _driverTimer;
  StreamSubscription<OrderModel>? _statusSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  bool _realtimeConnected = false;
  bool _isLoading = true;
  double _driverProgress = 0.0;

  // Demo geo points. Replace with real coordinates returned by your backend
  // (e.g. order pickup/drop-off or live driverLocation) once available.
  static const _restaurantPoint = LatLng(30.0444, 31.2357);
  static const _customerPoint = LatLng(30.0572, 31.2405);

  LatLng get _midRoute => LatLng(
        (_restaurantPoint.latitude + _customerPoint.latitude) / 2,
        (_restaurantPoint.longitude + _customerPoint.longitude) / 2,
      );

  int get _currentStep {
    final index =
        _statusFlow.indexWhere((s) => s.$1 == _order.status.toUpperCase());
    return index == -1 ? 0 : index;
  }

  bool get _isDelivered =>
      _order.status.toUpperCase() == 'DELIVERED';

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _realtimeConnected = sl<RealtimeService>().isConnected;
    sl<RealtimeService>()
      ..watchOrderStatus()
      ..connect();
    _statusSubscription =
        sl<RealtimeService>().orderUpdates.listen(_onRealtimeUpdate);
    _connectionSubscription =
        sl<RealtimeService>().connectionStatus.listen(_onConnectionChange);
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshFromServer(),
    );
    _driverTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickDriver(),
    );
    _refreshFromServer();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _driverTimer?.cancel();
    _statusSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  void _onRealtimeUpdate(OrderModel incoming) {
    if (!mounted) return;
    if (_sameOrder(_order, incoming)) {
      setState(() => _order = incoming);
    }
  }

  void _onConnectionChange(bool connected) {
    if (!mounted) return;
    setState(() => _realtimeConnected = connected);
  }

  void _tickDriver() {
    if (!mounted) return;
    final step = _currentStep;
    setState(() {
      if (_isDelivered) {
        _driverProgress = 1.0;
      } else if (step >= 2) {
        // ON_THE_WAY → driver travels from restaurant toward the customer.
        _driverProgress = (_driverProgress + 0.04).clamp(0.0, 1.0);
      } else {
        // PENDING / ACCEPTED → driver still at the restaurant.
        _driverProgress = 0.0;
      }
    });
  }

  LatLng _lerp(LatLng a, LatLng b, double t) => LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );

  Future<void> _refreshFromServer() async {
    try {
      final orders = await _orderService.getAllOrders();
      final match = _matchFromServer(orders);
      if (match != null && mounted) {
        setState(() {
          _order = match;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  OrderModel? _matchFromServer(List<OrderModel> orders) {
    if (_order.id != null) {
      for (final order in orders) {
        if (order.id == _order.id) return order;
      }
      return null;
    }
    for (final order in orders) {
      if (order.orderDetails == _order.orderDetails &&
          order.totalPrice == _order.totalPrice) {
        return order;
      }
    }
    return null;
  }

  bool _sameOrder(OrderModel a, OrderModel b) {
    if (a.id != null && b.id != null) return a.id == b.id;
    return a.orderDetails == b.orderDetails &&
        a.totalPrice == b.totalPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Track Order',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _RealtimeBadge(connected: _realtimeConnected),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CustomLoader(color: AppColors.primaryOrange, size: 40),
            )
          : RefreshIndicator(
              onRefresh: _refreshFromServer,
              color: AppColors.primaryOrange,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildOrderHeader(),
                  const SizedBox(height: 24),
                  _buildLiveMap(),
                  const SizedBox(height: 24),
                  _buildStepper(),
                  const SizedBox(height: 24),
                  _buildDetailsCard(),
                  const SizedBox(height: 24),
                  if (_isDelivered) _buildDeliveredCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryOrange, AppColors.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${_order.id ?? ''}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              StatusChip(status: _order.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              Text(
                'EGP ${_order.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMap() {
    final current = _currentStep;
    final caption = _isDelivered
        ? 'Delivered — driver reached your location'
        : current >= 2
            ? 'Driver is on the way to your location'
            : 'Driver is preparing at the restaurant';

    return Container(
      height: 240,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _midRoute,
              initialZoom: 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.swiftdrop_app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_restaurantPoint, _customerPoint],
                    strokeWidth: 4,
                    color: AppColors.primaryOrange,
                  ),
                ],
              ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: current >= 2
                          ? AppColors.primaryGreen
                          : AppColors.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    caption,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final driver = _lerp(_restaurantPoint, _customerPoint, _driverProgress);
    return [
      Marker(
        point: _restaurantPoint,
        width: 44,
        height: 44,
        child: _mapPin(Icons.storefront, AppColors.primaryOrange),
      ),
      Marker(
        point: _customerPoint,
        width: 44,
        height: 44,
        child: _mapPin(Icons.home_rounded, AppColors.primaryGreen),
      ),
      Marker(
        point: driver,
        width: 48,
        height: 48,
        child: _driverMarker(),
      ),
    ];
  }

  Widget _mapPin(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _driverMarker() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(Icons.local_shipping, color: Colors.white, size: 22),
    );
  }

  Widget _buildStepper() {
    final current = _currentStep;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Progress',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 18,
              left: 24,
              right: 24,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: current > 0
                            ? AppColors.primaryOrange
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: current > 1
                            ? AppColors.primaryOrange
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: current > 2
                            ? AppColors.primaryOrange
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_statusFlow.length, (index) {
                final step = _statusFlow[index];
                final isCompleted = index < current;
                final isActive = index == current && !_isDelivered;
                return Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primaryOrange
                              : isCompleted
                                  ? AppColors.success
                                  : AppColors.border,
                          shape: BoxShape.circle,
                          border: isActive
                              ? Border.all(
                                  color: AppColors.primaryOrange,
                                  width: 3,
                                )
                              : null,
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryOrange
                                        .withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          step.$2,
                          color: (isCompleted || isActive)
                              ? Colors.white
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step.$3,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: (isActive || isCompleted)
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: (isActive || isCompleted)
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _order.orderDetails,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveredCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success),
      ),
      child: const Row(
        children: [
          Icon(Icons.thumb_up_alt, color: AppColors.success, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Order Delivered! Enjoy your meal.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RealtimeBadge extends StatelessWidget {
  final bool connected;

  const _RealtimeBadge({required this.connected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: connected
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: connected ? AppColors.success : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            connected ? 'LIVE' : 'POLLING',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}