import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
          ? null
          : BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(size * 0.25),
            ),
      child: SvgPicture.asset(
        'assets/icons/logo.svg',
        width: size,
        height: size,
      ),
    );
  }
}
