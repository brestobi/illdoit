import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase show Provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/app_exceptions.dart';

/// Supabase service provider
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// Service for Supabase operations
class SupabaseService {
  static Supabase? _instance;

  SupabaseClient get client {
    if (Supabase.instance.client == null) {
      throw ServerException('Supabase not initialized');
    }
    return Supabase.instance.client;
  }

  User? get currentUser => client.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Sign up with email and password
  Future<User> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
      return response.user!;
    } on AuthException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw ServerException('Sign up failed: $e');
    }
  }

  /// Sign in with email and password
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user!;
    } on AuthException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw ServerException('Sign in failed: $e');
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      final response = await client.auth.signInWithOAuth(
        supabase.Provider.google,
        redirectTo: 'io.supabase.flutter://callback',
      );
      return response;
    } on AuthException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw ServerException('Google sign in failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } on AuthException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw ServerException('Sign out failed: $e');
    }
  }

  /// Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw ServerException('Password reset failed: $e');
    }
  }

  /// Sign in with OTP (Phone)
  Future<void> signInWithPhone({required String phone}) async {
    try {
      await client.auth.signInWithOtp(phone: phone);
    } on AuthException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw ServerException('Phone sign in failed: $e');
    }
  }

  /// Verify OTP
  Future<User> verifyOTP({
    required String phone,
    required String token,
  }) async {
    try {
      final response = await client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      return response.user!;
    } on AuthException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw ServerException('OTP verification failed: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required Map<String, dynamic> data,
  }) async {
    try {
      await client.auth.updateUser(
        UserAttributes(data: data),
      );
    } on AuthException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw ServerException('Profile update failed: $e');
    }
  }

  /// Perform a query
  Future<List<Map<String, dynamic>>> query({
    required String table,
    String? select,
    Map<String, dynamic>? filters,
    Map<String, String>? searchFilters,
  }) async {
    try {
      var query = client.from(table).select(select ?? '*');

      if (filters != null) {
        filters.forEach((key, value) {
          if (value is List) {
            query = query.filter(key, 'in', value);
          } else {
            query = query.eq(key, value);
          }
        });
      }

      if (searchFilters != null) {
        searchFilters.forEach((key, value) {
          query = query.ilike(key, '%$value%');
        });
      }

      final response = await query;
      return (response as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      print('Supabase query error on table $table: $e');
      throw ServerException('Query failed: $e');
    }
  }

  /// Insert data
  Future<Map<String, dynamic>> insert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await client.from(table).insert(data).select();
      return Map<String, dynamic>.from((response as List).first as Map);
    } catch (e) {
      print('Supabase insert error on table $table: $e');
      throw ServerException('Insert failed: $e');
    }
  }

  /// Update data
  Future<Map<String, dynamic>> update({
    required String table,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await client
          .from(table)
          .update(data)
          .eq('id', id)
          .select();
      return Map<String, dynamic>.from((response as List).first as Map);
    } catch (e) {
      print('Supabase update error on table $table: $e');
      throw ServerException('Update failed: $e');
    }
  }

  /// Delete data
  Future<void> delete({
    required String table,
    required String id,
  }) async {
    try {
      await client.from(table).delete().eq('id', id);
    } catch (e) {
      throw ServerException('Delete failed: $e');
    }
  }

  /// Upload file to storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required List<int> bytes,
  }) async {
    try {
      final response = await client.storage.from(bucket).uploadBinary(
            path,
            Uint8List.fromList(bytes),
          );
      return client.storage.from(bucket).getPublicUrl(response);
    } catch (e) {
      throw ServerException('File upload failed: $e');
    }
  }

  /// Delete file from storage
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await client.storage.from(bucket).remove([path]);
    } catch (e) {
      throw ServerException('File deletion failed: $e');
    }
  }
}
