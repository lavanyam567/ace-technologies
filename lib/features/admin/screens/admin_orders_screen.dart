import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../providers/admin_order_provider.dart';

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final ordersAsync = ref.watch(adminOrdersFutureProvider);

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Orders')),
        body: const Center(child: Text('Admin access required.')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Admin Orders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(adminOrdersFutureProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _AdminError(
          error: error.toString(),
          onRetry: () => ref.invalidate(adminOrdersFutureProvider),
        ),
        data: (orders) => orders.isEmpty
            ? const Center(child: Text('No orders yet.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  return _AdminOrderCard(
                    key: ValueKey('${orders[index].id}-${orders[index].status.name}'),
                    order: orders[index],
                  );
                },
              ),
      ),
    );
  }
}

class _AdminOrderCard extends ConsumerWidget {
  const _AdminOrderCard({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.id,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                CurrencyUtils.formatPrice(order.totalAmount),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${order.totalItems} item(s) • ${order.paymentMethod}'),
          if (order.paymentReference != null) ...[
            const SizedBox(height: 4),
            Text(
              'Payment ref: ${order.paymentReference}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<OrderStatus>(
            key: ValueKey('status-${order.id}-${order.status.name}'),
            initialValue: order.status,
            decoration: const InputDecoration(
              labelText: 'Order status',
              border: OutlineInputBorder(),
            ),
            items: OrderStatus.values.map((status) {
              return DropdownMenuItem(value: status, child: Text(status.name));
            }).toList(),
            onChanged: (status) async {
              if (status == null) return;
              try {
                await ref
                    .read(adminOrdersProvider.notifier)
                    .updateStatus(order.id, status);
                ref.invalidate(adminOrdersFutureProvider);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order status updated')),
                );
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error.toString())));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _AdminError extends StatelessWidget {
  const _AdminError({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Could not load admin orders',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
