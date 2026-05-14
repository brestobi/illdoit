import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../constants/app_colors.dart';

class WalkingWorkerLoader extends StatelessWidget {
  final double size;
  final Color? color;
  final String? label;

  const WalkingWorkerLoader({
    super.key,
    this.size = 50,
    this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LoadingAnimationWidget.halfTriangleDot(
          color: color ?? AppColors.primary,
          size: size,
        ),
        if (label != null) ...[
          const SizedBox(height: 16),
          Text(
            label!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
