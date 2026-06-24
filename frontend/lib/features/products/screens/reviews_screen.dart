import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/review_model.dart';
import '../../products/providers/product_providers.dart';
import '../../products/providers/review_provider.dart';

class ReviewsScreen extends ConsumerWidget {
  final String productId;

  const ReviewsScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productByIdProvider(productId));
    final reviewsState = ref.watch(reviewsProvider(productId));
    final reviews = reviewsState.reviews;
    final averageRating = reviews.isEmpty
        ? product?.rating ?? 0
        : reviewsState.averageRating;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Reviews',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/product/$productId/write-review'),
            icon: const Icon(Icons.rate_review),
            label: const Text('Write Review'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Rating Summary
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Overall Rating
                Column(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < averageRating.floor()
                              ? Icons.star
                              : Icons.star_border,
                          color: AppTheme.warningColor,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${reviews.length} reviews',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                // Rating Bars
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1].map((stars) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              '$stars',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: AppTheme.warningColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: reviewsState.ratingPercentage(stars),
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: const AlwaysStoppedAnimation(
                                    AppTheme.warningColor,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${reviewsState.ratingCount(stars)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          if (reviewsState.error != null)
            Container(
              width: double.infinity,
              color: AppTheme.errorColor.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 18,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reviewsState.error!,
                      style: const TextStyle(color: AppTheme.errorColor),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(reviewsProvider(productId).notifier)
                        .loadReviews(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // Reviews List
          Expanded(
            child: reviewsState.isLoading && reviews.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : reviews.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(reviewsProvider(productId).notifier)
                        .loadReviews(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        return _buildReviewCard(context, reviews[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'No reviews yet',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Be the first to review this product.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, ProductReview review) {
    final displayName = review.userName.trim().isEmpty
        ? 'Customer'
        : review.userName.trim();
    final initial = displayName.characters.first.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: AppTheme.warningColor,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('d MMM yyyy').format(review.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            review.content,
            style: TextStyle(color: Colors.grey.shade700, height: 1.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Helpful?',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.thumb_up_outlined, size: 18),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              const Text('0', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.thumb_down_outlined, size: 18),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
