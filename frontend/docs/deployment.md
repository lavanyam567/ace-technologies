# Deployment

## Production Environment

Create `env.production.json` from `env.production.example.json`. Keep it private.

Required values:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `PAYMENT_GATEWAY`
- `RAZORPAY_KEY_ID` using a live `rzp_live_...` key
- `APP_REDIRECT_URL` set to the deployed site origin, for example `https://web-rosy-two-12.vercel.app`

Optional:

- `GEMINI_API_KEY`

## Web Build

```powershell
flutter build web --release --dart-define-from-file=env.production.json
```

Deploy `build/web`.

## Hosting

This repo includes static hosting config for:

- Vercel: `vercel.json`
- Netlify: `netlify.toml`
- Firebase Hosting: `firebase.json`

All configs rewrite unknown routes to `index.html`, which is required for Flutter web routing.

## Supabase

Remote migrations can be checked with:

```powershell
supabase migration list
```

Payment secrets required for live Razorpay:

```powershell
supabase secrets set RAZORPAY_KEY_ID=rzp_live_your_key_id
supabase secrets set RAZORPAY_KEY_SECRET=your_live_key_secret
supabase secrets set RAZORPAY_WEBHOOK_SECRET=your_live_webhook_secret
```

Deploy payment functions:

```powershell
supabase functions deploy create-razorpay-order
supabase functions deploy verify-razorpay-payment
supabase functions deploy razorpay-webhook --no-verify-jwt
```

## Android Signing

Create a real keystore and copy `android/key.properties.example` to `android/key.properties`.
The real `android/key.properties` and keystore files are ignored by git.

Then build:

```powershell
flutter build appbundle --release --dart-define-from-file=env.production.json
```
