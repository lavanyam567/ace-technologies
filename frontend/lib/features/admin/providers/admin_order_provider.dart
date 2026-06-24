import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../../../models/order_model.dart';

class AdminOrdersNotifier extends StateNotifier<List<Order>> {
  AdminOrdersNotifier() : super([]);

  Future<void> loadOrders() async {
    state = [];
    try {
      state = await SupabaseService.instance.fetchAdminOrders();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    final updated = await SupabaseService.instance.updateAdminOrderStatus(
      orderId: orderId,
      status: orderStatusToSupabase(status),
    );
    state = state.map((order) {
      if (order.id != orderId) return order;
      return updated;
    }).toList();
  }
}

final adminOrdersProvider =
    StateNotifierProvider<AdminOrdersNotifier, List<Order>>((ref) {
      return AdminOrdersNotifier();
    });

final adminOrdersFutureProvider = FutureProvider<List<Order>>((ref) async {
  return SupabaseService.instance.fetchAdminOrders();
});
