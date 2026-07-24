import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../../../models/order_model.dart';
import '../../services/providers/booking_providers.dart';

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

class AdminServiceBookingsNotifier extends StateNotifier<List<ServiceBooking>> {
  AdminServiceBookingsNotifier() : super([]);

  Future<void> loadBookings() async {
    state = [];
    try {
      state = await SupabaseService.instance.fetchAdminServiceBookings();
    } catch (_) {}
  }

  Future<void> updateStatus(String bookingId, BookingStatus status) async {
    await SupabaseService.instance.updateAdminServiceBookingStatus(
      bookingId: bookingId,
      status: switch (status) {
        BookingStatus.pending => 'pending',
        BookingStatus.confirmed => 'confirmed',
        BookingStatus.inProgress => 'in_progress',
        BookingStatus.completed => 'completed',
        BookingStatus.cancelled => 'cancelled',
      },
    );
    state = state.map((b) {
      if (b.id != bookingId) return b;
      return b.copyWith(status: status);
    }).toList();
  }
}

final adminServiceBookingsProvider =
    StateNotifierProvider<AdminServiceBookingsNotifier, List<ServiceBooking>>((ref) {
      return AdminServiceBookingsNotifier();
    });

final adminServiceBookingsFutureProvider = FutureProvider<List<ServiceBooking>>((ref) async {
  return SupabaseService.instance.fetchAdminServiceBookings();
});
