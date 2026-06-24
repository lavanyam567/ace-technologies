# Live Deployment Guide

The codebase is already configured to seamlessly transition from `localhost` to your live deployment!

It uses `Uri.base.origin` dynamically, which means that when you deploy the app to the web (e.g., via Vercel, Netlify, or Firebase Hosting), the app will automatically use your live URL (like `https://my-live-app.com`) instead of `localhost`. 

**No hardcoded changes to the Flutter code are required.**

However, because authentication relies on third-party services, you must update the settings on **Supabase** and **Google Cloud Console** so they know to accept requests from your new live URL.

Follow these steps once you have deployed your app and have your live URL:

## 1. Supabase Dashboard Configuration

Supabase needs to know that your live URL is allowed to authenticate users.

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard).
2. Open your project and navigate to **Authentication > URL Configuration**.
3. Under **Site URL**, change `http://localhost:58488` to your live URL (e.g., `https://your-live-app.com`).
4. Under **Redirect URLs**, click **Add URL** and add your live URL. You can keep the localhost one if you still want to test locally.

## 2. Google Cloud Console (OAuth)

Google needs to be told that your live URL is authorized to request Sign-Ins.

1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Navigate to **APIs & Services > Credentials**.
3. Edit your existing **OAuth 2.0 Client ID** (the one you made for the Web application).
4. Under **Authorized JavaScript origins**, click **ADD URI** and paste your live URL (e.g., `https://your-live-app.com`).
5. *Note: The **Authorized redirect URIs** (which points to `https://bjjvvqlztmfjskxsykmz.supabase.co/auth/v1/callback`) remains the same and does not need to be changed.*
6. Click **Save**.

## 3. (Optional) Production Environment Variables

When you deploy your app (using CI/CD or directly building it), make sure you are passing your production environment variables (from your `env.production.json`) to the build command:

```bash
flutter build web --dart-define-from-file=env.production.json
```

If you ever want to force a specific redirect URL instead of letting the app figure it out dynamically, you can add `APP_REDIRECT_URL` to your environment variables:

```json
{
  "SUPABASE_URL": "...",
  "SUPABASE_ANON_KEY": "...",
  "PAYMENT_GATEWAY": "razorpay",
  "RAZORPAY_KEY_ID": "...",
  "APP_REDIRECT_URL": "https://your-live-app.com"
}
```
