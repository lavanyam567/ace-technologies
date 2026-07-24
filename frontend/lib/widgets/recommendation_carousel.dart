import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
            height: 220,
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
        itemBuilder: (_, __) => Container(
          width: 148,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
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
      error: (_, __) => const SizedBox.shrink(),
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
      error: (_, __) => const SizedBox.shrink(),
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
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? 0.12 : 0.06),
                blurRadius: _hovered ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: CachedNetworkImage(
                  imageUrl: widget.product.safeImage,
                  width: 148,
                  height: 110,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: Icon(Icons.image_outlined, color: Colors.grey),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.broken_image_outlined,
                        color: Colors.grey),
                  ),
                ),
              ),
              // Discount badge
              if (widget.product.hasDiscount)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.product.discount}% OFF',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 8),
              // Product name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
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
              ),
              const Spacer(),
              // Price
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(
                  widget.product.formattedPrice,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
