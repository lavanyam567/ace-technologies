import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/cached_image.dart';
import '../../orders/providers/order_providers.dart';
import '../../providers/address_provider.dart';
import '../../providers/cart_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isPlacingOrder = false;
  String _selectedPaymentMethod = 'cod';

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final addresses = ref.watch(savedAddressesProvider);
    final selectedAddress =
        ref.watch(selectedAddressProvider) ??
        (addresses.isNotEmpty
            ? addresses.firstWhere(
                (address) => address.isDefault,
                orElse: () => addresses.first,
              )
            : null);

    final subtotal = cartItems.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final shipping = subtotal > 500 ? 0.0 : 50.0;
    final tax = subtotal * 0.18;
    final total = subtotal + shipping + tax;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delivery Address',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () => context.go('/checkout/address/new'),
                  child: const Text('+ Add New'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (addresses.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('No saved addresses')),
                    TextButton(
                      onPressed: () => context.go('/checkout/address/new'),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              )
            else
              ...(selectedAddress != null ? [selectedAddress] : addresses)
                  .take(2)
                  .map((address) => _buildAddressCard(context, address)),
            const SizedBox(height: 24),
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: cartItems
                    .map((item) => _buildCartItem(item))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Price Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildPriceRow(
                    'Subtotal',
                    CurrencyUtils.formatPrice(subtotal),
                  ),
                  _buildPriceRow(
                    'Shipping',
                    shipping == 0
                        ? 'FREE'
                        : CurrencyUtils.formatPrice(shipping),
                  ),
                  _buildPriceRow('Tax (18%)', CurrencyUtils.formatPrice(tax)),
                  const Divider(height: 24),
                  _buildPriceRow(
                    'Total',
                    CurrencyUtils.formatPrice(total),
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildPaymentOption(
                    'credit_card',
                    'Credit / Debit Card',
                    Icons.credit_card,
                  ),
                  _buildPaymentOption('upi', 'UPI', Icons.qr_code),
                  _buildPaymentOption(
                    'netbanking',
                    'Net Banking',
                    Icons.account_balance,
                  ),
                  _buildPaymentOption('cod', 'Cash on Delivery', Icons.money),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isPlacingOrder || cartItems.isEmpty
                    ? null
                    : () => _placeOrder(cartItems, selectedAddress, total),
                child: Text(
                  _isPlacingOrder
                      ? 'Placing Order...'
                      : 'Place Order - ${CurrencyUtils.formatPrice(total)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder(
    List<CartItem> cartItems,
    Address? selectedAddress,
    double total,
  ) async {
    setState(() => _isPlacingOrder = true);
    try {
      final user = SupabaseService.instance.currentUser;
      final payment = await PaymentService.instance.preparePayment(
        method: _selectedPaymentMethod,
        amount: total,
        customerName:
            selectedAddress?.name ??
            user?.userMetadata?['full_name'] as String? ??
            'Ace Customer',
        customerEmail: user?.email ?? '',
        customerPhone: selectedAddress?.phone ?? '',
      );
      final remoteOrderId = await SupabaseService.instance.createOrder(
        totalAmount: total,
        paymentMethod: payment.method,
        paymentStatus: payment.status,
        paymentReference: payment.reference,
        addressId: selectedAddress?.id,
        items: cartItems
            .map(
              (item) => {
                'product_id': item.product.id,
                'quantity': item.quantity,
                'price': item.price,
              },
            )
            .toList(),
      );

      final order = Order(
        id: remoteOrderId,
        items: cartItems
            .map(
              (item) => OrderItem(
                product: item.product,
                price: item.price,
                quantity: item.quantity,
              ),
            )
            .toList(),
        orderDate: DateTime.now(),
        totalAmount: total,
        status: OrderStatus.pending,
        shippingAddress: selectedAddress,
        addressId: selectedAddress?.id,
        paymentMethod: payment.method,
        paymentStatus: payment.status,
        paymentReference: payment.reference,
      );

      ref.read(ordersProvider.notifier).addOrder(order);
      await ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        context.go('/order-success/$remoteOrderId');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  Widget _buildAddressCard(BuildContext context, Address address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(
            address.type == 'home' ? Icons.home : Icons.business,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.label ?? address.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${address.street ?? address.addressLine1}, ${address.city}, ${address.state} - ${address.pincode}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppTheme.primaryColor),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              height: 60,
              color: Colors.grey.shade100,
              child: AceImage(
                url: item.image,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Qty: ${item.quantity}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            CurrencyUtils.formatPrice(item.price * item.quantity),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String value, String label, IconData icon) {
    final isSelected = value == _selectedPaymentMethod;
    return ListTile(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      leading: Icon(icon, size: 20),
      title: Row(children: [Text(label)]),
      trailing: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? AppTheme.primaryColor : Colors.grey,
      ),
    );
  }
}
