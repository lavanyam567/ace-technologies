import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../responsive/responsive_config.dart';

/// Provider for current device type
final deviceTypeProvider = StreamProvider<DeviceType>((ref) async* {
  // This will be populated by the ResponsiveObserver
  yield* Stream.value(DeviceType.mobile);
});

/// Provider for current screen size
final screenSizeProvider = StateProvider<Size>((ref) {
  return const Size(0, 0);
});

/// Provider to track if sidebar is expanded on desktop
final sidebarExpandedProvider = StateProvider<bool>((ref) => true);

/// Provider for showing sidebar drawer on tablet
final drawerOpenProvider = StateProvider<bool>((ref) => false);

/// Observable widget to track screen size changes
class ResponsiveObserver extends ConsumerWidget {
  final Widget child;

  const ResponsiveObserver({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;

    // Update screen size when it changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(screenSizeProvider) != size) {
        ref.read(screenSizeProvider.notifier).state = size;
      }
    });

    return child;
  }
}
