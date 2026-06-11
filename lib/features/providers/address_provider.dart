import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/supabase_service.dart';
import '../../models/order_model.dart';
import 'auth_provider.dart';

class AddressNotifier extends StateNotifier<List<Address>> {
  AddressNotifier(this.ref) : super([]) {
    Future.microtask(loadAddresses);
  }

  final Ref ref;

  Future<void> loadAddresses() async {
    if (SupabaseService.instance.currentUser == null) {
      state = [];
      ref.read(selectedAddressProvider.notifier).state = null;
      return;
    }

    ref.read(addressLoadingProvider.notifier).state = true;
    ref.read(addressErrorProvider.notifier).state = null;

    try {
      final addresses = await SupabaseService.instance.fetchAddresses();
      state = addresses;
      ref.read(selectedAddressProvider.notifier).state = _defaultAddress(
        addresses,
      );
    } catch (error) {
      ref.read(addressErrorProvider.notifier).state = error.toString();
    } finally {
      ref.read(addressLoadingProvider.notifier).state = false;
    }
  }

  Future<void> addAddress(Address address) async {
    ref.read(addressErrorProvider.notifier).state = null;

    try {
      final created = await SupabaseService.instance.createAddress(
        address.copyWith(isDefault: state.isEmpty || address.isDefault),
      );
      state = [created, ...state];

      if (created.isDefault || state.length == 1) {
        await setDefaultAddress(created.id);
      } else {
        ref.read(selectedAddressProvider.notifier).state = _defaultAddress(
          state,
        );
      }
    } catch (error) {
      ref.read(addressErrorProvider.notifier).state = error.toString();
      rethrow;
    }
  }

  Future<void> updateAddress(Address address) async {
    ref.read(addressErrorProvider.notifier).state = null;

    try {
      final updated = await SupabaseService.instance.updateAddress(address);
      state = state.map((a) => a.id == updated.id ? updated : a).toList();

      final selected = ref.read(selectedAddressProvider);
      if (selected?.id == updated.id || updated.isDefault) {
        ref.read(selectedAddressProvider.notifier).state = updated;
      }
    } catch (error) {
      ref.read(addressErrorProvider.notifier).state = error.toString();
      rethrow;
    }
  }

  Future<void> removeAddress(String addressId) async {
    ref.read(addressErrorProvider.notifier).state = null;

    try {
      await SupabaseService.instance.deleteAddress(addressId);
      state = state.where((a) => a.id != addressId).toList();

      final selected = ref.read(selectedAddressProvider);
      if (selected?.id == addressId) {
        ref.read(selectedAddressProvider.notifier).state = _defaultAddress(
          state,
        );
      }
    } catch (error) {
      ref.read(addressErrorProvider.notifier).state = error.toString();
      rethrow;
    }
  }

  Future<void> setDefaultAddress(String addressId) async {
    ref.read(addressErrorProvider.notifier).state = null;

    try {
      final defaultAddress = await SupabaseService.instance.setDefaultAddress(
        addressId,
      );
      state = state
          .map((a) => a.copyWith(isDefault: a.id == defaultAddress.id))
          .toList();
      ref.read(selectedAddressProvider.notifier).state = defaultAddress;
    } catch (error) {
      ref.read(addressErrorProvider.notifier).state = error.toString();
      rethrow;
    }
  }

  void clearLocalAddresses() {
    state = [];
    ref.read(selectedAddressProvider.notifier).state = null;
    ref.read(addressErrorProvider.notifier).state = null;
  }

  Address? _defaultAddress(List<Address> addresses) {
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => addresses.first,
    );
  }
}

final savedAddressesProvider =
    StateNotifierProvider<AddressNotifier, List<Address>>((ref) {
      final notifier = AddressNotifier(ref);

      ref.listen<AuthState>(authProvider, (previous, next) {
        if (next.isAuthenticated) {
          notifier.loadAddresses();
        } else if (previous?.isAuthenticated == true) {
          notifier.clearLocalAddresses();
        }
      });

      return notifier;
    });

final addressLoadingProvider = StateProvider<bool>((ref) => false);

final addressErrorProvider = StateProvider<String?>((ref) => null);

final selectedAddressProvider = StateProvider<Address?>((ref) => null);
