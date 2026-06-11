import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/supabase_service.dart';
import '../../models/product_model.dart';
import 'auth_provider.dart';

class CartItem {
  final String? cartItemId;
  final Product product;
  int quantity;

  CartItem({this.cartItemId, required this.product, this.quantity = 1});

  CartItem copyWith({String? cartItemId, Product? product, int? quantity}) {
    return CartItem(
      cartItemId: cartItemId ?? this.cartItemId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  double get totalPrice => product.price * quantity;
  String get id => product.id;
  String get name => product.name;
  double get price => product.price;
  String get image => product.image;

  factory CartItem.fromSupabase(Map<String, dynamic> json) {
    final productJson = json['products'] as Map<String, dynamic>?;
    final product = productJson != null
        ? Product.fromSupabase(productJson)
        : Product(
            id: json['product_id'] as String? ?? '',
            name: 'Product unavailable',
            brand: '',
            price: 0,
            rating: 0,
            image: '',
            category: '',
          );

    return CartItem(
      cartItemId: json['id'] as String?,
      product: product,
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier(this.ref) : super([]) {
    Future.microtask(loadCart);
  }

  final Ref ref;

  List<CartItem> _snapshot() {
    return state.map((item) => item.copyWith()).toList();
  }

  Future<void> loadCart() async {
    if (SupabaseService.instance.currentUser == null) {
      state = [];
      return;
    }

    ref.read(cartLoadingProvider.notifier).state = true;
    ref.read(cartErrorProvider.notifier).state = null;

    try {
      final rows = await SupabaseService.instance.fetchCartItems();
      state = rows.map(CartItem.fromSupabase).toList();
    } catch (error) {
      ref.read(cartErrorProvider.notifier).state = error.toString();
    } finally {
      ref.read(cartLoadingProvider.notifier).state = false;
    }
  }

  Future<void> addToCart(Product product) async {
    final previous = _snapshot();
    final existingIndex = state.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex != -1) {
      state[existingIndex].quantity++;
      state = [...state];
    } else {
      state = [...state, CartItem(product: product, quantity: 1)];
    }
    final quantity = state
        .firstWhere((item) => item.product.id == product.id)
        .quantity;

    try {
      ref.read(cartErrorProvider.notifier).state = null;
      await SupabaseService.instance.addCartItem(product, quantity);
    } catch (error) {
      state = previous;
      ref.read(cartErrorProvider.notifier).state = error.toString();
    }
  }

  Future<void> removeFromCart(String productId) async {
    final previous = _snapshot();
    state = state.where((item) => item.product.id != productId).toList();

    try {
      ref.read(cartErrorProvider.notifier).state = null;
      await SupabaseService.instance.removeCartItem(productId);
    } catch (error) {
      state = previous;
      ref.read(cartErrorProvider.notifier).state = error.toString();
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(productId);
      return;
    }

    final previous = _snapshot();
    final index = state.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      state[index].quantity = quantity;
      state = [...state];

      try {
        ref.read(cartErrorProvider.notifier).state = null;
        await SupabaseService.instance.addCartItem(
          state[index].product,
          quantity,
        );
      } catch (error) {
        state = previous;
        ref.read(cartErrorProvider.notifier).state = error.toString();
      }
    }
  }

  Future<void> clearCart() async {
    final previous = _snapshot();
    state = [];

    try {
      ref.read(cartErrorProvider.notifier).state = null;
      await SupabaseService.instance.clearCart();
    } catch (error) {
      state = previous;
      ref.read(cartErrorProvider.notifier).state = error.toString();
    }
  }

  void clearLocalCart() {
    state = [];
    ref.read(cartErrorProvider.notifier).state = null;
  }

  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice =>
      state.fold(0.0, (sum, item) => sum + item.totalPrice);
  bool get isEmpty => state.isEmpty;
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  final notifier = CartNotifier(ref);

  ref.listen<AuthState>(authProvider, (previous, next) {
    if (next.isAuthenticated) {
      notifier.loadCart();
    } else if (previous?.isAuthenticated == true) {
      notifier.clearLocalCart();
    }
  });

  return notifier;
});

final cartLoadingProvider = StateProvider<bool>((ref) => false);

final cartErrorProvider = StateProvider<String?>((ref) => null);

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, item) => sum + item.quantity);
});

final cartTotalProvider = Provider<double>((ref) {
  return ref
      .watch(cartProvider)
      .fold(0.0, (sum, item) => sum + item.totalPrice);
});
