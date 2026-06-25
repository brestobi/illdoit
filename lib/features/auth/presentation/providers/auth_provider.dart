import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/repositories/user_repository_impl.dart';
import '../../../../core/models/user.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

/// State for authentication
class AuthState {

  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
    this.suspensionMessage,
  });
  final bool isLoading;
  final String? errorMessage;
  final supabase.User? user;
  final String? suspensionMessage;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    supabase.User? user,
    String? suspensionMessage,
  }) => AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      user: user ?? this.user,
      suspensionMessage: suspensionMessage ?? this.suspensionMessage,
    );
}

/// Notifier for authentication state
class AuthNotifier extends StateNotifier<AuthState> {

  AuthNotifier(this._supabaseService, this._ref) : super(AuthState(user: _supabaseService.currentUser)) {
    // Listen to auth state changes
    _authSubscription = _supabaseService.authStateChanges.listen((event) async {
      final user = event.session?.user;
      state = state.copyWith(user: user, isLoading: false);
      
      // If user just signed in or token refreshed, ensure profile exists
      if (user != null && (event.event == supabase.AuthChangeEvent.signedIn || event.event == supabase.AuthChangeEvent.tokenRefreshed)) {
        _ref.read(userRepositoryProvider).ensureProfileExists();
        _ref.read(notificationServiceProvider).updateToken();
        // Check if user is suspended/banned
        await _checkSuspension();
      }
    });

    // Start periodic suspension polling when authenticated
    _startSuspensionPolling();
  }
  final SupabaseService _supabaseService;
  final Ref _ref;
  StreamSubscription<supabase.AuthState>? _authSubscription;
  Timer? _suspensionTimer;

  /// Check if the current user's account is suspended or banned.
  /// If so, sign them out and set a suspension message.
  Future<void> _checkSuspension() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) return;

    try {
      final data = await _supabaseService.query(
        table: 'users',
        filters: {'id': currentUser.id},
      );

      if (data.isEmpty) return;

      final accountStatus = data.first['account_status'] as String? ?? 'active';
      final suspensionReason = data.first['suspension_reason'] as String?;

      if (accountStatus == 'suspended' || accountStatus == 'banned') {
        final message = accountStatus == 'suspended'
            ? 'Your account has been suspended.\nReason: ${suspensionReason ?? "No reason provided"}\n\nPlease contact support for assistance.'
            : 'Your account has been permanently banned.\nReason: ${suspensionReason ?? "No reason provided"}\n\nThis action cannot be reversed.';

        await _supabaseService.signOut();
        state = state.copyWith(
          user: null,
          suspensionMessage: message,
        );
      }
    } catch (_) {
      // Silently fail — don't block the user on a check error
    }
  }

  /// Poll for suspension status every 30 seconds while the user is browsing.
  /// Unlike [_checkSuspension], this does NOT sign the user out — it only
  /// updates [suspensionMessage] so the in-app [SuspensionBanner] appears.
  Future<void> _pollSuspensionStatus() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      // If signed out, clear any stale suspension message
      if (state.suspensionMessage != null) {
        state = state.copyWith(suspensionMessage: null);
      }
      return;
    }

    try {
      final data = await _supabaseService.query(
        table: 'users',
        filters: {'id': currentUser.id},
      );

      if (data.isEmpty) return;

      final accountStatus = data.first['account_status'] as String? ?? 'active';
      final suspensionReason = data.first['suspension_reason'] as String?;

      if (accountStatus == 'suspended' || accountStatus == 'banned') {
        final message = accountStatus == 'suspended'
            ? 'Your account has been suspended.\nReason: ${suspensionReason ?? "No reason provided"}\n\nPlease contact support for assistance.'
            : 'Your account has been permanently banned.\nReason: ${suspensionReason ?? "No reason provided"}\n\nThis action cannot be reversed.';

        // Set suspension message without signing out — the in-app banner handles the UI
        if (state.suspensionMessage != message) {
          state = state.copyWith(suspensionMessage: message);
        }
      } else {
        // Account is active — clear any stale suspension message
        if (state.suspensionMessage != null) {
          state = state.copyWith(suspensionMessage: null);
        }
      }
    } catch (_) {
      // Silently fail on polling errors
    }
  }

  /// Start a periodic timer to poll suspension status every 30 seconds.
  void _startSuspensionPolling() {
    _suspensionTimer?.cancel();
    _suspensionTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _pollSuspensionStatus(),
    );
  }

  @override
  void dispose() {
    _suspensionTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _supabaseService.signUpWithEmail(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );
      
      // Ensure profile exists immediately
      await _ref.read(userRepositoryProvider).ensureProfileExists();
      _ref.invalidate(profileProvider);
      
      // Update push token
      await _ref.read(notificationServiceProvider).updateToken();
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _supabaseService.signInWithEmail(
        email: email,
        password: password,
      );
      
      // Ensure profile exists immediately
      await _ref.read(userRepositoryProvider).ensureProfileExists();
      _ref.invalidate(profileProvider);
      
      // Update push token
      await _ref.read(notificationServiceProvider).updateToken();
      
      // Check if user is suspended/banned
      await _checkSuspension();
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _supabaseService.signInWithGoogle();
      // Note: We don't set isLoading to false here because the actual 
      // sign-in happens when the user returns from the browser.
      // The authStateChanges listener will handle the session.
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null, suspensionMessage: null);
    try {
      await _supabaseService.signOut();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Reset password
  Future<void> resetPassword({required String email}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _supabaseService.resetPassword(email: email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Sign in with phone
  Future<void> signInWithPhone({required String phone}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _supabaseService.signInWithPhone(phone: phone);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Sign in with Email OTP
  Future<void> signInWithEmailOtp({required String email}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _supabaseService.signInWithEmailOtp(email: email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Verify OTP
  Future<void> verifyOTP({
    String? phone,
    String? email,
    required String token,
    required supabase.OtpType type,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _supabaseService.verifyOTP(
        phone: phone,
        email: email,
        token: token,
        type: type,
      );
      
      // Ensure profile exists immediately
      await _ref.read(userRepositoryProvider).ensureProfileExists();
      _ref.invalidate(profileProvider);
      
      // Update push token
      await _ref.read(notificationServiceProvider).updateToken();
      
      // Check if user is suspended/banned
      await _checkSuspension();
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return AuthNotifier(supabaseService, ref);
});
