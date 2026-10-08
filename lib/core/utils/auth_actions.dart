import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/service_locator.dart';
import '../../core/network/realtime_service.dart';
import '../../features/auth/presentation/blocs/auth/auth_cubit.dart';
import '../../features/customer/presentation/blocs/cart/cart_cubit.dart';

/// Tears down the whole session so the next account starts with zero leftovers:
/// 1. Drops the STOMP socket (it carries the previous user's JWT).
/// 2. Clears the in-memory cart.
/// 3. Clears the persisted token/userId/role and flips [AuthCubit] → login.
Future<void> signOut(BuildContext context) async {
  sl<RealtimeService>().disconnect();
  context.read<CartCubit>().clearCart();
  await context.read<AuthCubit>().logout();
}

Future<bool> confirmSignOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log out'),
      content: const Text('Log out and switch account?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    await signOut(context);
  }
  return confirmed == true;
}