# Production Configuration

Pass runtime configuration with `--dart-define` instead of hardcoding it in
source files.

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-supabase-anon-key \
  --dart-define=PAYMENT_GATEWAY=razorpay \
  --dart-define=RAZORPAY_KEY_ID=rzp_test_your_key_id
```

For release builds, pass the same values to `flutter build`.

```sh
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-supabase-anon-key \
  --dart-define=PAYMENT_GATEWAY=razorpay \
  --dart-define=RAZORPAY_KEY_ID=rzp_live_your_key_id
```

Do not commit real environment files. Use `.env.example` only as a template.

For local development, you can also create an ignored `env.json` file from
`env.example.json` and run:

```sh
flutter run -d chrome --dart-define-from-file=env.json
```

Use the same `--dart-define-from-file=env.json` option for release builds or
replace it with CI/CD secret injection.

`PAYMENT_GATEWAY=razorpay` enables Razorpay Checkout for card, UPI,
netbanking, and wallet payments on Flutter web. Keep `RAZORPAY_KEY_SECRET`
out of Flutter and configure it only as a Supabase Edge Function secret:

```sh
supabase secrets set RAZORPAY_KEY_ID=rzp_live_your_key_id
supabase secrets set RAZORPAY_KEY_SECRET=your_razorpay_secret
supabase secrets set RAZORPAY_WEBHOOK_SECRET=your_razorpay_webhook_secret
```

Then deploy the payment functions:

```sh
supabase functions deploy create-razorpay-order
supabase functions deploy verify-razorpay-payment
supabase functions deploy razorpay-webhook --no-verify-jwt
```

Configure this webhook URL in the Razorpay dashboard:

```text
https://your-project-ref.supabase.co/functions/v1/razorpay-webhook
```

Subscribe to payment events such as `payment.captured` and
`payment.failed`.
