import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product_model.dart';
import '../../products/providers/product_providers.dart';
import '../../products/providers/recommendation_provider.dart';
import '../../providers/cart_provider.dart';
import '../../../widgets/product_card.dart';
import '../../../widgets/recommendation_carousel.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late TextEditingController _searchController;

  // Guard so a query is logged exactly once (not per keystroke / rebuild).
  String? _loggedQuery;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant SearchResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new query navigated in — allow logging it once results resolve.
    if (oldWidget.query != widget.query) {
      _loggedQuery = null;
      _searchController.text = widget.query;
    }
  }

  /// Logs the current query exactly once, then refreshes the search-based
  /// recommendation surfaces. Fire-and-forget; never throws.
  void _logSearchOnce(int resultCount) {
    if (_loggedQuery == widget.query) return;
    if (widget.query.trim().isEmpty) return;
    _loggedQuery = widget.query;
    SupabaseService.instance.logSearch(widget.query, resultCount).then((_) {
      if (!mounted) return;
      ref.invalidate(searchBasedRecommendationsProvider);
      ref.invalidate(mostRecentSearchQueryProvider);
    });
  }

  List<Product> _performSearch(List<Product> products) {
    if (widget.query.isEmpty) {
      return [];
    }
    final query = widget.query.toLowerCase();
    return products
        .where(
          (p) =>
              p.name.toLowerCase().contains(query) ||
              p.brand.toLowerCase().contains(query) ||
              p.category.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final isLoading = ref.watch(productsLoadingProvider);
    final results = _performSearch(products);

    // Log once the product catalogue has resolved so result_count is accurate.
    if (!isLoading) {
      final count = results.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _logSearchOnce(count));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search products...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade500),
          ),
          onSubmitted: (value) {
            context.go('/search?q=${Uri.encodeQueryComponent(value.trim())}');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => context.go(
              '/search?q=${Uri.encodeQueryComponent(_searchController.text.trim())}',
            ),
          ),
        ],
      ),
      body: isLoading && products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : results.isEmpty
          ? _buildEmptyState()
          : _buildSearchResults(results),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No results found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try different keywords',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        // Search-intent recommendations under the empty state.
        _buildEmptyStateRecommendations(),
      ],
    );
  }

  Widget _buildEmptyStateRecommendations() {
    final recsAsync = ref.watch(searchBasedRecommendationsProvider);
    return recsAsync.when(
      loading: () => const RecommendationCarousel(
        title: 'You might like these',
        subtitle: 'Based on your recent searches',
        icon: Icons.manage_search,
        products: [],
        isLoading: true,
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return RecommendationCarousel(
          title: 'You might like these',
          subtitle: 'Based on your recent searches',
          icon: Icons.manage_search,
          products: products,
        );
      },
    );
  }

  Widget _buildSearchResults(List<Product> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${results.length} result${results.length == 1 ? '' : 's'} for "${widget.query}"',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.55,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              return ProductCard(
                product: results[index],
                onTap: () => context.push('/product/${results[index].id}'),
                onAddToCart: () async {
                  try {
                    await ref
                        .read(cartProvider.notifier)
                        .addToCart(results[index]);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${results[index].name} added to cart!'),
                      ),
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error.toString())));
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
