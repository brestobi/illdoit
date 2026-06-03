import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/repositories/user_repository_impl.dart';

/// State for authentication
class AuthState {

  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
  });
  final bool isLoading;
  final String? errorMessage;
  final supabase.User? user;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    supabase.User? user,
  }) => AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
}

/// Notifier for authentication state
class AuthNotifier extends StateNotifier<AuthState> {

  AuthNotifier(this._supabaseService, this._ref) : super(AuthState(user: _supabaseService.currentUser)) {
    // Listen to auth state changes
    _supabaseService.authStateChanges.listen((event) {
      final user = event.session?.user;
      state = state.copyWith(user: user, isLoading: false);
      
      // If user just signed in or token refreshed, ensure profile exists
      if (user != null && (event.event == supabase.AuthChangeEvent.signedIn || event.event == supabase.AuthChangeEvent.tokenRefreshed)) {
        _ref.read(userRepositoryProvider).ensureProfileExists();
        _ref.read(notificationServiceProvider).updateToken();
      }
    });
  }
  final SupabaseService _supabaseService;
  final Ref _ref;

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
      
      // Update push token
      await _ref.read(notificationServiceProvider).updateToken();
      
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
    state = state.copyWith(isLoading: true, errorMessage: null);
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
      
      // Update push token
      await _ref.read(notificationServiceProvider).updateToken();
      
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
