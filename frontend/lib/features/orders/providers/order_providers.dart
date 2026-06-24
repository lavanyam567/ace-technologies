import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

export '../../../models/order_model.dart';

import '../../../core/services/supabase_service.dart';
import '../../../models/order_model.dart';

class OrdersNotifier extends StateNotifier<List<Order>> {
  OrdersNotifier(this.ref) : super([]) {
    loadOrders();
  }

  final Ref ref;

  Future<void> loadOrders() async {
    ref.read(ordersLoadingProvider.notifier).state = true;
    ref.read(ordersErrorProvider.notifier).state = null;

    try {
      state = await SupabaseService.instance
          .fetchOrders()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Orders are taking too long to load. Check your connection and try again.',
            ),
          );
    } catch (error) {
      state = [];
      ref.read(ordersErrorProvider.notifier).state = error.toString();
    } finally {
      ref.read(ordersLoadingProvider.notifier).state = false;
    }
  }

  Future<void> loadOrder(String orderId) async {
    ref.read(orderDetailLoadingProvider(orderId).notifier).state = true;
    ref.read(orderDetailErrorProvider(orderId).notifier).state = null;

    try {
      final order = await SupabaseService.instance.fetchOrderById(orderId);
      if (order == null) {
        ref.read(orderDetailErrorProvider(orderId).notifier).state =
            'Order not found.';
        return;
      }

      final existingIndex = state.indexWhere((item) => item.id == order.id);
      if (existingIndex == -1) {
        state = [order, ...state];
      } else {
        final updated = [...state];
        updated[existingIndex] = order;
        state = updated;
      }
    } catch (error) {
      ref.read(orderDetailErrorProvider(orderId).notifier).state = error
          .toString();
    } finally {
      ref.read(orderDetailLoadingProvider(orderId).notifier).state = false;
    }
  }

  void addOrder(Order order) {
    state = [order, ...state];
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final previous = [...state];
    state = state.map((order) {
      if (order.id != orderId) return order;
      return order.copyWith(status: status);
    }).toList();

    try {
      ref.read(ordersErrorProvider.notifier).state = null;
      final updated = await SupabaseService.instance.updateOrderStatus(
        orderId: orderId,
        status: orderStatusToSupabase(status),
      );
      state = state.map((order) {
        if (order.id != orderId) return order;
        return updated;
      }).toList();
    } catch (error) {
      state = previous;
      ref.read(ordersErrorProvider.notifier).state = error.toString();
      rethrow;
    }
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<Order>>((
  ref,
) {
  return OrdersNotifier(ref);
});

final ordersLoadingProvider = StateProvider<bool>((ref) => false);

final ordersErrorProvider = StateProvider<String?>((ref) => null);

final orderDetailLoadingProvider = StateProvider.family<bool, String>(
  (ref, orderId) => false,
);

final orderDetailErrorProvider = StateProvider.family<String?, String>(
  (ref, orderId) => null,
);

final orderByIdProvider = Provider.family<Order?, String>((ref, orderId) {
  try {
    return ref.watch(ordersProvider).firstWhere((order) => order.id == orderId);
  } catch (_) {
    return null;
  }
});
