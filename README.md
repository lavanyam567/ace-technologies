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

Every push can generate the Selenium `.xlsx` E2E and vulnerability report through
`.github/workflows/e2e-report.yml`. The workflow:

- builds Flutter web with a generated `env.ci.json`
- runs `npm run test:e2e`
- includes route/UI coverage plus vulnerability checks such as XSS, open redirect,
  injection, path traversal, unsafe links, and secret exposure probes
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

## CI Mobile Appium Report

Android mobile coverage now has a separate Appium pipeline in
`.github/workflows/mobile-appium-report.yml`. That workflow:

- builds the Flutter Android debug APK with a generated `env.ci.json`
- boots a GitHub Actions Android emulator
- starts Appium with the `uiautomator2` driver
- runs the separate `appium_tests` suite with `301` generated cases across
  functional, UI/UX, compatibility, and E2E coverage
- uploads `appium_tests/reports/*.xlsx`, `appium_tests/reports/evidence/**`,
  `appium_tests/TEST_SUMMARY.md`, and the Appium server log as artifacts

Additional recommended GitHub repository secrets for real mobile login coverage:

- `TEST_EMAIL`
- `TEST_PASSWORD`
- `ADMIN_EMAIL`

## CI Baseline Load Report

Baseline performance coverage now has a separate k6 pipeline in
`.github/workflows/k6-baseline-report.yml`. It runs a `100` virtual-user
baseline test for `1 minute` against the public Supabase-backed catalog
endpoints, exports the k6 summary JSON, converts the results into an Excel
workbook, and uploads both artifacts on every push to `main`.

## Production Checklist

- Use live Razorpay keys and webhook secrets.
- Configure Supabase production URL, anon key, and Edge Function secrets.
- Replace Android debug signing with a Play/App Store signing setup before publishing.
- Build and test the final target platform with production `--dart-define` values.

See [docs/deployment.md](docs/deployment.md) for web hosting, Supabase, Razorpay, and Android signing steps.
