import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../../../models/service_model.dart';

class ServicesNotifier extends StateNotifier<List<Service>> {
  ServicesNotifier(this.ref) : super([]) {
    Future.microtask(loadServices);
  }

  final Ref ref;

  Future<void> loadServices() async {
    ref.read(servicesLoadingProvider.notifier).state = true;
    ref.read(servicesErrorProvider.notifier).state = null;

    try {
      final services = await SupabaseService.instance.fetchServices();
      state = services;
    } catch (error) {
      state = [];
      ref.read(servicesErrorProvider.notifier).state = error.toString();
    } finally {
      ref.read(servicesLoadingProvider.notifier).state = false;
    }
  }
}

final servicesProvider = StateNotifierProvider<ServicesNotifier, List<Service>>(
  (ref) {
    return ServicesNotifier(ref);
  },
);

final servicesLoadingProvider = StateProvider<bool>((ref) => false);

final servicesErrorProvider = StateProvider<String?>((ref) => null);

final serviceByIdProvider = Provider.family<Service?, String>((ref, id) {
  try {
    return ref
        .watch(servicesProvider)
        .firstWhere((service) => service.id == id);
  } catch (_) {
    return null;
  }
});
