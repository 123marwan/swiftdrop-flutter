import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/network/dio_client.dart';

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      showErrorSnackBar(context, 'Please fill all required fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = {
        'name': name,
        'username': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': 'CUSTOMER',
      };

      Response response;
      try {
        response = await DioClient.dio.post(ApiEndpoints.authRegisterCustomer, data: payload);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          // Fallback to standard /api/auth/register if /customer sub-route is 404 on backend
          response = await DioClient.dio.post(ApiEndpoints.authRegister, data: payload);
        } else {
          rethrow;
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        showSuccessSnackBar(context, 'Registration successful! Please login.');
        Navigator.pop(context);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      String errorMsg = 'Registration failed';
      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map) {
          errorMsg = data['message']?.toString() ??
              data['error']?.toString() ??
              data['details']?.toString() ??
              'Server error (${e.response?.statusCode})';
        } else if (data is String && data.trim().isNotEmpty) {
          errorMsg = data;
        } else {
          errorMsg = 'Server error (${e.response?.statusCode})';
        }
      } else {
        errorMsg = 'Cannot connect to server. Please ensure Spring Boot is running on http://localhost:8080';
      }
      showErrorSnackBar(context, errorMsg);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'An unexpected error occurred: $e');
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
        title: const Text('Customer Registration'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CustomLoader(color: Colors.white)
                    : const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}