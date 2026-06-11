import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

class ServiceConfirmationScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const ServiceConfirmationScreen({super.key, required this.bookingId});

  @override
  ConsumerState<ServiceConfirmationScreen> createState() =>
      _ServiceConfirmationScreenState();
}

class _ServiceConfirmationScreenState
    extends ConsumerState<ServiceConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Booking Confirmation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: const Center(child: Text('Service Confirmation Screen')),
    );
  }
}
