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

class DriverActiveOrdersScreen extends StatefulWidget {
  const DriverActiveOrdersScreen({super.key});

  @override
  State<DriverActiveOrdersScreen> createState() =>
      _DriverActiveOrdersScreenState();
}

class _DriverActiveOrdersScreenState extends State<DriverActiveOrdersScreen> {
  final OrderService _orderService = sl<OrderService>();
  List<OrderModel> _activeOrders = [];
  bool _isLoading = true;
  String? _error;
  Timer? _timer;
  final Set<int> _updatingOrders = {};
  StreamSubscription<OrderModel>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _fetchActiveOrders();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchActiveOrders();
    });
    sl<RealtimeService>()
      ..watchOrderStatus()
      ..connect();
    _realtimeSubscription =
        sl<RealtimeService>().orderUpdates.listen(_onRealtimeOrderUpdate);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  void _onRealtimeOrderUpdate(OrderModel order) {
    if (!mounted) return;
    final status = order.status.toUpperCase();
    setState(() {
      if (status == 'DELIVERED' || status == 'CANCELLED') {
        _activeOrders.removeWhere((o) => o.id == order.id);
      } else if (status == 'ACCEPTED' ||
          status == 'IN_PROGRESS' ||
          status == 'ON_THE_WAY' ||
          status == 'PREPARING') {
        final index = _activeOrders.indexWhere((o) => o.id == order.id);
        if (index != -1) {
          _activeOrders[index] = order;
        } else {
          _activeOrders.insert(0, order);
        }
      }
    });
  }

  Future<void> _fetchActiveOrders() async {
    try {
      final allOrders = await _orderService.getAllOrders();
      final active = allOrders.where((order) {
        final s = order.status.toUpperCase();
        return s == 'ACCEPTED' ||
            s == 'IN_PROGRESS' ||
            s == 'ON_THE_WAY' ||
            s == 'PREPARING';
      }).toList();

      if (mounted) {
        setState(() {
          _activeOrders = active;
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

  Future<void> _updateStatus(OrderModel order, String newStatus) async {
    if (order.id == null) return;
    setState(() {
      _updatingOrders.add(order.id!);
    });
    try {
      await _orderService.updateOrderStatus(order.id!, newStatus);
      sl<RealtimeService>().publishOrderStatus(order.id!, newStatus);
      if (!mounted) return;
      showSuccessSnackBar(context, 'Status updated to $newStatus');
      _fetchActiveOrders();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted && order.id != null) {
        setState(() {
          _updatingOrders.remove(order.id);
        });
      }
    }
  }

  String _getNextStatus(String currentStatus) {
    switch (currentStatus.toUpperCase()) {
      case 'ACCEPTED':
      case 'IN_PROGRESS':
        return 'ON_THE_WAY';
      case 'ON_THE_WAY':
        return 'DELIVERED';
      default:
        return 'ON_THE_WAY';
    }
  }

  String _getActionButtonText(String currentStatus) {
    switch (currentStatus.toUpperCase()) {
      case 'ACCEPTED':
      case 'IN_PROGRESS':
        return 'Start Delivery';
      case 'ON_THE_WAY':
        return 'Mark as Delivered';
      default:
        return 'Update Status';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Active Orders',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchActiveOrders,
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
                onPressed: _fetchActiveOrders,
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
    if (_activeOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No active orders',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Accept pending orders to start delivery',
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
      onRefresh: _fetchActiveOrders,
      color: AppColors.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeOrders.length,
        itemBuilder: (context, index) {
          final order = _activeOrders[index];
          final isUpdating =
              order.id != null && _updatingOrders.contains(order.id);
          final nextStatus = _getNextStatus(order.status);
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
                      onPressed: isUpdating
                          ? null
                          : () => _updateStatus(order, nextStatus),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: isUpdating
                          ? const CustomLoader(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.local_shipping, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  _getActionButtonText(order.status),
                                  style: const TextStyle(
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