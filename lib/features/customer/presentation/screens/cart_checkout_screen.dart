import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/realtime_service.dart';
import '../blocs/cart/cart_cubit.dart';
import '../../data/models/cart_model.dart';
import '../components/cart_item_widget.dart';
import '../../../shared/data/models/order_model.dart';
import '../../../shared/data/services/order_service.dart';
import 'order_tracking_screen.dart';

class CartCheckoutScreen extends StatefulWidget {
  const CartCheckoutScreen({super.key});

  @override
  State<CartCheckoutScreen> createState() => _CartCheckoutScreenState();
}

class _CartCheckoutScreenState extends State<CartCheckoutScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _descriptionController = TextEditingController();
  final OrderService _orderService = sl<OrderService>();
  bool _isLoading = false;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final pickup = _pickupController.text.trim();
    final dropoff = _dropoffController.text.trim();
    final description = _descriptionController.text.trim();
    final cartState = context.read<CartCubit>().state;

    if (pickup.isEmpty || dropoff.isEmpty) {
      showErrorSnackBar(context, 'Please enter pickup and delivery address');
      return;
    }

    if (cartState.items.isEmpty) {
      showErrorSnackBar(context, 'Your cart is empty');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final orderDetails = 'Pickup: $pickup | Dropoff: $dropoff | '
          'Items: ${cartState.items.map((e) => '${e.menuItem.name} x${e.quantity}').join(', ')} | '
          'Notes: $description';

      final order = OrderModel(
        orderDetails: orderDetails,
        totalPrice: cartState.total,
        status: 'PENDING',
      );

      final createdOrder = await _orderService.createOrder(order);
      sl<RealtimeService>().announceOrderCreated(order);

      if (!mounted) return;
      context.read<CartCubit>().clearCart();
      showSuccessSnackBar(context, 'Order placed successfully!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(
            order: createdOrder,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Cart & Checkout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add items from home to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return CartItemWidget(
                            cartItem: item,
                            onIncrement: () {
                              context.read<CartCubit>().incrementQuantity(
                                    item.menuItem.id,
                                  );
                            },
                            onDecrement: () {
                              context.read<CartCubit>().decrementQuantity(
                                    item.menuItem.id,
                                  );
                            },
                            onRemove: () {
                              context.read<CartCubit>().removeFromCart(
                                    item.menuItem.id,
                                  );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Delivery Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pickupController,
                        decoration: InputDecoration(
                          labelText: 'Pickup Address',
                          hintText: 'Enter pickup location',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.location_on,
                              color: AppColors.primaryOrange),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _dropoffController,
                        decoration: InputDecoration(
                          labelText: 'Delivery Address',
                          hintText: 'Enter delivery location',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.flag,
                              color: AppColors.primaryGreen),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Order Notes (Optional)',
                          hintText: 'Special instructions...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.note),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildPriceRow('Subtotal', state.subtotal),
                            const SizedBox(height: 8),
                            _buildPriceRow('Delivery Fee', state.deliveryFee),
                            const Divider(height: 16),
                            _buildPriceRow('Total', state.total, isTotal: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const CustomLoader(color: Colors.white)
                          : Text(
                              'Place Order • EGP ${state.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'EGP ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.primaryOrange : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}