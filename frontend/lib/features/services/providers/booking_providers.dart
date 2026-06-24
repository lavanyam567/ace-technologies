import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../../../models/service_model.dart';
import '../../providers/auth_provider.dart';

/// Service booking status
enum BookingStatus { pending, confirmed, inProgress, completed, cancelled }

BookingStatus _bookingStatusFromDb(String? value) {
  switch (value) {
    case 'confirmed':
      return BookingStatus.confirmed;
    case 'in_progress':
    case 'inProgress':
      return BookingStatus.inProgress;
    case 'completed':
      return BookingStatus.completed;
    case 'cancelled':
      return BookingStatus.cancelled;
    case 'pending':
    default:
      return BookingStatus.pending;
  }
}

String _bookingStatusToDb(BookingStatus status) {
  return switch (status) {
    BookingStatus.pending => 'pending',
    BookingStatus.confirmed => 'confirmed',
    BookingStatus.inProgress => 'in_progress',
    BookingStatus.completed => 'completed',
    BookingStatus.cancelled => 'cancelled',
  };
}

/// Service slot model
class ServiceSlot {
  final String id;
  final DateTime date;
  final String timeSlot;
  final bool isAvailable;

  const ServiceSlot({
    required this.id,
    required this.date,
    required this.timeSlot,
    this.isAvailable = true,
  });
}

/// Address for service booking (reusing from orders)
class Address {
  final String id;
  final String name;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;
  final String? label;
  final String? street;
  final String? type;

  const Address({
    required this.id,
    required this.name,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
    this.label,
    this.street,
    this.type,
  });

  String get displayLabel => label ?? name;
  String get displayStreet => street ?? addressLine1;

  factory Address.fromSupabase(Map<String, dynamic> json) {
    final addressLine1 = json['address_line1'] as String? ?? '';
    return Address(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['label'] as String? ?? 'Address',
      phone: json['phone'] as String? ?? '',
      addressLine1: addressLine1,
      addressLine2: json['address_line2'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
      label: json['label'] as String?,
      street: addressLine1,
      type: json['type'] as String?,
    );
  }
}

/// Service booking model
class ServiceBooking {
  final String id;
  final Service service;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final Address bookingAddress;
  final ServiceSlot slot;
  final BookingStatus status;
  final DateTime bookingDate;
  final String? notes;
  final double? totalPrice;

  const ServiceBooking({
    required this.id,
    required this.service,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.bookingAddress,
    required this.slot,
    required this.status,
    required this.bookingDate,
    this.notes,
    this.totalPrice,
  });

  String get statusText {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get serviceName => service.name;
  String get date => slot.date.toIso8601String();
  String get timeSlot => slot.timeSlot;
  Address get address => bookingAddress;
  double get price => totalPrice ?? service.price ?? 0;

  ServiceBooking copyWith({BookingStatus? status}) {
    return ServiceBooking(
      id: id,
      service: service,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      bookingAddress: bookingAddress,
      slot: slot,
      status: status ?? this.status,
      bookingDate: bookingDate,
      notes: notes,
      totalPrice: totalPrice,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'service_id': service.id,
      'address_id': bookingAddress.id.isEmpty ? null : bookingAddress.id,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'booking_date': slot.date.toIso8601String().split('T').first,
      'time_slot': slot.timeSlot,
      'status': _bookingStatusToDb(status),
      'notes': notes,
      'total_price': totalPrice,
    };
  }

  factory ServiceBooking.fromSupabase(Map<String, dynamic> json) {
    final serviceJson = json['services'] as Map<String, dynamic>?;
    final addressJson = json['addresses'] as Map<String, dynamic>?;
    final bookingDate =
        DateTime.tryParse(json['booking_date'] as String? ?? '') ??
        DateTime.now();

    return ServiceBooking(
      id: json['id'] as String,
      service: serviceJson != null
          ? Service.fromSupabase(serviceJson)
          : Service(
              id: json['service_id'] as String? ?? '',
              title: 'Service',
              description: '',
              image: '',
            ),
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String? ?? '',
      customerEmail: json['customer_email'] as String? ?? '',
      bookingAddress: addressJson != null
          ? Address.fromSupabase(addressJson)
          : const Address(
              id: '',
              name: 'Address unavailable',
              phone: '',
              addressLine1: '',
              city: '',
              state: '',
              pincode: '',
            ),
      slot: ServiceSlot(
        id: json['id'] as String,
        date: bookingDate,
        timeSlot: json['time_slot'] as String? ?? '',
      ),
      status: _bookingStatusFromDb(json['status'] as String?),
      bookingDate:
          DateTime.tryParse(json['created_at'] as String? ?? '') ?? bookingDate,
      notes: json['notes'] as String?,
      totalPrice: json['total_price'] != null
          ? (json['total_price'] as num).toDouble()
          : null,
    );
  }
}

class SavedServiceAddressesNotifier extends StateNotifier<List<Address>> {
  SavedServiceAddressesNotifier(this.ref) : super([]) {
    Future.microtask(loadAddresses);
  }

  final Ref ref;

  Future<void> loadAddresses() async {
    if (SupabaseService.instance.currentUser == null) {
      state = [];
      return;
    }

    ref.read(serviceAddressesLoadingProvider.notifier).state = true;
    ref.read(serviceAddressesErrorProvider.notifier).state = null;

    try {
      final addresses = await SupabaseService.instance.fetchAddresses();
      state = addresses
          .map(
            (address) => Address(
              id: address.id,
              name: address.name,
              phone: address.phone,
              addressLine1: address.addressLine1,
              addressLine2: address.addressLine2,
              city: address.city,
              state: address.state,
              pincode: address.pincode,
              isDefault: address.isDefault,
              label: address.label,
              street: address.addressLine1,
              type: address.type,
            ),
          )
          .toList();
    } catch (error) {
      ref.read(serviceAddressesErrorProvider.notifier).state = error.toString();
    } finally {
      ref.read(serviceAddressesLoadingProvider.notifier).state = false;
    }
  }

  void clearLocalAddresses() {
    state = [];
    ref.read(serviceAddressesErrorProvider.notifier).state = null;
  }
}

final savedAddressesProvider =
    StateNotifierProvider<SavedServiceAddressesNotifier, List<Address>>((ref) {
      final notifier = SavedServiceAddressesNotifier(ref);

      ref.listen<AuthState>(authProvider, (previous, next) {
        if (next.isAuthenticated) {
          notifier.loadAddresses();
        } else if (previous?.isAuthenticated == true) {
          notifier.clearLocalAddresses();
        }
      });

      return notifier;
    });

final serviceAddressesLoadingProvider = StateProvider<bool>((ref) => false);

final serviceAddressesErrorProvider = StateProvider<String?>((ref) => null);

/// Service bookings notifier
class ServiceBookingsNotifier extends StateNotifier<List<ServiceBooking>> {
  ServiceBookingsNotifier(this.ref) : super([]) {
    Future.microtask(loadBookings);
  }

  final Ref ref;

  Future<void> loadBookings() async {
    if (SupabaseService.instance.currentUser == null) {
      state = [];
      return;
    }

    ref.read(serviceBookingsLoadingProvider.notifier).state = true;
    ref.read(serviceBookingsErrorProvider.notifier).state = null;

    try {
      final rows = await SupabaseService.instance.fetchServiceBookings();
      state = rows.map(ServiceBooking.fromSupabase).toList();
    } catch (error) {
      state = [];
      ref.read(serviceBookingsErrorProvider.notifier).state = error.toString();
    } finally {
      ref.read(serviceBookingsLoadingProvider.notifier).state = false;
    }
  }

  Future<ServiceBooking> addBooking(ServiceBooking booking) async {
    ref.read(serviceBookingsErrorProvider.notifier).state = null;

    try {
      final row = await SupabaseService.instance
          .createServiceBookingWithDetails(booking.toSupabase());
      final savedBooking = ServiceBooking.fromSupabase(row);
      state = [savedBooking, ...state];
      return savedBooking;
    } catch (error) {
      ref.read(serviceBookingsErrorProvider.notifier).state = error.toString();
      rethrow;
    }
  }

  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    final previous = [...state];
    state = state.map((booking) {
      if (booking.id != bookingId) return booking;
      return booking.copyWith(status: status);
    }).toList();

    try {
      ref.read(serviceBookingsErrorProvider.notifier).state = null;
      final row = await SupabaseService.instance.updateServiceBookingStatus(
        bookingId: bookingId,
        status: _bookingStatusToDb(status),
      );
      final updatedBooking = ServiceBooking.fromSupabase(row);
      state = state
          .map((booking) => booking.id == bookingId ? updatedBooking : booking)
          .toList();
    } catch (error) {
      state = previous;
      ref.read(serviceBookingsErrorProvider.notifier).state = error.toString();
      rethrow;
    }
  }

  Future<void> cancelBooking(String bookingId) {
    return updateBookingStatus(bookingId, BookingStatus.cancelled);
  }

  void clearLocalBookings() {
    state = [];
    ref.read(serviceBookingsErrorProvider.notifier).state = null;
  }
}

final serviceBookingsProvider =
    StateNotifierProvider<ServiceBookingsNotifier, List<ServiceBooking>>((ref) {
      final notifier = ServiceBookingsNotifier(ref);

      ref.listen<AuthState>(authProvider, (previous, next) {
        if (next.isAuthenticated) {
          notifier.loadBookings();
        } else if (previous?.isAuthenticated == true) {
          notifier.clearLocalBookings();
        }
      });

      return notifier;
    });

final serviceBookingsLoadingProvider = StateProvider<bool>((ref) => false);

final serviceBookingsErrorProvider = StateProvider<String?>((ref) => null);

final activeServiceBookingsProvider = Provider<List<ServiceBooking>>((ref) {
  return ref
      .watch(serviceBookingsProvider)
      .where(
        (booking) =>
            booking.status == BookingStatus.pending ||
            booking.status == BookingStatus.confirmed ||
            booking.status == BookingStatus.inProgress,
      )
      .toList();
});

final serviceBookingHistoryProvider = Provider<List<ServiceBooking>>((ref) {
  return ref
      .watch(serviceBookingsProvider)
      .where(
        (booking) =>
            booking.status == BookingStatus.completed ||
            booking.status == BookingStatus.cancelled,
      )
      .toList();
});

/// Available time slots provider
final availableSlotsProvider = Provider<List<ServiceSlot>>((ref) {
  final now = DateTime.now();
  final slots = <ServiceSlot>[];

  // Generate slots for next 7 days
  for (int day = 1; day <= 7; day++) {
    final date = now.add(Duration(days: day));
    if (date.weekday != 7) {
      // Skip Sundays
      slots.add(
        ServiceSlot(
          id: 'slot_${day}_1',
          date: date,
          timeSlot: '9:00 AM - 11:00 AM',
        ),
      );
      slots.add(
        ServiceSlot(
          id: 'slot_${day}_2',
          date: date,
          timeSlot: '11:00 AM - 1:00 PM',
        ),
      );
      slots.add(
        ServiceSlot(
          id: 'slot_${day}_3',
          date: date,
          timeSlot: '2:00 PM - 4:00 PM',
        ),
      );
      slots.add(
        ServiceSlot(
          id: 'slot_${day}_4',
          date: date,
          timeSlot: '4:00 PM - 6:00 PM',
        ),
      );
    }
  }

  return slots;
});

/// Single booking provider
final bookingByIdProvider = Provider.family<ServiceBooking?, String>((
  ref,
  bookingId,
) {
  try {
    return ref
        .watch(serviceBookingsProvider)
        .firstWhere((b) => b.id == bookingId);
  } catch (e) {
    return null;
  }
});
