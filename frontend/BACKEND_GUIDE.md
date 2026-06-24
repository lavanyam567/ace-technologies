# Ace Technologies Backend Guide

This app uses Supabase as the backend. Supabase gives the Flutter app a hosted PostgreSQL database, authentication, row-level security, and auto-generated REST APIs. There is no separate Express server required for the current implementation.

## Project Connection

Flutter reads Supabase configuration from compile-time environment values in:

```text
lib/core/config/app_config.dart
```

Run the app with:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your-public-anon-key
```

Important: the URL must be the project root URL. Do not add `/rest/v1/` to it.

## How The Backend Works

The database schema lives in:

```text
supabase/migrations/20260512042939_ace_backend.sql
```

That migration creates the backend tables, policies, triggers, and seed data.

Main tables:

```text
profiles           User profile data linked to Supabase Auth users
categories         Product categories
products           Product catalog
services           Service catalog
addresses          Customer addresses
cart_items         User cart rows
wishlist_items     User wishlist rows
orders             Order headers
order_items        Products inside each order
service_bookings   Booked services and schedule slots
reviews            Product reviews
```

Security is handled with Supabase Row Level Security.

Public users can read:

```text
categories
products
services
reviews
```

Signed-in users can manage only their own:

```text
profiles
addresses
cart_items
wishlist_items
orders
service_bookings
reviews
```

## Flutter API Layer

The main Supabase wrapper is:

```text
lib/core/services/supabase_service.dart
```

It contains methods for:

```text
fetchProducts()
fetchServices()
signIn()
signUp()
signOut()
addCartItem()
removeCartItem()
clearCart()
createServiceBooking()
```

The UI does not call Supabase everywhere directly. Instead, providers call `SupabaseService`, then screens read provider state.

Important provider files:

```text
lib/features/products/providers/product_providers.dart
lib/features/services/providers/service_providers.dart
lib/features/providers/auth_provider.dart
lib/features/providers/cart_provider.dart
lib/features/services/providers/booking_providers.dart
```

Products and services load from Supabase first. If Supabase fails or returns empty data, the app falls back to the existing sample data so the UI can still run.

## Initialize On A New Machine

From the project root:

```powershell
cd D:\PDD_final\my_app
flutter pub get
```

Install or verify Supabase CLI:

```powershell
supabase --version
```

Login or use an access token:

```powershell
supabase login
```

Link the local folder to the Supabase project:

Use your own Supabase project reference when linking the local folder.

Push migrations to the remote database:

```powershell
supabase db push
```

Check migration status:

```powershell
supabase migration list
```

Run the Flutter app:

```powershell
flutter run
```

## Initialize With An Access Token

If using a Supabase access token in PowerShell:

```powershell
$env:SUPABASE_ACCESS_TOKEN="your-token-here"
supabase link --project-ref your-project-ref
supabase db push
```

Do not commit access tokens. If a token was pasted into chat or stored somewhere unsafe, rotate it from the Supabase dashboard.

## Common Development Commands

Analyze Flutter code:

```powershell
flutter analyze
```

Format Dart files:

```powershell
dart format lib
```

Run tests:

```powershell
flutter test
```

Create a new migration:

```powershell
supabase migration new migration_name
```

Push database changes:

```powershell
supabase db push
```

## App Data Flow

Product listing:

```text
ProductsScreen
-> filteredProductsProvider
-> productsProvider
-> SupabaseService.fetchProducts()
-> public.products
```

Service listing:

```text
Services screen/detail screens
-> servicesProvider / serviceByIdProvider
-> SupabaseService.fetchServices()
-> public.services
```

Authentication:

```text
Login/signup UI
-> authProvider
-> SupabaseService.signIn/signUp()
-> Supabase Auth
-> public.profiles on signup
```

Cart:

```text
Add/remove cart actions
-> cartProvider
-> SupabaseService.addCartItem/removeCartItem/clearCart()
-> public.cart_items
```

Service booking:

```text
BookServiceScreen
-> serviceBookingsProvider.addBooking()
-> SupabaseService.createServiceBooking()
-> public.service_bookings
```

## Notes

- The current frontend stores cart state locally first, then syncs cart changes to Supabase for signed-in users.
- Some older legacy Provider files still exist for older screens. The newer Riverpod providers are the main backend-connected path.
- If an insert fails with `Please sign in first`, the user is not authenticated. Supabase RLS requires a valid signed-in user for private tables.
- If product or service screens show sample data, Supabase either returned no rows or the request failed. Check the Supabase table data and browser/app logs.
