import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/auth_actions.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../auth/presentation/blocs/auth/auth_cubit.dart';
import '../../../auth/presentation/widgets/role_guard.dart';
import '../blocs/cart/cart_cubit.dart';
import '../../data/models/cart_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/restaurant_model.dart';
import '../../data/services/restaurant_service.dart';
import '../components/category_chip.dart';
import '../components/restaurant_card.dart';
import 'cart_checkout_screen.dart';
import 'live_orders_screen.dart';
import 'restaurant_menu_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final RestaurantService _restaurantService = sl<RestaurantService>();
  List<RestaurantModel> _restaurants = [];
  List<CategoryModel> _categories = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final restaurants = await _restaurantService.getRestaurants();
      if (!mounted) return;
      setState(() {
        _restaurants = restaurants;
        _categories = _buildCategories(restaurants);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<CategoryModel> _buildCategories(List<RestaurantModel> restaurants) {
    final names = <String>{};
    for (final restaurant in restaurants) {
      if (restaurant.category.isNotEmpty) {
        names.add(restaurant.category);
      }
    }
    final categories = <CategoryModel>[
      CategoryModel(id: 1, name: 'All', icon: '🍽️'),
    ];
    var nextId = 2;
    for (final name in names) {
      categories.add(
        CategoryModel(id: nextId++, name: name, icon: _iconForCategory(name)),
      );
    }
    return categories;
  }

  String _iconForCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('pizza')) return '🍕';
    if (n.contains('burger')) return '🍔';
    if (n.contains('chicken')) return '🍗';
    if (n.contains('dessert') || n.contains('sweet')) return '🍰';
    if (n.contains('drink') || n.contains('juice')) return '🥤';
    return '🍽️';
  }

  List<RestaurantModel> get _filteredRestaurants {
    if (_selectedCategory == 'All') return _restaurants;
    return _restaurants
        .where((r) => r.category == _selectedCategory)
        .toList();
  }

  void _openRestaurant(RestaurantModel restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantMenuScreen(restaurant: restaurant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRole: UserRole.customer,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'SwiftDrop',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: AppColors.primaryOrange,
          elevation: 0,
          actions: [
            BlocBuilder<CartCubit, CartState>(
              builder: (context, state) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CartCheckoutScreen(),
                          ),
                        );
                      },
                    ),
                    if (state.itemCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            state.itemCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.receipt_long, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LiveOrdersScreen()),
                );
              },
            ),
            IconButton(
              tooltip: 'Log out',
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => confirmSignOut(context),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CustomLoader(color: AppColors.primaryOrange, size: 40),
              )
            : _error != null
                ? _buildError()
                : _restaurants.isEmpty
                    ? _buildEmpty()
                    : _buildHome(),
      ),
    );
  }

  Widget _buildHome() {
    return RefreshIndicator(
      onRefresh: _loadRestaurants,
      color: AppColors.primaryOrange,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppColors.primaryOrange, AppColors.primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryOrange.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Food Delivery',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Fast & Fresh to Your Doorstep',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return CategoryChip(
                    category: category,
                    isSelected: _selectedCategory == category.name,
                    onTap: () {
                      setState(() => _selectedCategory = category.name);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Restaurants',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (_filteredRestaurants.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No restaurants in this category',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ..._filteredRestaurants.map(
                (restaurant) => RestaurantCard(
                  restaurant: restaurant,
                  onTap: () => _openRestaurant(restaurant),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Failed to load restaurants',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadRestaurants,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.storefront,
            size: 56,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'No restaurants available yet',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}