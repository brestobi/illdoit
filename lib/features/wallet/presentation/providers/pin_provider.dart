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
      // On error, assume locked — don't expose account info
      state = PinStatus.locked;
    }
  }

  /// Verify the entered PIN against the stored hash.
  /// Returns true if verified, false otherwise.
  Future<bool> verifyPin(String pin) async {
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
        state = PinStatus.unlocked;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Set a new PIN for the current user.
  /// Hashes it with the user's ID and stores in Supabase.
  Future<void> setPin(String pin) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final hashedPin = _pinService.hashPin(pin: pin, userId: userId);

    await _supabaseService.update(
      table: 'users',
      id: userId,
      data: {'pin_hash': hashedPin},
    );

    state = PinStatus.unlocked;
  }

  /// Lock the wallet (e.g., on app background or manual lock).
  void lock() {
    state = PinStatus.locked;
  }

  /// Reset to locked on sign-out / user change.
  void reset() {
    state = PinStatus.notSet;
  }
}

/// Provider for PIN state
final pinProvider = StateNotifierProvider<PinNotifier, PinStatus>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final pinService = ref.watch(pinServiceProvider);
  return PinNotifier(supabaseService, pinService);
});
