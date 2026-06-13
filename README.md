# Ace Technologies

Flutter app for Ace Technologies IT products, services, cart, orders, and support chat.

## Requirements

- Flutter SDK matching `pubspec.yaml`
- Supabase project with the migrations in `supabase/migrations`
- Razorpay account for live payments

## Local Setup

```powershell
flutter pub get
flutter run --dart-define-from-file=env.json
```

Create `env.json` from `env.example.json` and provide environment-specific values:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `PAYMENT_GATEWAY`
- `RAZORPAY_KEY_ID`
- `GEMINI_API_KEY` when enabling Gemini-backed chat

## Validation

```powershell
flutter analyze
flutter test
flutter build web --dart-define-from-file=env.json
```

## CI E2E Report

Every push can generate the Selenium `.xlsx` E2E report through
`.github/workflows/e2e-report.yml`. The workflow:

- builds Flutter web with a generated `env.ci.json`
- runs `npm run test:e2e`
- uploads `reports/*.xlsx` and `reports/evidence/**` as GitHub Actions artifacts

Recommended GitHub repository secrets:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `PAYMENT_GATEWAY`
- `RAZORPAY_KEY_ID`
- `APP_REDIRECT_URL`
- `GEMINI_API_KEY` if needed

If secrets are not set, the workflow falls back to placeholder values so the
report pipeline can still run for route-level UI coverage.

## Production Checklist

- Use live Razorpay keys and webhook secrets.
- Configure Supabase production URL, anon key, and Edge Function secrets.
- Replace Android debug signing with a Play/App Store signing setup before publishing.
- Build and test the final target platform with production `--dart-define` values.

See [docs/deployment.md](docs/deployment.md) for web hosting, Supabase, Razorpay, and Android signing steps.
