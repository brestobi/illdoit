import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../errors/app_exceptions.dart';
import 'abstract_repositories.dart';

/// Concrete implementation of ReviewRepository using Supabase
class ReviewRepositoryImpl implements ReviewRepository {

  ReviewRepositoryImpl(this._supabaseService);
  final SupabaseService _supabaseService;

  @override
  Future<Map<String, dynamic>> createReview({
    required String targetUserId,
    required int rating,
    required String comment,
    String? serviceId,
  }) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      throw AuthenticationException('No user logged in');
    }

    try {
      final reviewData = {
        'reviewer_id': currentUser.id,
        'target_user_id': targetUserId,
        'service_id': serviceId,
        'rating': rating,
        'comment': comment,
      };

      final response = await _supabaseService.insert(
        table: 'reviews',
        data: reviewData,
      );

      await _recalculateTargetRating(targetUserId);
      // Also recalculate service rating if review is tied to a service
      if (serviceId != null) {
        await _recalculateServiceRating(serviceId);
      }
      return response;
    } catch (e) {
      if (e is ServerException || e is AuthenticationException) rethrow;
      throw ServerException('Failed to create review: $e');
    }
  }

  @override
  Future<void> deleteReview({required String reviewId}) async {
    try {
      // Fetch the review first to get service_id before deleting
      final reviews = await _supabaseService.query(
        table: 'reviews',
        filters: {'id': reviewId},
      );
      final serviceId = reviews.isNotEmpty ? reviews.first['service_id'] as String? : null;

      await _supabaseService.delete(table: 'reviews', id: reviewId);

      // Recalculate ratings after deletion
      if (serviceId != null) {
        await _recalculateServiceRating(serviceId);
      }
    } catch (e) {
      throw ServerException('Failed to delete review: $e');
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
  Future<void> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
  }) async {
    try {
      final updated = await _supabaseService.update(
        table: 'reviews',
        id: reviewId,
        data: {
          'rating': rating,
          'comment': comment,
        },
      );

      final targetUserId = updated['target_user_id'] as String?;
      if (targetUserId != null) {
        await _recalculateTargetRating(targetUserId);
      }
      final serviceId = updated['service_id'] as String?;
      if (serviceId != null) {
        await _recalculateServiceRating(serviceId);
      }
    } catch (e) {
      throw ServerException('Failed to update review: $e');
    }
  }

  /// Recalculate and update the average rating for a service.
  Future<void> _recalculateServiceRating(String serviceId) async {
    final reviews = await _supabaseService.query(
      table: 'reviews',
      filters: {'service_id': serviceId},
    );

    if (reviews.isEmpty) {
      await _supabaseService.update(
        table: 'services',
        id: serviceId,
        data: {'rating': 0},
      );
      return;
    }

    final totalRating = reviews
        .map((review) => (review['rating'] as num).toDouble())
        .reduce((a, b) => a + b);
    final averageRating = totalRating / reviews.length;

    await _supabaseService.update(
      table: 'services',
      id: serviceId,
      data: {'rating': averageRating},
    );
  }

  Future<void> _recalculateTargetRating(String targetUserId) async {
    final reviews = await _supabaseService.query(
      table: 'reviews',
      filters: {'target_user_id': targetUserId},
    );

    if (reviews.isEmpty) {
      await _supabaseService.update(
        table: 'users',
        id: targetUserId,
        data: {'rating': 0},
      );
      return;
    }

    final totalRating = reviews
        .map((review) => (review['rating'] as num).toDouble())
        .reduce((a, b) => a + b);
    final averageRating = totalRating / reviews.length;

    await _supabaseService.update(
      table: 'users',
      id: targetUserId,
      data: {'rating': averageRating},
    );
  }
}

/// Provider for ReviewRepository
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return ReviewRepositoryImpl(supabaseService);
});