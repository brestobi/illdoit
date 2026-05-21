import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool isRounded;

  const AppLogo({
    super.key,
    this.size = 80,
    this.isRounded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: isRounded
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.2),
              image: const DecorationImage(
                image: AssetImage('assets/icons/icon.png'),
                fit: BoxFit.cover,
              ),
            )
          : BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(size * 0.25),
              image: const DecorationImage(
                image: AssetImage('assets/icons/icon.png'),
                fit: BoxFit.cover,
              ),
            ),
    );
  }
}
