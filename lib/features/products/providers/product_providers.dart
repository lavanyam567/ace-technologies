import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/product_model.dart';

/// Product filter state
class ProductFilter {
  final String category;
  final String searchQuery;
  final String sortBy;
  final double? minPrice;
  final double? maxPrice;
  final List<String> brands;
  final bool inStockOnly;
  final String discountFilter;

  const ProductFilter({
    this.category = 'All',
    this.searchQuery = '',
    this.sortBy = 'Featured',
    this.minPrice,
    this.maxPrice,
    this.brands = const [],
    this.inStockOnly = false,
    this.discountFilter = 'All',
  });

  ProductFilter copyWith({
    String? category,
    String? searchQuery,
    String? sortBy,
    double? minPrice,
    double? maxPrice,
    List<String>? brands,
    bool? inStockOnly,
    String? discountFilter,
  }) {
    return ProductFilter(
      category: category ?? this.category,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      brands: brands ?? this.brands,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      discountFilter: discountFilter ?? this.discountFilter,
    );
  }
}

/// Product filter notifier
class ProductFilterNotifier extends StateNotifier<ProductFilter> {
  ProductFilterNotifier() : super(const ProductFilter());

  void setCategory(String category) {
    state = state.copyWith(category: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void setPriceRange(double? min, double? max) {
    state = state.copyWith(minPrice: min, maxPrice: max);
  }

  void toggleBrand(String brand) {
    final brands = List<String>.from(state.brands);
    if (brands.contains(brand)) {
      brands.remove(brand);
    } else {
      brands.add(brand);
    }
    state = state.copyWith(brands: brands);
  }

  void setInStockOnly(bool value) {
    state = state.copyWith(inStockOnly: value);
  }

  void setDiscountFilter(String discountFilter) {
    state = state.copyWith(discountFilter: discountFilter);
  }

  void updateFilter({
    String? sortBy,
    double? minPrice,
    double? maxPrice,
    List<String>? categories,
    List<String>? brands,
    bool? inStockOnly,
  }) {
    state = state.copyWith(
      sortBy: _sortLabel(sortBy) ?? state.sortBy,
      category: categories != null && categories.isNotEmpty
          ? categories.first
          : state.category,
      minPrice: minPrice,
      maxPrice: maxPrice,
      brands: brands,
      inStockOnly: inStockOnly,
    );
  }

  String? _sortLabel(String? sortBy) {
    switch (sortBy) {
      case 'newest':
        return 'Newest';
      case 'price_low':
        return 'Price: Low to High';
      case 'price_high':
        return 'Price: High to Low';
      case 'rating':
        return 'Rating';
      default:
        return sortBy;
    }
  }

  void reset() {
    state = const ProductFilter();
  }
}

final productFilterProvider =
    StateNotifierProvider<ProductFilterNotifier, ProductFilter>((ref) {
      return ProductFilterNotifier();
    });

class ProductsNotifier extends StateNotifier<List<Product>> {
  ProductsNotifier(this.ref) : super([]) {
    Future.microtask(loadProducts);
  }

  final Ref ref;

  Future<void> loadProducts() async {
    ref.read(productsLoadingProvider.notifier).state = true;
    ref.read(productsErrorProvider.notifier).state = null;

    try {
      final products = await SupabaseService.instance.fetchProducts();
      state = products;
    } catch (error) {
      state = [];
      ref.read(productsErrorProvider.notifier).state = error.toString();
    } finally {
      ref.read(productsLoadingProvider.notifier).state = false;
    }
  }
}

final productsProvider = StateNotifierProvider<ProductsNotifier, List<Product>>(
  (ref) {
    return ProductsNotifier(ref);
  },
);

final productsLoadingProvider = StateProvider<bool>((ref) => false);

final productsErrorProvider = StateProvider<String?>((ref) => null);

/// Filtered products provider
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final filter = ref.watch(productFilterProvider);
  var products = ref.watch(productsProvider);

  // Filter by category
  if (filter.category != 'All') {
    products = products.where((p) => p.category == filter.category).toList();
  }

  // Filter by search
  if (filter.searchQuery.isNotEmpty) {
    final query = filter.searchQuery.toLowerCase().trim();
    products = products
        .where(
          (p) => [
            p.name,
            p.brand,
            p.category,
            p.description,
            p.id,
          ].any((value) => value.toLowerCase().contains(query)),
        )
        .toList();
  }

  // Filter by price range
  if (filter.minPrice != null) {
    products = products.where((p) => p.price >= filter.minPrice!).toList();
  }
  if (filter.maxPrice != null) {
    products = products.where((p) => p.price <= filter.maxPrice!).toList();
  }

  // Filter by brands
  if (filter.brands.isNotEmpty) {
    products = products.where((p) => filter.brands.contains(p.brand)).toList();
  }

  // Filter out of stock
  if (filter.inStockOnly) {
    products = products.where((p) => !p.isOutOfStock).toList();
  }

  // Filter by discount
  switch (filter.discountFilter) {
    case 'below15':
      products = products
          .where((p) => p.discount > 0 && p.discount < 15)
          .toList();
      break;
    case '15plus':
      products = products.where((p) => p.discount >= 15).toList();
      break;
    case '30plus':
      products = products.where((p) => p.discount >= 30).toList();
      break;
  }

  // Sort
  switch (filter.sortBy) {
    case 'Price: Low to High':
      products.sort((a, b) => a.price.compareTo(b.price));
      break;
    case 'Price: High to Low':
      products.sort((a, b) => b.price.compareTo(a.price));
      break;
    case 'Rating':
      products.sort((a, b) => b.rating.compareTo(a.rating));
      break;
    case 'Newest':
      products.sort((a, b) => b.id.compareTo(a.id));
      break;
    default:
      break;
  }

  return products;
});

/// All categories provider
final categoriesProvider = Provider<List<String>>((ref) {
  return [
    'All',
    'Processors',
    'Laptops',
    'Networking',
    'Printers',
    'Servers',
    'CCTV Cameras',
    'Fire Alarms',
    'Door Access',
    'RAM',
    'Hard Disk',
    'Keyboard',
    'Mouse',
    'Monitor',
  ];
});

/// Sort options provider
final sortOptionsProvider = Provider<List<String>>((ref) {
  return [
    'Featured',
    'Price: Low to High',
    'Price: High to Low',
    'Newest',
    'Rating',
  ];
});

/// Featured products provider
final featuredProductsProvider = Provider<List<Product>>((ref) {
  return ref.watch(productsProvider).take(6).toList();
});

/// Product by ID provider
final productByIdProvider = Provider.family<Product?, String>((ref, id) {
  try {
    return ref.watch(productsProvider).firstWhere((p) => p.id == id);
  } catch (e) {
    return null;
  }
});

/// Products by category provider
final productsByCategoryProvider = Provider.family<List<Product>, String>((
  ref,
  category,
) {
  final products = ref.watch(productsProvider);
  if (category == 'All') return products;
  return products.where((p) => p.category == category).toList();
});

/// All products provider
final allProductsProvider = Provider<List<Product>>((ref) {
  return ref.watch(productsProvider);
});

/// Recently viewed products notifier
class RecentlyViewedNotifier extends StateNotifier<List<Product>> {
  RecentlyViewedNotifier() : super([]) {
    Future.microtask(loadHistory);
  }

  Future<void> loadHistory() async {
    try {
      state = await SupabaseService.instance.fetchRecentlyViewedProducts();
    } catch (_) {
      state = [];
    }
  }

  Future<void> addToRecent(Product product) async {
    state = state.where((p) => p.id != product.id).toList();
    state = [product, ...state];
    if (state.length > 10) {
      state = state.sublist(0, 10);
    }
    await SupabaseService.instance.addRecentlyViewedProduct(product);
  }

  Future<void> clearHistory() async {
    state = [];
    await SupabaseService.instance.clearRecentlyViewedProducts();
  }
}

final recentlyViewedProvider =
    StateNotifierProvider<RecentlyViewedNotifier, List<Product>>((ref) {
      return RecentlyViewedNotifier();
    });

/// Compare products notifier
class CompareProductsNotifier extends StateNotifier<List<String>> {
  CompareProductsNotifier() : super([]) {
    Future.microtask(loadCompare);
  }

  Future<void> loadCompare() async {
    try {
      state = await SupabaseService.instance.fetchCompareProductIds();
    } catch (_) {
      state = [];
    }
  }

  Future<void> toggleCompare(String productId) async {
    if (state.contains(productId)) {
      await removeFromCompare(productId);
    } else {
      await addToCompare(productId);
    }
  }

  Future<void> addToCompare(String productId) async {
    if (!state.contains(productId) && state.length < 4) {
      state = [...state, productId];
      await SupabaseService.instance.addCompareProduct(productId);
    }
  }

  Future<void> removeFromCompare(String productId) async {
    state = state.where((id) => id != productId).toList();
    await SupabaseService.instance.removeCompareProduct(productId);
  }

  Future<void> clearCompare() async {
    state = [];
    await SupabaseService.instance.clearCompareProducts();
  }
}

final compareProductsProvider =
    StateNotifierProvider<CompareProductsNotifier, List<String>>((ref) {
      return CompareProductsNotifier();
    });
