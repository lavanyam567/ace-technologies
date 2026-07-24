import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../../../models/product_model.dart';
import '../../providers/auth_provider.dart';

// ──────────────────────────────────────────────────────────────
// Personalised recommendations (collaborative filtering)
// ──────────────────────────────────────────────────────────────

class RecommendationsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    // Re-fetch whenever auth state changes
    ref.watch(authProvider);
    return SupabaseService.instance.fetchRecommendations();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => SupabaseService.instance.fetchRecommendations(),
    );
  }
}

final recommendationsProvider =
    AsyncNotifierProvider<RecommendationsNotifier, List<Product>>(
  RecommendationsNotifier.new,
);

// ──────────────────────────────────────────────────────────────
// Search-intent recommendations ("Because You Searched")
// ──────────────────────────────────────────────────────────────

class SearchBasedRecommendationsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    // Re-fetch whenever auth state changes
    ref.watch(authProvider);
    return SupabaseService.instance.fetchSearchBasedRecommendations();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => SupabaseService.instance.fetchSearchBasedRecommendations(),
    );
  }
}

final searchBasedRecommendationsProvider =
    AsyncNotifierProvider<SearchBasedRecommendationsNotifier, List<Product>>(
  SearchBasedRecommendationsNotifier.new,
);

// The user's most recent search query — powers the carousel subtitle.
final mostRecentSearchQueryProvider = FutureProvider<String?>((ref) async {
  ref.watch(authProvider);
  return SupabaseService.instance.fetchMostRecentSearchQuery();
});

// ──────────────────────────────────────────────────────────────
// Similar products (content-based, by category)
// ──────────────────────────────────────────────────────────────

final similarProductsProvider =
    FutureProvider.family<List<Product>, String>((ref, productId) async {
  return SupabaseService.instance.fetchSimilarProducts(productId);
});
