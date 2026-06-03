import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/walking_worker_loader.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final isAuthenticated = ref.read(authProvider).isAuthenticated;

    if (isAuthenticated) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Splash Image
          Image.asset(
            'assets/images/splash.png',
            fit: BoxFit.cover,
          ),
          // Gradient overlay for better text readability if needed
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          // Content
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(flex: 3),
                // Logo/App Icon
                AppLogo(size: 120),
                SizedBox(height: 24),
                // App Title
                Text(
                  'I\'ll Do It',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(height: 8),
                // Tagline
                Text(
                  'South Africa\'s Work & Hustle Platform',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                Spacer(flex: 2),
                // Loading Indicator
                WalkingWorkerLoader(
                  label: 'Preparing your hustle...',
                  color: Colors.white,
                ),
                SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
}
