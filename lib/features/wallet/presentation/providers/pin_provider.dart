import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/pin_service.dart';

/// Tracks the wallet PIN state for the current user.
enum PinStatus {
  /// No PIN has been set for this user yet (first-time setup needed).
  notSet,

  /// PIN exists but hasn't been verified this session.
  locked,

  /// PIN was verified successfully this session.
  unlocked,
}

/// State notifier for wallet PIN verification.
class PinNotifier extends StateNotifier<PinStatus> {
  PinNotifier(this._supabaseService, this._pinService) : super(PinStatus.locked);

  final SupabaseService _supabaseService;
  final PinService _pinService;

  String? get _currentUserId => _supabaseService.currentUser?.id;

  // Rate limiting
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  static const _maxAttempts = 5;
  static const _lockoutMinutes = 15;

  /// Whether the user is currently locked out due to too many failed attempts.
  bool get isLockedOut {
    if (_lockoutUntil == null) return false;
    if (DateTime.now().isAfter(_lockoutUntil!)) {
      _lockoutUntil = null;
      _failedAttempts = 0;
      return false;
    }
    return true;
  }

  int get remainingAttempts => isLockedOut ? 0 : _maxAttempts - _failedAttempts;

  int get lockoutMinutesRemaining {
    if (!isLockedOut || _lockoutUntil == null) return 0;
    return _lockoutUntil!.difference(DateTime.now()).inMinutes + 1;
  }

  void _recordFailedAttempt() {
    _failedAttempts++;
    if (_failedAttempts >= _maxAttempts) {
      _lockoutUntil = DateTime.now().add(const Duration(minutes: _lockoutMinutes));
    }
  }

  /// Reset the PIN — only callable after password verification.
  /// Clears the pin_hash so user can set a new one.
  Future<void> resetPin() async {
    final userId = _currentUserId;
    if (userId == null) return;

    _failedAttempts = 0;
    _lockoutUntil = null;

    await _supabaseService.update(
      table: 'users',
      id: userId,
      data: {'pin_hash': null},
    );

    state = PinStatus.notSet;
  }

  /// Verify the account password (not the PIN) against Supabase Auth.
  /// Used for PIN recovery flow.
  Future<bool> verifyAccountPassword(String password) async {
    final email = _supabaseService.currentUser?.email;
    if (email == null) return false;

    try {
      // Sign in with password to verify it's correct.
      // This doesn't change the session — it just validates the credentials.
      await _supabaseService.signInWithEmail(email: email, password: password);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Check if the current user already has a PIN set (from DB).
  /// Updates state to [PinStatus.notSet] if no PIN exists.
  Future<void> checkPinStatus() async {
    final userId = _currentUserId;
    if (userId == null) {
      state = PinStatus.locked;
      return;
    }

    try {
      final data = await _supabaseService.query(
        table: 'users',
        filters: {'id': userId},
      );

      if (data.isEmpty) {
        state = PinStatus.notSet;
        return;
      }

      final pinHash = data.first['pin_hash'] as String?;
      if (pinHash == null || pinHash.isEmpty) {
        state = PinStatus.notSet;
      } else {
        state = PinStatus.locked;
      }
    } catch (_) {
      state = PinStatus.locked;
    }
  }

  /// Verify the entered PIN against the stored hash.
  /// Returns true if verified, false otherwise.
  Future<bool> verifyPin(String pin) async {
    if (isLockedOut) return false;

    final userId = _currentUserId;
    if (userId == null) return false;

    try {
      final data = await _supabaseService.query(
        table: 'users',
        filters: {'id': userId},
      );

      if (data.isEmpty) return false;

      final storedHash = data.first['pin_hash'] as String?;
      if (storedHash == null || storedHash.isEmpty) return false;

      final isValid = _pinService.verifyPin(
        pin: pin,
        userId: userId,
        storedHash: storedHash,
      );

      if (isValid) {
        _failedAttempts = 0;
        _lockoutUntil = null;
        state = PinStatus.unlocked;
        return true;
      }

      _recordFailedAttempt();
      return false;
    } catch (_) {
      _recordFailedAttempt();
      return false;
    }
  }

  /// Set a new PIN for the current user.
  Future<void> setPin(String pin) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final hashedPin = _pinService.hashPin(pin: pin, userId: userId);

    await _supabaseService.update(
      table: 'users',
      id: userId,
      data: {'pin_hash': hashedPin},
    );

    _failedAttempts = 0;
    _lockoutUntil = null;
    state = PinStatus.unlocked;
  }

  /// Unlock the wallet via biometrics (fingerprint/face).
  /// Only call after successful biometric authentication.
  void biometricUnlock() {
    _failedAttempts = 0;
    _lockoutUntil = null;
    state = PinStatus.unlocked;
  }

  /// Lock the wallet (e.g., on app background or manual lock).
  void lock() {
    state = PinStatus.locked;
  }

  /// Reset to notSet on sign-out / user change.
  void reset() {
    _failedAttempts = 0;
    _lockoutUntil = null;
    state = PinStatus.notSet;
  }
}

/// Provider for PIN state
final pinProvider = StateNotifierProvider<PinNotifier, PinStatus>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final pinService = ref.watch(pinServiceProvider);
  return PinNotifier(supabaseService, pinService);
});
