import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/pin_provider.dart';

/// PIN entry / setup screen for wallet security.
///
/// Handles three flows:
/// 1. **Setup** — First-time user creates a 4-digit PIN (mode == notSet)
/// 2. **Entry** — Returning user enters their PIN to unlock the wallet (mode == locked)
/// 3. **Recovery** — User forgot PIN → verify account password → set new PIN
class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _focusNode = FocusNode();
  final _passwordController = TextEditingController();
  String _enteredPin = '';
  String _confirmPin = '';
  bool _showError = false;
  String _errorMessage = '';
  bool _isLoading = false;
  bool _showConfirm = false;
  bool _showRecovery = false;
  bool _canUseBiometrics = false;

  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pinProvider.notifier).checkPinStatus();
    });
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isAvailable = await _localAuth.isDeviceSupported();
      if (mounted) {
        setState(() => _canUseBiometrics = canCheck && isAvailable);
      }
    } catch (_) {
      // Biometrics unavailable
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock your wallet',
        biometricOnly: true,
      );
      if (authenticated && mounted) {
        // Mark the PIN as verified for this session
        ref.read(pinProvider.notifier).biometricUnlock();
        if (mounted) Navigator.pop(context, true);
      }
    } catch (_) {
      // Biometric auth failed — user can still enter PIN
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    _focusNode.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_showError) setState(() => _showError = false);

    if (_showConfirm) {
      if (_confirmPin.length < 4) {
        setState(() => _confirmPin += digit);
        if (_confirmPin.length == 4) _verifySetup();
      }
    } else {
      if (_enteredPin.length < 4) {
        setState(() => _enteredPin += digit);
        if (_enteredPin.length == 4) {
          final pinStatus = ref.read(pinProvider);
          if (pinStatus == PinStatus.notSet) {
            setState(() {
              _showConfirm = true;
              _confirmPin = '';
            });
          } else {
            _verifyEntry();
          }
        }
      }
    }
  }

  void _onDeletePressed() {
    if (_showConfirm) {
      if (_confirmPin.isNotEmpty) {
        setState(() => _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1));
      } else {
        setState(() {
          _showConfirm = false;
          _enteredPin = '';
        });
      }
    } else {
      if (_enteredPin.isNotEmpty) {
        setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
      }
    }
  }

  Future<void> _verifySetup() async {
    setState(() => _isLoading = true);

    if (_enteredPin != _confirmPin) {
      setState(() {
        _showError = true;
        _errorMessage = 'PINs do not match. Try again.';
        _isLoading = false;
        _enteredPin = '';
        _confirmPin = '';
        _showConfirm = false;
      });
      return;
    }

    if (!_isValidPin(_enteredPin)) {
      setState(() {
        _showError = true;
        _errorMessage = 'PIN must be exactly 4 digits.';
        _isLoading = false;
        _enteredPin = '';
        _confirmPin = '';
        _showConfirm = false;
      });
      return;
    }

    try {
      await ref.read(pinProvider.notifier).setPin(_enteredPin);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _showError = true;
        _errorMessage = 'Failed to save PIN. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyEntry() async {
    setState(() => _isLoading = true);

    final notifier = ref.read(pinProvider.notifier);

    if (notifier.isLockedOut) {
      setState(() {
        _showError = true;
        _errorMessage = 'Too many attempts. Try again in ${notifier.lockoutMinutesRemaining} min.';
        _isLoading = false;
        _enteredPin = '';
      });
      return;
    }

    final isValid = await notifier.verifyPin(_enteredPin);

    if (isValid) {
      if (mounted) Navigator.pop(context, true);
    } else {
      final remaining = notifier.remainingAttempts;
      setState(() {
        _showError = true;
        if (notifier.isLockedOut) {
          _errorMessage = 'Locked out. Try again in ${notifier.lockoutMinutesRemaining} min.';
        } else {
          _errorMessage = 'Incorrect PIN. $remaining attempt${remaining == 1 ? '' : 's'} remaining.';
        }
        _isLoading = false;
        _enteredPin = '';
      });
    }
  }

  Future<void> _handleForgotPin() async {
    // Show password verification dialog
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          bool obscure = true;
          bool dialogLoading = false;
          String? dialogError;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Reset Wallet PIN',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter your account password to reset your PIN.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: obscure,
                  enabled: !dialogLoading,
                  decoration: InputDecoration(
                    hintText: 'Account password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 12),
                  Text(dialogError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: dialogLoading ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: dialogLoading
                    ? null
                    : () async {
                        final pw = _passwordController.text;
                        if (pw.isEmpty) {
                          setState(() => dialogError = 'Please enter your password.');
                          return;
                        }
                        setState(() {
                          dialogLoading = true;
                          dialogError = null;
                        });
                        final valid = await ref.read(pinProvider.notifier).verifyAccountPassword(pw);
                        if (valid) {
                          Navigator.pop(ctx, pw);
                        } else {
                          setState(() {
                            dialogLoading = false;
                            dialogError = 'Incorrect password. Please try again.';
                          });
                        }
                      },
                child: dialogLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Verify'),
              ),
            ],
          );
        },
      ),
    );

    if (password != null && mounted) {
      // Password verified — reset the PIN
      await ref.read(pinProvider.notifier).resetPin();
      _passwordController.clear();
      setState(() {
        _showRecovery = false;
        _enteredPin = '';
        _confirmPin = '';
        _showConfirm = false;
        _showError = false;
      });
      // Now user can set a new PIN (state is now notSet)
    }
  }

  bool _isValidPin(String pin) {
    return pin.length == 4 && RegExp(r'^\d{4}$').hasMatch(pin);
  }

  @override
  Widget build(BuildContext context) {
    final pinStatus = ref.watch(pinProvider);
    final isSetup = pinStatus == PinStatus.notSet;
    final notifier = ref.read(pinProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Lock icon
            Icon(
              isSetup ? Icons.lock_open : Icons.lock_outline,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              isSetup ? 'Set Wallet PIN' : 'Enter Wallet PIN',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              isSetup
                  ? (_showConfirm ? 'Confirm your 4-digit PIN' : 'Create a 4-digit PIN to secure your wallet')
                  : 'Enter your 4-digit PIN to access your wallet',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            if (!isSetup && notifier.isLockedOut) ...[
              const SizedBox(height: 12),
              Text(
                'Locked out • ${notifier.lockoutMinutesRemaining} min remaining',
                style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],

            const SizedBox(height: 32),

            // PIN dot display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = _showConfirm
                    ? index < _confirmPin.length
                    : index < _enteredPin.length;
                return Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.primary : AppColors.surface,
                    border: Border.all(
                      color: filled ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Error message
            if (_showError)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),

            const Spacer(flex: 1),

            // Number pad
            _buildNumberPad(),

            const SizedBox(height: 12),

            // Biometric button (entry mode only)
            if (!isSetup && _canUseBiometrics)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: TextButton.icon(
                  onPressed: _authenticateWithBiometrics,
                  icon: const Icon(Icons.fingerprint, size: 22),
                  label: const Text('Use fingerprint / face'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ),

            // Forgot PIN + Cancel
            if (!isSetup)
              TextButton(
                onPressed: notifier.isLockedOut ? null : _handleForgotPin,
                child: const Text(
                  'Forgot PIN?',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),

            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                isSetup ? 'Skip (not recommended)' : 'Cancel',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),

            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          _buildRow(['1', '2', '3']),
          _buildRow(['4', '5', '6']),
          _buildRow(['7', '8', '9']),
          _buildLastRow(),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildKey(d)).toList(),
    );
  }

  Widget _buildLastRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const SizedBox(width: 72),
        _buildKey('0'),
        _buildKey('delete', isDelete: true),
      ],
    );
  }

  Widget _buildKey(String label, {bool isDelete = false}) {
    final notifier = ref.read(pinProvider.notifier);
    final disabled = _isLoading || (!ref.read(pinProvider).toString().contains('notSet') && notifier.isLockedOut);
    return SizedBox(
      width: 72,
      height: 72,
      child: TextButton(
        onPressed: disabled
            ? null
            : () {
                if (isDelete) {
                  _onDeletePressed();
                } else {
                  _onDigitPressed(label);
                }
              },
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          textStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
          shape: const CircleBorder(),
        ),
        child: isDelete
            ? const Icon(Icons.backspace_outlined, size: 28, color: AppColors.textSecondary)
            : Text(label),
      ),
    );
  }
}
