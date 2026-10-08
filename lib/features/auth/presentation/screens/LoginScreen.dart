import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/realtime_service.dart';
import '../../../customer/presentation/blocs/cart/cart_cubit.dart';
import 'package:dio/dio.dart';
import '../blocs/auth/auth_cubit.dart';
import 'CustomerRegisterScreen.dart';
import 'DriverRegisterScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final usernameInput = _usernameController.text.trim();
    final password = _passwordController.text;

    if (usernameInput.isEmpty || password.isEmpty) {
      showErrorSnackBar(context, 'Please enter username/email and password');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await DioClient.dio.post(ApiEndpoints.authLogin, data: {
        'username': usernameInput,
        'email': usernameInput,
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        String token = '';
        String? userId;
        String? displayName;
        if (response.data is Map) {
          final data = response.data as Map;
          token = data['token'] ??
              data['accessToken'] ??
              data['jwt'] ??
              '';
          userId = data['userId']?.toString() ?? data['id']?.toString();
          displayName = data['name']?.toString() ?? data['username']?.toString();
        } else if (response.data is String) {
          token = response.data;
        }

        if (token.isEmpty) {
          if (!mounted) return;
          showErrorSnackBar(context, 'Login failed: no token returned');
          return;
        }

        final role = userRoleFromValue(
          response.data is Map ? (response.data as Map)['role'] : null,
        ) ??
            userRoleFromValue(
              response.data is Map ? (response.data as Map)['userType'] : null,
            );

        // Reset leftovers from any previous account before switching.
        if (!mounted) return;
        sl<RealtimeService>().disconnect();
        context.read<CartCubit>().clearCart();

        await context.read<AuthCubit>().signIn(
              token: token,
              userId: userId,
              role: role,
              name: displayName,
            );

        if (!mounted) return;
        showSuccessSnackBar(context, 'Login successful!');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.message ?? 'Login failed');
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'An unexpected error occurred');
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryOrange, AppColors.primaryGreen],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryOrange.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SwiftDrop',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Fast Delivery at Your Fingertips',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username or Email',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CustomLoader(color: Colors.white)
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomerRegisterScreen(),
                    ),
                  );
                },
                child: Text(
                  'Don\'t have an account? Register as Customer',
                  style: TextStyle(
                    color: AppColors.primaryOrange,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverRegisterScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.two_wheeler, color: AppColors.primaryGreen),
                label: const Text(
                  'Join as Driver',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: AppColors.primaryGreen,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}