import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

String orderStatusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return 'Pending';
    case 'ACCEPTED':
      return 'Accepted';
    case 'IN_PROGRESS':
      return 'In Progress';
    case 'PREPARING':
      return 'Preparing';
    case 'ON_THE_WAY':
      return 'On The Way';
    case 'DELIVERED':
      return 'Delivered';
    case 'CANCELLED':
      return 'Cancelled';
    default:
      return status;
  }
}

Color orderStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return Colors.orange;
    case 'ACCEPTED':
      return AppColors.primaryOrange;
    case 'IN_PROGRESS':
      return Colors.blue;
    case 'PREPARING':
      return Colors.purple;
    case 'ON_THE_WAY':
      return Colors.blue;
    case 'DELIVERED':
      return AppColors.success;
    case 'CANCELLED':
      return AppColors.error;
    default:
      return AppColors.textSecondary;
  }
}

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        orderStatusLabel(status).toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}