import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/order.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 100),
              const SizedBox(height: 24),
              const Text(
                'Order Completed!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                'Order #${order.id.substring(0, 8)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Back to Orders'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
