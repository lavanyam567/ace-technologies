# Google Sign-In Setup

Google Sign-In is handled by Supabase Auth OAuth.

## Google Cloud Console

Create an OAuth 2.0 Client ID for a web application.

Authorized JavaScript origins:

```text
http://localhost:58488
```

Add the production app URL after deployment.

Authorized redirect URI:

```text
https://bjjvvqlztmfjskxsykmz.supabase.co/auth/v1/callback
```

## Supabase Dashboard

Open:

```text
Authentication > Providers > Google
```

Enable Google and paste:

```text
Client ID
Client Secret
```

Then open:

```text
Authentication > URL Configuration
```

Site URL for local testing:

```text
http://localhost:58488
```

Redirect URLs:

```text
http://localhost:58488
```

Add the production app URL after deployment.

## Run

```powershell
flutter run -d chrome --web-port 58488 --dart-define-from-file=env.json
```
