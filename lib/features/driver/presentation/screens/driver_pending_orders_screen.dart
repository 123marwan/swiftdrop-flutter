import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/utils/auth_actions.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/realtime_service.dart';
import '../../../shared/data/models/order_model.dart';
import '../../../shared/data/services/order_service.dart';
import '../../../shared/presentation/components/status_chip.dart';

class DriverPendingOrdersScreen extends StatefulWidget {
  const DriverPendingOrdersScreen({super.key});

  @override
  State<DriverPendingOrdersScreen> createState() =>
      _DriverPendingOrdersScreenState();
}

class _DriverPendingOrdersScreenState
    extends State<DriverPendingOrdersScreen> {
  final OrderService _orderService = sl<OrderService>();
  List<OrderModel> _pendingOrders = [];
  bool _isLoading = true;
  String? _error;
  Timer? _timer;
  final Set<int> _acceptingOrders = {};
  StreamSubscription<OrderModel>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _fetchPendingOrders();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchPendingOrders();
    });
    sl<RealtimeService>()
      ..watchPendingOrders()
      ..connect();
    _realtimeSubscription = sl<RealtimeService>()
        .pendingOrderUpdates
        .listen(_onRealtimePendingOrder);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  void _onRealtimePendingOrder(OrderModel order) {
    if (!mounted) return;
    if (order.status.toUpperCase() != 'PENDING') return;
    setState(() {
      final index = _pendingOrders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _pendingOrders[index] = order;
      } else {
        _pendingOrders.insert(0, order);
      }
    });
  }

  Future<void> _fetchPendingOrders() async {
    try {
      final orders = await _orderService.getPendingOrders();
      if (mounted) {
        setState(() {
          _pendingOrders = orders;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptOrder(OrderModel order) async {
    if (order.id == null) return;
    setState(() {
      _acceptingOrders.add(order.id!);
    });
    try {
      await _orderService.acceptOrder(order.id!);
      sl<RealtimeService>().acceptOrder(order.id!);
      if (!mounted) return;
      showSuccessSnackBar(context, 'Order accepted successfully!');
      setState(() {
        _pendingOrders.removeWhere((o) => o.id == order.id);
      });
      _fetchPendingOrders();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted && order.id != null) {
        setState(() {
          _acceptingOrders.remove(order.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Pending Orders',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPendingOrders,
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => confirmSignOut(context),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CustomLoader(color: AppColors.primaryGreen, size: 40),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error loading orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchPendingOrders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_pendingOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No pending orders',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Orders will appear here in real-time',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchPendingOrders,
      color: AppColors.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingOrders.length,
        itemBuilder: (context, index) {
          final order = _pendingOrders[index];
          final isAccepting = order.id != null && _acceptingOrders.contains(order.id);
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      StatusChip(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    order.orderDetails,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'EGP ${order.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isAccepting ? null : () => _acceptOrder(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: isAccepting
                          ? const CustomLoader(color: Colors.white)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Accept Order',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}