import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {

  const OtpVerificationScreen({
    super.key,
    required this.identifier,
    this.isEmail = false,
  });
  final String identifier;
  final bool isEmail;

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  static const int _boxCount = 8;
  final List<TextEditingController> _controllers = List.generate(_boxCount, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(_boxCount, (_) => FocusNode());
  final List<FocusNode> _keyListeners = List.generate(_boxCount, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    for (final f in _keyListeners) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (value.length == 1) {
      // Auto-advance to next box
      if (index < _boxCount - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
  }

  void _onKeyEvent(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otp;
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6 to 8 digit code')),
      );
      return;
    }

    await ref.read(authProvider.notifier).verifyOTP(
          phone: widget.isEmail ? null : widget.identifier,
          email: widget.isEmail ? widget.identifier : null,
          token: otp,
          type: widget.isEmail ? OtpType.email : OtpType.sms,
        );
  }

  Future<void> _handleResendCode() async {
    if (widget.isEmail) {
      await ref.read(authProvider.notifier).signInWithEmailOtp(
            email: widget.identifier,
          );
    } else {
      await ref.read(authProvider.notifier).signInWithPhone(
            phone: widget.identifier,
          );
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verify Code',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the code sent to ${widget.identifier}',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),

              // OTP Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_boxCount, (index) {
                  return SizedBox(
                    width: 40,
                    height: 56,
                    child: RawKeyboardListener(
                      focusNode: _keyListeners[index],
                      onKey: (event) => _onKeyEvent(index, event),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        enabled: !isLoading,
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) => _onChanged(index, value),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleVerifyOtp,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.darkBg,
                          ),
                        )
                      : const Text(
                          'Verify & Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Resend Code
              Center(
                child: TextButton(
                  onPressed: isLoading ? null : _handleResendCode,
                  child: RichText(
                    text: TextSpan(
                      text: "Didn't receive a code? ",
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'Resend',
                          style: TextStyle(
                            color: isLoading ? AppColors.textTertiary : AppColors.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
