class PaymentResult {
  const PaymentResult({
    required this.method,
    required this.status,
    this.reference,
  });

  final String method;
  final String status;
  final String? reference;
}
