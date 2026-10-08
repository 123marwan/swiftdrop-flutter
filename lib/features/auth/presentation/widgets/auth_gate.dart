import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../customer/presentation/screens/customer_home_screen.dart';
import '../../../driver/presentation/screens/driver_dashboard_screen.dart';
import '../blocs/auth/auth_cubit.dart';
import '../screens/HomeScreen.dart';
import '../screens/LoginScreen.dart';

/// App root. Picks the correct first screen from the persisted session:
///   - no session  → LoginScreen
///   - customer    → Customer portal
///   - driver      → Driver portal
///   - session but unknown role → HomeScreen role picker (fallback)
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<AuthCubit>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.unknown:
            return const _SessionLoader();
          case AuthStatus.unauthenticated:
            return const LoginScreen();
          case AuthStatus.authenticated:
            if (state.role == UserRole.customer) {
              return const CustomerHomeScreen();
            }
            if (state.role == UserRole.driver) {
              return const DriverDashboardScreen();
            }
            return const HomeScreen();
        }
      },
    );
  }
}

class _SessionLoader extends StatelessWidget {
  const _SessionLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CustomLoader(color: AppColors.primaryOrange, size: 40),
      ),
    );
  }
}