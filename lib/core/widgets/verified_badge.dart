import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class VerifiedBadge extends StatelessWidget {

  const VerifiedBadge({super.key, 
    this.size = 16,
    this.showText = false,
  });
  final double size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    if (showText) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, size: size, color: AppColors.primary),
            const SizedBox(width: 4),
            const Text(
              'Verified',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    return Icon(
      Icons.verified,
      size: size,
      color: AppColors.primary,
    );
  }
}
