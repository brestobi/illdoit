import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';
import '../errors/app_exceptions.dart';
import 'abstract_repositories.dart';

/// Concrete implementation of UserRepository using Supabase
class UserRepositoryImpl implements UserRepository {
  final SupabaseService _supabaseService;

  UserRepositoryImpl(this._supabaseService);

  @override
  Future<User> getCurrentUserProfile() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      throw AuthenticationException('No user logged in');
    }

    try {
      final data = await _supabaseService.query(
        table: 'users',
        filters: {'id': currentUser.id},
      );

      if (data.isEmpty) {
        throw ServerException('User profile not found');
      }

      return User.fromJson(data.first);
    } catch (e) {
      if (e is ServerException || e is AuthenticationException) rethrow;
      throw ServerException('Failed to fetch user profile: $e');
    }
  }

  @override
  Future<void> updateUserProfile({required Map<String, dynamic> data}) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      throw AuthenticationException('No user logged in');
    }

    try {
      await _supabaseService.update(
        table: 'users',
        id: currentUser.id,
        data: data,
      );
    } catch (e) {
      if (e is ServerException || e is AuthenticationException) rethrow;
      throw ServerException('Failed to update profile: $e');
    }
  }

  @override
  Future<String> uploadAvatar({required List<int> bytes}) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      throw AuthenticationException('No user logged in');
    }

    try {
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '${currentUser.id}/$fileName';
      
      final url = await _supabaseService.uploadFile(
        bucket: 'avatars',
        path: path,
        bytes: bytes,
      );
      
      // Update profile with new avatar URL
      await updateUserProfile(data: {'avatar_url': url});
      
      return url;
    } catch (e) {
      if (e is ServerException || e is AuthenticationException) rethrow;
      throw ServerException('Failed to upload avatar: $e');
    }
  }

  @override
  Future<User> getUserById({required String userId}) async {
    try {
      final data = await _supabaseService.query(
        table: 'users',
        filters: {'id': userId},
      );

      if (data.isEmpty) {
        throw ServerException('User not found');
      }

      return User.fromJson(data.first);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to fetch user: $e');
    }
  }

  @override
  Future<List<User>> searchUsers({
    required String query,
    String? category,
  }) async {
    try {
      final results = await _supabaseService.query(
        table: 'users',
        searchFilters: {'display_name': query},
      );

      return results.map((e) => User.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('Search failed: $e');
    }
  }

  @override
  Future<List<User>> getUsers({String? userType, int? limit}) async {
    try {
      final filters = userType != null ? {'user_type': userType} : null;
      final results = await _supabaseService.query(
        table: 'users',
        filters: filters,
      );
      
      final users = results.map((e) => User.fromJson(e)).toList();
      if (limit != null && users.length > limit) {
        return users.sublist(0, limit);
      }
      return users;
    } catch (e) {
      throw ServerException('Failed to fetch users: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUserReviews({required String userId}) async {
    try {
      return await _supabaseService.query(
        table: 'reviews',
        filters: {'target_user_id': userId},
      );
    } catch (e) {
      throw ServerException('Failed to fetch reviews: $e');
    }
  }

  @override
  Future<String> uploadVerificationDoc({required List<int> bytes, required String fileName}) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      final path = 'verification/${currentUser.id}/$fileName';
      return await _supabaseService.uploadFile(
        bucket: 'verification-docs',
        path: path,
        bytes: bytes,
      );
    } catch (e) {
      throw ServerException('Failed to upload verification document: $e');
    }
  }

  @override
  Future<void> submitVerification({
    required String idType,
    required String idFrontUrl,
    String? idBackUrl,
    String? selfieUrl,
  }) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      // In a real app, we'd save this to a 'verification_requests' table
      // For this MVP, we'll just update the user's metadata or a simple flag
      await _supabaseService.update(
        table: 'users',
        id: currentUser.id,
        data: {
          'is_verified': false, // Still false until admin approves
          'verification_status': 'pending',
          'verification_metadata': {
            'id_type': idType,
            'id_front_url': idFrontUrl,
            'id_back_url': idBackUrl,
            'selfie_url': selfieUrl,
            'submitted_at': DateTime.now().toIso8601String(),
          }
        },
      );
    } catch (e) {
      throw ServerException('Failed to submit verification: $e');
    }
  }

  @override
  Future<void> reportUser({
    required String targetUserId,
    required String reason,
    String? description,
  }) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      await _supabaseService.insert(
        table: 'user_reports',
        data: {
          'reporter_id': currentUser.id,
          'target_id': targetUserId,
          'reason': reason,
          'description': description,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw ServerException('Failed to submit report: $e');
    }
  }

  @override
  Future<void> blockUser({required String targetUserId}) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      await _supabaseService.insert(
        table: 'user_blocks',
        data: {
          'blocker_id': currentUser.id,
          'blocked_id': targetUserId,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw ServerException('Failed to block user: $e');
    }
  }

  @override
  Future<void> ensureProfileExists() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) return;

    try {
      final data = await _supabaseService.query(
        table: 'users',
        filters: {'id': currentUser.id},
      );

      if (data.isEmpty) {
        await _supabaseService.insert(
          table: 'users',
          data: {
            'id': currentUser.id,
            'email': currentUser.email,
            'display_name': currentUser.userMetadata?['full_name'] ?? currentUser.email?.split('@').first ?? 'User',
            'user_type': currentUser.userMetadata?['user_type'] ?? 'viewer',
            'verification_status': 'unverified',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
      } else {
        // Update display name if it's from social login and might have changed
        final metadataName = currentUser.userMetadata?['full_name'];
        if (metadataName != null && metadataName != data.first['display_name']) {
          await _supabaseService.update(
            table: 'users',
            id: currentUser.id,
            data: {
              'display_name': metadataName,
              'updated_at': DateTime.now().toIso8601String(),
            },
          );
        }
      }
    } catch (e) {
      // Log error but don't fail, as it might be handled by trigger now
    }
  }
}

/// Provider for UserRepository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return UserRepositoryImpl(supabaseService);
});
