import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../../models/product_model.dart';
import '../../models/service_model.dart';
import '../../models/order_model.dart';
import '../../models/review_model.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();
  static const String _productSelect = '''
    id,
    name,
    brand,
    description,
    price,
    original_price,
    rating,
    image_url,
    additional_images,
    stock,
    discount,
    category
  ''';
  static const String _orderSelect =
      '''
    id,
    created_at,
    total_amount,
    status,
    address_id,
    payment_method,
    tracking_number,
    order_items (
      id,
      product_id,
      quantity,
      price,
      products (
        $_productSelect
      )
    )
  ''';
  static const String _orderSummarySelect = '''
    id,
    created_at,
    total_amount,
    status,
    address_id,
    payment_method,
    tracking_number
  ''';
  static const String _orderItemSelect =
      '''
    id,
    order_id,
    product_id,
    quantity,
    price,
    products (
      $_productSelect
    )
  ''';

  SupabaseClient get _client => Supabase.instance.client;
  User? get currentUser => _client.auth.currentUser;

  Future<List<Product>> fetchProducts() async {
    final rows = await _client
        .from('products')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return rows.map<Product>((row) => Product.fromSupabase(row)).toList();
  }

  Future<List<Service>> fetchServices() async {
    final rows = await _client
        .from('services')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return rows.map<Service>((row) => Service.fromSupabase(row)).toList();
  }

  Future<List<Order>> fetchOrders() async {
    final user = _requireUser();
    final rows = await _client
        .from('orders')
        .select(_orderSummarySelect)
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 8));

    final orderRows = rows
        .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
        .toList();
    if (orderRows.isEmpty) return [];

    final orderIds = orderRows
        .map<String?>((row) => row['id'] as String?)
        .whereType<String>()
        .toList();
    final itemsByOrder = <String, List<Map<String, dynamic>>>{};
    try {
      final itemRows = await _client
          .from('order_items')
          .select(_orderItemSelect)
          .inFilter('order_id', orderIds)
          .timeout(const Duration(seconds: 6));
      for (final item in itemRows) {
        final itemMap = Map<String, dynamic>.from(item);
        final orderId = itemMap['order_id'] as String?;
        if (orderId == null) continue;
        itemsByOrder.putIfAbsent(orderId, () => []).add(itemMap);
      }
    } catch (_) {
      // Show order summaries even if item details are temporarily unavailable.
    }

    return orderRows.map<Order>((row) {
      final orderId = row['id'] as String;
      return Order.fromSupabase({
        ...row,
        'order_items': itemsByOrder[orderId] ?? const [],
      });
    }).toList();
  }

  Future<List<Order>> fetchAdminOrders() async {
    await _requireAdmin();
    final rows = await _client
        .from('orders')
        .select(_orderSummarySelect)
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 12));

    final orderRows = rows
        .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
        .toList();
    if (orderRows.isEmpty) return [];

    final orderIds = orderRows
        .map<String?>((row) => row['id'] as String?)
        .whereType<String>()
        .toList();
    final itemRows = await _client
        .from('order_items')
        .select(_orderItemSelect)
        .inFilter('order_id', orderIds)
        .timeout(const Duration(seconds: 12));
    final itemsByOrder = <String, List<Map<String, dynamic>>>{};
    for (final item in itemRows) {
      final itemMap = Map<String, dynamic>.from(item);
      final orderId = itemMap['order_id'] as String?;
      if (orderId == null) continue;
      itemsByOrder.putIfAbsent(orderId, () => []).add(itemMap);
    }

    return orderRows.map<Order>((row) {
      final orderId = row['id'] as String;
      return Order.fromSupabase({
        ...row,
        'order_items': itemsByOrder[orderId] ?? const [],
      });
    }).toList();
  }

  Future<Order?> fetchOrderById(String orderId) async {
    final user = _requireUser();
    final row = await _client
        .from('orders')
        .select(_orderSelect)
        .eq('user_id', user.id)
        .eq('id', orderId)
        .maybeSingle();

    if (row == null) return null;
    return Order.fromSupabase(row);
  }

  Future<Order> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final user = _requireUser();
    final row = await _client
        .from('orders')
        .update({'status': status})
        .eq('id', orderId)
        .eq('user_id', user.id)
        .select(_orderSelect)
        .single();

    return Order.fromSupabase(row);
  }

  Future<Order> updateAdminOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _requireAdmin();
    try {
      await _client.rpc(
        'update_admin_order_status',
        params: {'p_order_id': orderId, 'p_status': status},
      );

      final orders = await fetchAdminOrders();
      return orders.firstWhere(
        (order) => order.id == orderId,
        orElse: () => throw StateError('Updated order could not be reloaded.'),
      );
    } on PostgrestException catch (error) {
      if (!_isMissingAdminUpdateRpc(error)) rethrow;
    }

    final row = await _client
        .from('orders')
        .update({'status': status})
        .eq('id', orderId)
        .select(_orderSelect)
        .single();

    return Order.fromSupabase(row);
  }

  bool _isMissingAdminUpdateRpc(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == 'PGRST202' ||
        message.contains('update_admin_order_status') ||
        message.contains('could not find the function');
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppConfig.oauthRedirectUrl,
      queryParams: const {'prompt': 'select_account'},
    );
  }

  Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name, 'phone': ?phone},
    );
    final user = response.user;
    if (user != null && response.session != null) {
      await _client.from('profiles').upsert({
        'id': user.id,
        'full_name': name,
        'phone': phone,
      });
    }
    return response;
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<Map<String, dynamic>?> fetchCurrentProfile() async {
    final user = _requireUser();
    return _client
        .from('profiles')
        .select('id, full_name, phone, avatar_url, role')
        .eq('id', user.id)
        .maybeSingle();
  }

  Future<Map<String, dynamic>> updateCurrentProfile({
    required String name,
    String? phone,
    String? avatarUrl,
  }) async {
    final user = _requireUser();

    await _client.auth.updateUser(
      UserAttributes(
        data: {'full_name': name, 'phone': phone, 'avatar_url': avatarUrl},
      ),
    );

    final row = await _client
        .from('profiles')
        .upsert({
          'id': user.id,
          'full_name': name,
          'phone': phone,
          'avatar_url': avatarUrl,
        })
        .select('id, full_name, phone, avatar_url')
        .single();

    return row;
  }

  Future<List<Map<String, dynamic>>> fetchCartItems() async {
    final user = _requireUser();
    final rows = await _client
        .from('cart_items')
        .select('''
          id,
          product_id,
          quantity,
          products (
            $_productSelect
          )
        ''')
        .eq('user_id', user.id)
        .order('updated_at', ascending: false);

    return rows.map<Map<String, dynamic>>((row) => row).toList();
  }

  Future<void> addCartItem(Product product, int quantity) async {
    final user = _requireUser();
    await _client.from('cart_items').upsert({
      'user_id': user.id,
      'product_id': product.id,
      'quantity': quantity,
    }, onConflict: 'user_id,product_id');
  }

  Future<void> removeCartItem(String productId) async {
    final user = _requireUser();
    await _client
        .from('cart_items')
        .delete()
        .eq('user_id', user.id)
        .eq('product_id', productId);
  }

  Future<void> clearCart() async {
    final user = _requireUser();
    await _client.from('cart_items').delete().eq('user_id', user.id);
  }

  Future<List<Product>> fetchWishlistItems() async {
    final user = _requireUser();
    final rows = await _client
        .from('wishlist_items')
        .select('''
          product_id,
          products (
            $_productSelect
          )
        ''')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return rows
        .map<Product?>((row) {
          final productJson = row['products'] as Map<String, dynamic>?;
          return productJson == null ? null : Product.fromSupabase(productJson);
        })
        .whereType<Product>()
        .toList();
  }

  Future<void> addWishlistItem(Product product) async {
    final user = _requireUser();
    await _client.from('wishlist_items').upsert({
      'user_id': user.id,
      'product_id': product.id,
    }, onConflict: 'user_id,product_id');
  }

  Future<void> removeWishlistItem(String productId) async {
    final user = _requireUser();
    await _client
        .from('wishlist_items')
        .delete()
        .eq('user_id', user.id)
        .eq('product_id', productId);
  }

  Future<void> clearWishlistItems() async {
    final user = _requireUser();
    await _client.from('wishlist_items').delete().eq('user_id', user.id);
  }

  Future<List<Product>> fetchRecentlyViewedProducts() async {
    final user = _requireUser();
    final rows = await _client
        .from('recently_viewed_products')
        .select('''
          product_id,
          viewed_at,
          products (
            $_productSelect
          )
        ''')
        .eq('user_id', user.id)
        .order('viewed_at', ascending: false)
        .limit(20);

    return rows
        .map<Product?>((row) {
          final productJson = row['products'] as Map<String, dynamic>?;
          return productJson == null ? null : Product.fromSupabase(productJson);
        })
        .whereType<Product>()
        .toList();
  }

  Future<void> addRecentlyViewedProduct(Product product) async {
    final user = _requireUser();
    await _client.from('recently_viewed_products').upsert({
      'user_id': user.id,
      'product_id': product.id,
      'viewed_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,product_id');
  }

  Future<void> clearRecentlyViewedProducts() async {
    final user = _requireUser();
    await _client
        .from('recently_viewed_products')
        .delete()
        .eq('user_id', user.id);
  }

  Future<List<String>> fetchCompareProductIds() async {
    final user = _requireUser();
    final rows = await _client
        .from('compare_items')
        .select('product_id')
        .eq('user_id', user.id)
        .order('created_at', ascending: true)
        .limit(4);

    return rows
        .map<String?>((row) => row['product_id'] as String?)
        .whereType<String>()
        .toList();
  }

  Future<void> addCompareProduct(String productId) async {
    final user = _requireUser();
    await _client.from('compare_items').upsert({
      'user_id': user.id,
      'product_id': productId,
    }, onConflict: 'user_id,product_id');
  }

  Future<void> removeCompareProduct(String productId) async {
    final user = _requireUser();
    await _client
        .from('compare_items')
        .delete()
        .eq('user_id', user.id)
        .eq('product_id', productId);
  }

  Future<void> clearCompareProducts() async {
    final user = _requireUser();
    await _client.from('compare_items').delete().eq('user_id', user.id);
  }

  Future<List<ProductReview>> fetchProductReviews(String productId) async {
    final rows = await _client
        .from('reviews')
        .select('id, user_id, product_id, rating, comment, created_at')
        .eq('product_id', productId)
        .order('created_at', ascending: false);

    final userIds = rows
        .map<String?>((row) => row['user_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final userNames = await _fetchProfileNames(userIds);

    return rows
        .map<ProductReview>(
          (row) => ProductReview.fromSupabase(
            row,
            userName: userNames[row['user_id'] as String?],
          ),
        )
        .toList();
  }

  Future<ProductReview?> fetchMyProductReview(String productId) async {
    final user = _requireUser();
    final row = await _client
        .from('reviews')
        .select('id, user_id, product_id, rating, comment, created_at')
        .eq('user_id', user.id)
        .eq('product_id', productId)
        .maybeSingle();

    if (row == null) return null;
    final userName = await _fetchProfileName(user.id);
    return ProductReview.fromSupabase(row, userName: userName);
  }

  Future<ProductReview> submitProductReview({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    final user = _requireUser();
    final existing = await _client
        .from('reviews')
        .select('id')
        .eq('user_id', user.id)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing != null) {
      throw const PostgrestException(
        message: 'You have already reviewed this product.',
      );
    }

    final row = await _client
        .from('reviews')
        .insert({
          'user_id': user.id,
          'product_id': productId,
          'rating': rating,
          'comment': comment,
        })
        .select('id, user_id, product_id, rating, comment, created_at')
        .single();

    final userName = await _fetchProfileName(user.id);
    return ProductReview.fromSupabase(row, userName: userName);
  }

  Future<List<Address>> fetchAddresses() async {
    final user = _requireUser();
    final rows = await _client
        .from('addresses')
        .select()
        .eq('user_id', user.id)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);

    return rows.map<Address>((row) => Address.fromSupabase(row)).toList();
  }

  Future<Address> createAddress(Address address) async {
    final user = _requireUser();
    final row = await _client
        .from('addresses')
        .insert({'user_id': user.id, ...address.toSupabase()})
        .select()
        .single();

    return Address.fromSupabase(row);
  }

  Future<Address> updateAddress(Address address) async {
    final user = _requireUser();
    final row = await _client
        .from('addresses')
        .update(address.toSupabase())
        .eq('id', address.id)
        .eq('user_id', user.id)
        .select()
        .single();

    return Address.fromSupabase(row);
  }

  Future<void> deleteAddress(String addressId) async {
    final user = _requireUser();
    await _client
        .from('addresses')
        .delete()
        .eq('id', addressId)
        .eq('user_id', user.id);
  }

  Future<Address> setDefaultAddress(String addressId) async {
    final user = _requireUser();
    await _client
        .from('addresses')
        .update({'is_default': false})
        .eq('user_id', user.id);

    final row = await _client
        .from('addresses')
        .update({'is_default': true})
        .eq('id', addressId)
        .eq('user_id', user.id)
        .select()
        .single();

    return Address.fromSupabase(row);
  }

  Future<List<Map<String, dynamic>>> fetchServiceBookings() async {
    final user = _requireUser();
    final rows = await _client
        .from('service_bookings')
        .select('''
          id,
          user_id,
          service_id,
          address_id,
          customer_name,
          customer_phone,
          customer_email,
          booking_date,
          time_slot,
          status,
          notes,
          total_price,
          created_at,
          services (
            id,
            title,
            description,
            price,
            image_url,
            additional_images,
            features
          ),
          addresses (
            id,
            name,
            phone,
            address_line1,
            address_line2,
            city,
            state,
            pincode,
            is_default,
            label,
            type
          )
        ''')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return rows.map<Map<String, dynamic>>((row) => row).toList();
  }

  Future<String> createServiceBooking(Map<String, dynamic> booking) async {
    final user = _requireUser();
    final rows = await _client
        .from('service_bookings')
        .insert({'user_id': user.id, ...booking})
        .select('id')
        .single();
    return rows['id'] as String;
  }

  Future<Map<String, dynamic>> createServiceBookingWithDetails(
    Map<String, dynamic> booking,
  ) async {
    final user = _requireUser();
    final row = await _client
        .from('service_bookings')
        .insert({'user_id': user.id, ...booking})
        .select('''
          id,
          user_id,
          service_id,
          address_id,
          customer_name,
          customer_phone,
          customer_email,
          booking_date,
          time_slot,
          status,
          notes,
          total_price,
          created_at,
          services (
            id,
            title,
            description,
            price,
            image_url,
            additional_images,
            features
          ),
          addresses (
            id,
            name,
            phone,
            address_line1,
            address_line2,
            city,
            state,
            pincode,
            is_default,
            label,
            type
          )
        ''')
        .single();
    return row;
  }

  Future<Map<String, dynamic>> updateServiceBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    final user = _requireUser();
    final row = await _client
        .from('service_bookings')
        .update({'status': status})
        .eq('id', bookingId)
        .eq('user_id', user.id)
        .select('''
          id,
          user_id,
          service_id,
          address_id,
          customer_name,
          customer_phone,
          customer_email,
          booking_date,
          time_slot,
          status,
          notes,
          total_price,
          created_at,
          services (
            id,
            title,
            description,
            price,
            image_url,
            additional_images,
            features
          ),
          addresses (
            id,
            name,
            phone,
            address_line1,
            address_line2,
            city,
            state,
            pincode,
            is_default,
            label,
            type
          )
        ''')
        .single();
    return row;
  }

  Future<String> createOrder({
    required double totalAmount,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    String? addressId,
    String paymentStatus = 'pending',
    String? paymentReference,
  }) async {
    _requireUser();
    if (items.isEmpty) {
      throw const PostgrestException(
        message: 'Cannot create an order with an empty cart.',
      );
    }

    try {
      final orderId = await _client.rpc<String>(
        'create_order_with_items',
        params: {
          'p_total_amount': totalAmount,
          'p_payment_method': paymentMethod,
          'p_address_id': addressId,
          'p_items': items,
          'p_payment_status': paymentStatus,
          'p_payment_reference': paymentReference,
        },
      );
      return orderId;
    } on PostgrestException catch (error) {
      if (!_isMissingCreateOrderRpc(error)) rethrow;
      return _createOrderWithClientFallback(
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        items: items,
        addressId: addressId,
        paymentStatus: paymentStatus,
        paymentReference: paymentReference,
      );
    }
  }

  bool _isMissingCreateOrderRpc(PostgrestException error) {
    return error.code == 'PGRST202' ||
        error.message.contains('create_order_with_items');
  }

  Future<String> _createOrderWithClientFallback({
    required double totalAmount,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    String? addressId,
    String paymentStatus = 'pending',
    String? paymentReference,
  }) async {
    final user = _requireUser();
    await _validateProductStock(items);

    final orderData = <String, dynamic>{
      'user_id': user.id,
      'total_amount': totalAmount,
      'status': 'pending',
      'payment_method': paymentMethod,
    };
    if (paymentStatus != 'pending' || paymentReference != null) {
      orderData['payment_status'] = paymentStatus;
      orderData['payment_reference'] = paymentReference;
    }
    if (addressId != null) {
      orderData['address_id'] = addressId;
    }

    final order = await _insertOrderWithSchemaFallback(orderData);
    final orderId = order['id'] as String;

    if (items.isNotEmpty) {
      await _client
          .from('order_items')
          .insert(
            items
                .map(
                  (item) => {
                    'order_id': orderId,
                    'product_id': item['product_id'],
                    'quantity': item['quantity'],
                    'price': item['price'],
                  },
                )
                .toList(),
          );
      await _decrementProductStock(items);
    }

    return orderId;
  }

  Future<Map<String, dynamic>> _insertOrderWithSchemaFallback(
    Map<String, dynamic> orderData,
  ) async {
    try {
      return await _client
          .from('orders')
          .insert(orderData)
          .select('id')
          .single();
    } on PostgrestException catch (error) {
      final paymentColumnMissing =
          error.code == 'PGRST204' &&
          (error.message.contains('payment_status') ||
              error.message.contains('payment_reference'));
      if (!paymentColumnMissing) rethrow;

      final compatibleOrderData = Map<String, dynamic>.from(orderData)
        ..remove('payment_status')
        ..remove('payment_reference');
      return _client
          .from('orders')
          .insert(compatibleOrderData)
          .select('id')
          .single();
    }
  }

  Future<void> _validateProductStock(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;

    final productIds = items
        .map((item) => item['product_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final rows = await _client
        .from('products')
        .select('id, stock, name')
        .inFilter('id', productIds);
    final stockByProduct = {
      for (final row in rows)
        row['id'] as String: {
          'stock': row['stock'] as int? ?? 0,
          'name': row['name'] as String? ?? 'Product',
        },
    };

    for (final item in items) {
      final productId = item['product_id'] as String?;
      if (productId == null) continue;
      final requested = item['quantity'] as int? ?? 1;
      final productStock = stockByProduct[productId];
      final available = productStock?['stock'] as int? ?? 0;
      if (requested > available) {
        final name = productStock?['name'] as String? ?? 'Product';
        throw PostgrestException(
          message:
              '$name has only $available item(s) available. Please update your cart.',
        );
      }
    }
  }

  Future<void> _decrementProductStock(List<Map<String, dynamic>> items) async {
    for (final item in items) {
      final productId = item['product_id'] as String?;
      if (productId == null) continue;
      final quantity = item['quantity'] as int? ?? 1;
      final row = await _client
          .from('products')
          .select('stock')
          .eq('id', productId)
          .single();
      final stock = row['stock'] as int? ?? 0;
      final nextStock = stock - quantity;
      await _client
          .from('products')
          .update({'stock': nextStock < 0 ? 0 : nextStock})
          .eq('id', productId);
    }
  }

  User _requireUser() {
    final user = currentUser;
    if (user == null) {
      throw const AuthException('Please sign in first.');
    }
    return user;
  }

  Future<void> _requireAdmin() async {
    _requireUser();
    final isAdmin = await _client.rpc<bool>('is_admin');
    if (isAdmin != true) {
      throw const AuthException('Admin access required.');
    }
  }

  Future<Map<String, String>> _fetchProfileNames(List<String> userIds) async {
    if (userIds.isEmpty) return {};

    final rows = await _client
        .from('profiles')
        .select('id, full_name')
        .inFilter('id', userIds);

    return {
      for (final row in rows)
        if (row['id'] != null && row['full_name'] != null)
          row['id'] as String: row['full_name'] as String,
    };
  }

  Future<String?> _fetchProfileName(String userId) async {
    final row = await _client
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .maybeSingle();
    return row?['full_name'] as String?;
  }
}
