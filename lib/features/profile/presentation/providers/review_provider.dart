import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/review_repository_impl.dart';
import '../../../../core/repositories/abstract_repositories.dart';

/// Provider for reviews for a particular user
final userReviewsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final reviewRepository = ref.watch(reviewRepositoryProvider);
  return reviewRepository.getUserReviews(userId: userId);
});

/// Review creation and state management
class ReviewState {

  ReviewState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  ReviewState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) => ReviewState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
}

class ReviewNotifier extends StateNotifier<ReviewState> {

  ReviewNotifier(this._reviewRepository, this._ref) : super(ReviewState());
  final ReviewRepository _reviewRepository;
  final Ref _ref;

  Future<void> createReview({
    required String targetUserId,
    required int rating,
    required String comment,
    String? serviceId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      await _reviewRepository.createReview(
        targetUserId: targetUserId,
        rating: rating,
        comment: comment,
        serviceId: serviceId,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      _ref.invalidate(userReviewsProvider(targetUserId));
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }
}

final reviewNotifierProvider = StateNotifierProvider<ReviewNotifier, ReviewState>((ref) {
  final reviewRepository = ref.watch(reviewRepositoryProvider);
  return ReviewNotifier(reviewRepository, ref);
});