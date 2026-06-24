import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'payment_models.dart';

Future<PaymentResult> preparePlatformPayment({
  required String method,
  required double amount,
  required String customerName,
  required String customerEmail,
  required String customerPhone,
}) async {
  if (method == 'cod') {
    return const PaymentResult(method: 'COD', status: 'pending');
  }

  if (AppConfig.razorpayKeyId.isEmpty) {
    throw StateError('Missing RAZORPAY_KEY_ID in env.json.');
  }

  final order = await _createRazorpayOrder(
    amount: amount,
    paymentMethod: method,
  );
  final payment = await _openRazorpayCheckout(
    order: order,
    amount: amount,
    customerName: customerName,
    customerEmail: customerEmail,
    customerPhone: customerPhone,
  );
  final verified = await _verifyRazorpayPayment(payment);

  return PaymentResult(
    method: 'Razorpay',
    status: verified ? 'paid' : 'failed',
    reference: payment.paymentId,
  );
}

Future<Map<String, dynamic>> _createRazorpayOrder({
  required double amount,
  required String paymentMethod,
}) async {
  final response = await Supabase.instance.client.functions.invoke(
    'create-razorpay-order',
    body: {
      'amount': amount,
      'currency': 'INR',
      'payment_method': paymentMethod,
    },
  );

  final data = response.data;
  if (data is Map && data['error'] != null) {
    throw StateError(data['error'].toString());
  }
  if (data is! Map) {
    throw StateError('Invalid Razorpay order response.');
  }
  return Map<String, dynamic>.from(data);
}

Future<_RazorpayPayment> _openRazorpayCheckout({
  required Map<String, dynamic> order,
  required double amount,
  required String customerName,
  required String customerEmail,
  required String customerPhone,
}) {
  final razorpayFactory = globalContext['Razorpay'] as JSFunction?;
  if (razorpayFactory == null) {
    throw StateError('Razorpay Checkout script failed to load.');
  }

  final completer = Completer<_RazorpayPayment>();
  final options =
      {
            'key': AppConfig.razorpayKeyId,
            'amount': ((order['amount'] as num?) ?? (amount * 100)).round(),
            'currency': order['currency'] ?? 'INR',
            'name': 'Ace Technologies',
            'description': 'Ace Technologies order payment',
            'order_id': order['id'],
            'prefill': {
              'name': customerName,
              'email': customerEmail,
              'contact': customerPhone,
            },
            'theme': {'color': '#009688'},
            'handler': ((JSObject response) {
              if (completer.isCompleted) return;
              completer.complete(
                _RazorpayPayment(
                  orderId: _readRequiredString(response, 'razorpay_order_id'),
                  paymentId: _readRequiredString(
                    response,
                    'razorpay_payment_id',
                  ),
                  signature: _readRequiredString(
                    response,
                    'razorpay_signature',
                  ),
                ),
              );
            }).toJS,
            'modal': {
              'ondismiss': (() {
                if (!completer.isCompleted) {
                  completer.completeError(StateError('Payment cancelled.'));
                }
              }).toJS,
            },
          }.jsify()
          as JSObject;

  final checkout = razorpayFactory.callAsConstructor<JSObject>(options);
  checkout.callMethod('open'.toJS);
  return completer.future;
}

Future<bool> _verifyRazorpayPayment(_RazorpayPayment payment) async {
  final response = await Supabase.instance.client.functions.invoke(
    'verify-razorpay-payment',
    body: {
      'razorpay_order_id': payment.orderId,
      'razorpay_payment_id': payment.paymentId,
      'razorpay_signature': payment.signature,
    },
  );

  final data = response.data;
  if (data is Map && data['error'] != null) {
    throw StateError(data['error'].toString());
  }
  if (data is Map && data['verified'] == true) {
    return true;
  }
  throw StateError('Payment verification failed.');
}

String _readRequiredString(JSObject object, String property) {
  final value = object[property];
  if (value == null) {
    throw StateError('Missing Razorpay field: $property.');
  }
  return (value as JSString).toDart;
}

class _RazorpayPayment {
  const _RazorpayPayment({
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });

  final String orderId;
  final String paymentId;
  final String signature;
}
