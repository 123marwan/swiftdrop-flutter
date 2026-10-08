import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/auth_actions.dart';
import '../../../../core/constants/app_colors.dart';
import '../blocs/auth/auth_cubit.dart';

/// Defensive role guard. Blocks [child] unless the logged-in user has
/// [requiredRole]. It is the last line of defence on top of [AuthGate]'s
/// routing (e.g. a Driver navigating directly to a Customer screen).
class RoleGuard extends StatelessWidget {
  final UserRole requiredRole;
  final Widget child;

  const RoleGuard({super.key, required this.requiredRole, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final allowed = state.isAuthenticated && state.role == requiredRole;
        if (!allowed) {
          return _ForbiddenScreen(requiredRole: requiredRole);
        }
        return child;
      },
    );
  }
}

class _ForbiddenScreen extends StatelessWidget {
  final UserRole requiredRole;

  const _ForbiddenScreen({required this.requiredRole});

  @override
  Widget build(BuildContext context) {
    final roleLabel = requiredRole == UserRole.driver ? 'Driver' : 'Customer';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: AppColors.primaryOrange,
                ),
                const SizedBox(height: 16),
                Text(
                  'This area is for $roleLabel accounts only',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You are signed in with a different role. Log out to switch.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => confirmSignOut(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}