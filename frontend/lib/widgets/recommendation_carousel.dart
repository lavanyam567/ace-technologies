import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'cached_image.dart';
import '../models/product_model.dart';
import '../core/theme/app_theme.dart';
import '../features/products/providers/recommendation_provider.dart';
import '../features/providers/auth_provider.dart';

// ────────────────────────────────────────────────────────────────────────────
// RecommendationCarousel
// A full-featured carousel for "Recommended for You" and "Similar Products".
// ────────────────────────────────────────────────────────────────────────────

class RecommendationCarousel extends ConsumerWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Product> products;
  final bool isLoading;

  const RecommendationCarousel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.products,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isLoading && products.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Horizontal scroll list ───────────────────────────────
          SizedBox(
            height: 234,
            child: isLoading
                ? _buildShimmer()
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return _RecommendationCard(
                        product: products[index],
                        onTap: () =>
                            context.push('/product/${products[index].id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        itemCount: 4,
        itemBuilder: (_, _) => Container(
          width: 148,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Personalised Carousel — pulls from recommendationsProvider
// ────────────────────────────────────────────────────────────────────────────

class PersonalisedRecommendationCarousel extends ConsumerWidget {
  const PersonalisedRecommendationCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated) return const SizedBox.shrink();

    final recommendationsAsync = ref.watch(recommendationsProvider);

    return recommendationsAsync.when(
      loading: () => RecommendationCarousel(
        title: 'Recommended for You',
        subtitle: 'Based on your activity',
        icon: Icons.auto_awesome,
        products: const [],
        isLoading: true,
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (products) => RecommendationCarousel(
        title: 'Recommended for You',
        subtitle: 'Personalised picks for you',
        icon: Icons.auto_awesome,
        products: products,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Search-Intent Carousel — pulls from searchBasedRecommendationsProvider
// Hidden entirely when there are no search-based recommendations.
// ────────────────────────────────────────────────────────────────────────────

class SearchBasedRecommendationCarousel extends ConsumerWidget {
  const SearchBasedRecommendationCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated) return const SizedBox.shrink();

    final recsAsync = ref.watch(searchBasedRecommendationsProvider);
    final recentQuery = ref.watch(mostRecentSearchQueryProvider).valueOrNull;

    final subtitle = (recentQuery != null && recentQuery.trim().isNotEmpty)
        ? 'Based on "$recentQuery"'
        : 'Based on your recent searches';

    return recsAsync.when(
      loading: () => RecommendationCarousel(
        title: 'Because You Searched',
        subtitle: subtitle,
        icon: Icons.manage_search,
        products: const [],
        isLoading: true,
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (products) {
        // Hide entirely when empty.
        if (products.isEmpty) return const SizedBox.shrink();
        return RecommendationCarousel(
          title: 'Because You Searched',
          subtitle: subtitle,
          icon: Icons.manage_search,
          products: products,
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Similar Products Carousel — pulls from similarProductsProvider
// ────────────────────────────────────────────────────────────────────────────

class SimilarProductsCarousel extends ConsumerWidget {
  final String productId;

  const SimilarProductsCarousel({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similarAsync = ref.watch(similarProductsProvider(productId));

    return similarAsync.when(
      loading: () => RecommendationCarousel(
        title: 'Similar Products',
        subtitle: 'You might also like these',
        icon: Icons.grid_view_rounded,
        products: const [],
        isLoading: true,
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (products) => RecommendationCarousel(
        title: 'Similar Products',
        subtitle: 'From the same category',
        icon: Icons.grid_view_rounded,
        products: products,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Individual product card used inside the carousel
// ────────────────────────────────────────────────────────────────────────────

class _RecommendationCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const _RecommendationCard({required this.product, required this.onTap});

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 148,
          margin: const EdgeInsets.only(right: 12),
          transform: _hovered
              ? (Matrix4.identity()..translate(0.0, -4.0, 0.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? 0.08 : 0.04),
                blurRadius: _hovered ? 18 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image (AceImage renders a native <img> on web,
              // which loads cross-origin images that CachedNetworkImage can't).
              Stack(
                children: [
                  Container(
                    width: 148,
                    height: 110,
                    color: Colors.grey.shade50,
                    child: AceImage(
                      url: widget.product.safeImage,
                      width: 148,
                      height: 110,
                      fit: BoxFit.cover,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                  ),
                  // Discount badge (overlaid, top-left)
                  if (widget.product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.product.discount}% OFF',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Rating pill (overlaid, top-right)
                  if (widget.product.rating > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 11, color: Color(0xFFFFC107)),
                            const SizedBox(width: 2),
                            Text(
                              widget.product.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              // Brand + name
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.product.brand.isNotEmpty)
                      Text(
                        widget.product.brand.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      widget.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Price row (current + strikethrough original)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        widget.product.formattedPrice,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    if (widget.product.hasDiscount &&
                        widget.product.formattedOriginalPrice.isNotEmpty) ...[
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          widget.product.formattedOriginalPrice,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
