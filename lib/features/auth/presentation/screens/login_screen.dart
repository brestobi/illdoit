import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/walking_worker_loader.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
    }
  }

  Future<void> _handleEmailOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    await ref.read(authProvider.notifier).signInWithEmailOtp(email: email);
    
    if (mounted && ref.read(authProvider).errorMessage == null) {
      context.push(
        AppRoutes.otpVerify,
        extra: {
          'identifier': email,
          'isEmail': true,
        },
      );
    }
  }

  Future<void> _launchTerms() async {
    final Uri url = Uri.parse('https://illdoit.space/termsandconditions');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch terms and conditions')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    // Listen for errors
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo Header
                  const AppLogo(size: 80),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your next hustle is just a sign-in away',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Column(
                      children: [
                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !isLoading,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Email address',
                            prefixIcon: Icon(
                              Icons.alternate_email_rounded,
                              size: 20,
                            ),
                          ),
                          validator: Validators.email,
                          autofillHints: const [AutofillHints.email],
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _isObscured,
                          enabled: !isLoading,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscured 
                                    ? Icons.visibility_off_rounded 
                                    : Icons.visibility_rounded,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscured = !_isObscured;
                                });
                              },
                            ),
                          ),
                          validator: (value) => Validators.required(value, 'Password'),
                          autofillHints: const [AutofillHints.password],
                        ),
                        const SizedBox(height: 8),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : () => context.push(AppRoutes.forgotPassword),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isLoading
                                ? const WalkingWorkerLoader(size: 24)
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // Social Login Section
                  const Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.borderColor)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or continue with',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.borderColor)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          icon: Icons.g_mobiledata_rounded,
                          label: 'Google',
                          onPressed: isLoading
                              ? null
                              : () => ref.read(authProvider.notifier).signInWithGoogle(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SocialButton(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          onPressed: isLoading ? null : _handleEmailOtp,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SocialButton(
                          icon: Icons.phone_android_rounded,
                          label: 'Phone',
                          onPressed: isLoading
                              ? null
                              : () => context.push(AppRoutes.phoneLogin),
                        ),
                      ),
                    ],
                  ),                  const SizedBox(height: 32),

                  // Sign Up Link
                  GestureDetector(
                    onTap: isLoading ? null : () => context.push(AppRoutes.signup),
                    child: RichText(
                      text: TextSpan(
                        text: 'Don\'t have an account? ',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),

                  // Terms and Conditions Link
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'By signing in, you agree to our ',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms and Conditions',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = _launchTerms,
                          ),
                          const TextSpan(text: ' and Privacy Policy.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: AppColors.borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: AppColors.textPrimary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
