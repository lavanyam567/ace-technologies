import 'payment_models.dart';
import 'payment_service_platform.dart'
    if (dart.library.html) 'payment_service_web.dart';

class PaymentService {
  const PaymentService._();

  static const instance = PaymentService._();

  Future<PaymentResult> preparePayment({
    required String method,
    required double amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) {
    return preparePlatformPayment(
      method: method,
      amount: amount,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
    );
  }
}
