import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/explore/presentation/screens/explore_screen.dart';
import '../../features/services/presentation/screens/services_screen.dart';
import '../../features/jobs/presentation/screens/jobs_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/chat/presentation/screens/conversations_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/services/presentation/screens/my_orders_screen.dart';
import '../../features/jobs/presentation/screens/my_applications_screen.dart';
import '../../features/jobs/presentation/screens/manage_applications_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';

import '../../features/services/presentation/screens/create_service_screen.dart';
import '../../features/jobs/presentation/screens/create_job_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/public_profile_screen.dart';
import '../../features/profile/presentation/screens/verification_center_screen.dart';
import '../../features/profile/presentation/screens/id_verification_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/phone_login_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/onboarding_steps_screen.dart';

import '../../features/services/presentation/screens/service_detail_screen.dart';


import '../../features/jobs/presentation/screens/job_detail_screen.dart';

import '../models/service.dart';
import '../models/job.dart';

/// Navigation path constants
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String phoneLogin = '/phone-login';
  static const String otpVerify = '/otp-verify';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String explore = '/explore';
  static const String services = '/services';
  static const String serviceDetail = '/service/:id';
  static const String createService = '/create-service';
  static const String jobs = '/jobs';
  static const String jobDetail = '/job/:id';
  static const String createJob = '/create-job';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String editProfile = '/edit-profile';
  static const String publicProfile = '/profile/:id';
  static const String verificationCenter = '/verification-center';
  static const String idVerification = '/id-verification';
  static const String wallet = '/wallet';
  static const String notifications = '/notifications';
  static const String messages = '/messages';
  static const String chat = '/chat/:id';
  static const String myOrders = '/my-orders';
  static const String myApplications = '/my-applications';
  static const String manageApplications = '/manage-applications/:jobId';
}

/// A notifier that bridges Riverpod and GoRouter's refreshListenable
class RouterNotifier extends ChangeNotifier {

  RouterNotifier(this._ref) {
    // Notify GoRouter when auth or profile state changes
    _ref.listen(authProvider, (_, __) => notifyListeners());
    _ref.listen(profileProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);
    final profileAsync = _ref.read(profileProvider);
    
    final isLoading = authState.isLoading;
    final isAuthenticated = authState.isAuthenticated;
    
    final isLoggingIn = state.matchedLocation == AppRoutes.login;
    final isSigningUp = state.matchedLocation == AppRoutes.signup;
    final isForgotPassword = state.matchedLocation == AppRoutes.forgotPassword;
    final isPhoneLogin = state.matchedLocation == AppRoutes.phoneLogin;
    final isOtpVerify = state.matchedLocation == AppRoutes.otpVerify;
    final isOnboarding = state.matchedLocation == AppRoutes.onboarding;
    final isSplash = state.matchedLocation == AppRoutes.splash;

    if (isLoading) return null;

    if (!isAuthenticated) {
      if (isLoggingIn || isSigningUp || isForgotPassword || isPhoneLogin || isOtpVerify || isSplash) return null;
      return AppRoutes.login;
    }

    if (isAuthenticated) {
      // If authenticated but on auth screens, go home
      if (isLoggingIn || isSigningUp || isForgotPassword || isPhoneLogin || isOtpVerify || isSplash) {
        return AppRoutes.home;
      }

      // Check onboarding status
      final profile = profileAsync.valueOrNull;
      if (profile != null && !profile.isOnboardingCompleted && !isOnboarding) {
        return AppRoutes.onboarding;
      }
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>(RouterNotifier.new);

/// GoRouter provider for navigation
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Authentication Routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.phoneLogin,
        builder: (context, state) => PhoneLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otpVerify,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final identifier = extra['identifier'] as String? ?? '';
          final isEmail = extra['isEmail'] as bool? ?? false;
          return OtpVerificationScreen(
            identifier: identifier,
            isEmail: isEmail,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => OnboardingStepsScreen(),
      ),

      // Main App Routes
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.explore,
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: AppRoutes.services,
        builder: (context, state) => const ServicesScreen(),
      ),
      GoRoute(
        path: AppRoutes.serviceDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ServiceDetailScreen(serviceId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.createService,
        builder: (context, state) {
          final service = state.extra as Service?;
          return CreateServiceScreen(service: service);
        },
      ),
      GoRoute(
        path: AppRoutes.jobs,
        builder: (context, state) => const JobsScreen(),
      ),
      GoRoute(
        path: AppRoutes.jobDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return JobDetailScreen(jobId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.createJob,
        builder: (context, state) {
          final job = state.extra as Job?;
          return CreateJobScreen(job: job);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.publicProfile,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PublicProfileScreen(userId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.verificationCenter,
        builder: (context, state) => const VerificationCenterScreen(),
      ),
      GoRoute(
        path: AppRoutes.idVerification,
        builder: (context, state) => const IdVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.wallet,
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.messages,
        builder: (context, state) => const ConversationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final name = state.extra as String? ?? 'User';
          return ChatScreen(otherUserId: id, otherUserName: name);
        },
      ),
      GoRoute(
        path: AppRoutes.myOrders,
        builder: (context, state) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.myApplications,
        builder: (context, state) => const MyApplicationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.manageApplications,
        builder: (context, state) {
          final jobId = state.pathParameters['jobId']!;
          return ManageApplicationsScreen(jobId: jobId);
        },
      ),
    ],
  );
});
