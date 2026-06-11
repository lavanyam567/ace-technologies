class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const paymentGateway = String.fromEnvironment(
    'PAYMENT_GATEWAY',
    defaultValue: 'cod',
  );
  static const razorpayKeyId = String.fromEnvironment('RAZORPAY_KEY_ID');
  static const appRedirectUrl = String.fromEnvironment('APP_REDIRECT_URL');

  static bool get onlinePaymentsEnabled => paymentGateway != 'cod';
  static String get oauthRedirectUrl =>
      appRedirectUrl.isNotEmpty ? appRedirectUrl : Uri.base.origin;

  static void validate() {
    final missing = <String>[
      if (supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
    ];

    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required environment configuration: ${missing.join(', ')}. '
        'Run with --dart-define=SUPABASE_URL=... '
        '--dart-define=SUPABASE_ANON_KEY=...',
      );
    }
  }
}
