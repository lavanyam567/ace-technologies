import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../../../models/product_model.dart';
import '../../providers/auth_provider.dart';

/// Wishlist state notifier backed by Supabase for authenticated users.
class WishlistNotifier extends StateNotifier<List<Product>> {
  WishlistNotifier(this.ref) : super([]) {
    Future.microtask(loadWishlist);
  }

  final Ref ref;

  Future<void> loadWishlist() async {
    if (SupabaseService.instance.currentUser == null) {
      state = [];
      return;
    }

    ref.read(wishlistLoadingProvider.notifier).state = true;
    ref.read(wishlistErrorProvider.notifier).state = null;

    try {
      state = await SupabaseService.instance.fetchWishlistItems();
    } catch (error) {
      ref.read(wishlistErrorProvider.notifier).state = error.toString();
    } finally {
      ref.read(wishlistLoadingProvider.notifier).state = false;
    }
  }

  Future<void> addToWishlist(Product product) async {
    if (isInWishlist(product.id)) return;

    final previous = [...state];
    state = [...state, product];

    try {
      ref.read(wishlistErrorProvider.notifier).state = null;
      await SupabaseService.instance.addWishlistItem(product);
    } catch (error) {
      state = previous;
      ref.read(wishlistErrorProvider.notifier).state = error.toString();
      rethrow;
    }
  }

  Future<void> removeFromWishlist(String productId) async {
    final previous = [...state];
    state = state.where((p) => p.id != productId).toList();

    try {
      ref.read(wishlistErrorProvider.notifier).state = null;
      await SupabaseService.instance.removeWishlistItem(productId);
    } catch (error) {
      state = previous;
      ref.read(wishlistErrorProvider.notifier).state = error.toString();
      rethrow;
    }
  }

  Future<void> toggleWishlist(Product product) async {
    if (isInWishlist(product.id)) {
      await removeFromWishlist(product.id);
    } else {
      await addToWishlist(product);
    }
  }

  bool isInWishlist(String productId) {
    return state.any((p) => p.id == productId);
  }

  Future<void> clearWishlist() async {
    final previous = [...state];
    state = [];

    try {
      ref.read(wishlistErrorProvider.notifier).state = null;
      await SupabaseService.instance.clearWishlistItems();
    } catch (error) {
      state = previous;
      ref.read(wishlistErrorProvider.notifier).state = error.toString();
      rethrow;
    }
  }

  void clearLocalWishlist() {
    state = [];
    ref.read(wishlistErrorProvider.notifier).state = null;
  }
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, List<Product>>(
  (ref) {
    final notifier = WishlistNotifier(ref);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        notifier.loadWishlist();
      } else if (previous?.isAuthenticated == true) {
        notifier.clearLocalWishlist();
      }
    });

    return notifier;
  },
);

final wishlistLoadingProvider = StateProvider<bool>((ref) => false);

final wishlistErrorProvider = StateProvider<String?>((ref) => null);

/// Wishlist count provider
final wishlistCountProvider = Provider<int>((ref) {
  return ref.watch(wishlistProvider).length;
});

/// Check if product is in wishlist
final isInWishlistProvider = Provider.family<bool, String>((ref, productId) {
  return ref.watch(wishlistProvider).any((p) => p.id == productId);
});
