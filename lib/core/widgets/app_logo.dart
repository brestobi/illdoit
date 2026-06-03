import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppLogo extends StatelessWidget {

  const AppLogo({
    super.key,
    this.size = 80,
    this.isRounded = true,
  });
  final double size;
  final bool isRounded;

  @override
  Widget build(BuildContext context) => Container(
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
