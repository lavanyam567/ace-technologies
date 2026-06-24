import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../../../models/review_model.dart';
import '../../providers/auth_provider.dart';

class ReviewsState {
  final List<ProductReview> reviews;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  const ReviewsState({
    this.reviews = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  ReviewsState copyWith({
    List<ProductReview>? reviews,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return ReviewsState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
    );
  }

  double get averageRating {
    if (reviews.isEmpty) return 0;
    final total = reviews.fold<int>(0, (sum, review) => sum + review.rating);
    return total / reviews.length;
  }

  int ratingCount(int stars) {
    return reviews.where((review) => review.rating == stars).length;
  }

  double ratingPercentage(int stars) {
    if (reviews.isEmpty) return 0;
    return ratingCount(stars) / reviews.length;
  }

  ProductReview? currentUserReview(String? userId) {
    if (userId == null) return null;
    for (final review in reviews) {
      if (review.userId == userId) return review;
    }
    return null;
  }
}

class ReviewsNotifier extends StateNotifier<ReviewsState> {
  ReviewsNotifier(this.ref, this.productId) : super(const ReviewsState()) {
    Future.microtask(loadReviews);
  }

  final Ref ref;
  final String productId;

  Future<void> loadReviews() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final reviews = await SupabaseService.instance.fetchProductReviews(
        productId,
      );
      state = state.copyWith(reviews: reviews);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> submitReview({
    required int rating,
    required String title,
    required String content,
  }) async {
    final user = SupabaseService.instance.currentUser;
    if (state.currentUserReview(user?.id) != null) {
      state = state.copyWith(error: 'You have already reviewed this product.');
      throw StateError('You have already reviewed this product.');
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final comment = [
        title.trim(),
        content.trim(),
      ].where((value) => value.isNotEmpty).join('\n\n');
      final review = await SupabaseService.instance.submitProductReview(
        productId: productId,
        rating: rating,
        comment: comment,
      );
      state = state.copyWith(reviews: [review, ...state.reviews]);
    } catch (error) {
      state = state.copyWith(error: error.toString());
      rethrow;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}

final reviewsProvider =
    StateNotifierProvider.family<ReviewsNotifier, ReviewsState, String>((
      ref,
      productId,
    ) {
      final notifier = ReviewsNotifier(ref, productId);

      ref.listen<AuthState>(authProvider, (previous, next) {
        if (previous?.isAuthenticated != next.isAuthenticated) {
          notifier.loadReviews();
        }
      });

      return notifier;
    });

final currentUserReviewProvider = Provider.family<ProductReview?, String>((
  ref,
  productId,
) {
  final userId = SupabaseService.instance.currentUser?.id;
  return ref.watch(reviewsProvider(productId)).currentUserReview(userId);
});
