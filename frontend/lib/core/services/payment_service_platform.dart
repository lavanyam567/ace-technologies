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

  throw UnsupportedError(
    'Online payments are currently supported on Flutter web in this build.',
  );
}
