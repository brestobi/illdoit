import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/pin_provider.dart';

/// PIN entry / setup screen for wallet security.
///
/// Handles two flows:
/// 1. **Setup** — First-time user creates a 4-digit PIN (mode == notSet)
/// 2. **Entry** — Returning user enters their PIN to unlock the wallet (mode == locked)
class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _focusNode = FocusNode();
  String _enteredPin = '';
  String _confirmPin = '';
  bool _showError = false;
  String _errorMessage = '';
  bool _isLoading = false;
  bool _showConfirm = false; // For setup: show confirm step

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pinProvider.notifier).checkPinStatus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    _focusNode.dispose();
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
            // First step of setup — go to confirm
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
        // Go back to first entry
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

    final isValid = await ref.read(pinProvider.notifier).verifyPin(_enteredPin);

    if (isValid) {
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _showError = true;
        _errorMessage = 'Incorrect PIN. Please try again.';
        _isLoading = false;
        _enteredPin = '';
      });
    }
  }

  bool _isValidPin(String pin) {
    return pin.length == 4 && RegExp(r'^\d{4}$').hasMatch(pin);
  }

  @override
  Widget build(BuildContext context) {
    final pinStatus = ref.watch(pinProvider);
    final isSetup = pinStatus == PinStatus.notSet;

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

            const SizedBox(height: 16),

            // Cancel / Back button
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
        const SizedBox(width: 72), // Empty space for symmetry
        _buildKey('0'),
        _buildKey('delete', isDelete: true),
      ],
    );
  }

  Widget _buildKey(String label, {bool isDelete = false}) {
    return SizedBox(
      width: 72,
      height: 72,
      child: TextButton(
        onPressed: _isLoading
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
