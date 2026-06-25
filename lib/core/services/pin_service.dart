import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for hashing and verifying wallet PINs.
///
/// PINs are hashed with SHA-256 using a user-specific salt
/// (the user's ID) to prevent identical PINs across users
/// from producing identical hashes.
class PinService {
  /// Hash a plaintext PIN for a given user.
  /// The salt is the user's ID, ensuring unique hashes per user.
  String hashPin({required String pin, required String userId}) {
    final bytes = utf8.encode('$pin:$userId');
    return sha256.convert(bytes).toString();
  }

  /// Verify a plaintext PIN against a stored hash.
  bool verifyPin({
    required String pin,
    required String userId,
    required String storedHash,
  }) {
    final computedHash = hashPin(pin: pin, userId: userId);
    return computedHash == storedHash;
  }

  /// Validate that a PIN meets strength requirements:
  /// - Exactly 4 digits
  /// - Contains only numeric characters
  bool isValidPin(String pin) {
    if (pin.length != 4) return false;
    return RegExp(r'^\d{4}$').hasMatch(pin);
  }
}

/// Singleton provider for PinService
final pinServiceProvider = Provider<PinService>((ref) => PinService());
