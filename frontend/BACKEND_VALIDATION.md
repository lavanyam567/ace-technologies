# Backend Validation Report

Validation date: 2026-05-12

## Inserted Test Data

Inserted through Supabase REST/Auth endpoints:

```text
Product: api_test_product_1778605386
Service: api_test_service_1778605386
Auth user: api-test-1778605386@example.com
Address: f48257f5-a237-4caa-83a0-33cfdb82ab43
Order item: d9ca5d96-7ab7-4a23-a693-bb507f6b822a
```

## Endpoint Results

```text
POST /rest/v1/products                  OK
GET  /rest/v1/products                  OK
POST /rest/v1/services                  OK
GET  /rest/v1/services                  OK
POST /auth/v1/admin/users               OK
POST /auth/v1/token?grant_type=password OK
POST /rest/v1/profiles                  OK
POST /rest/v1/addresses                 OK
POST /rest/v1/cart_items                OK
GET  /rest/v1/cart_items                OK
POST /rest/v1/service_bookings          OK
GET  /rest/v1/service_bookings          OK
POST /rest/v1/orders                    OK
GET  /rest/v1/orders                    OK
POST /rest/v1/order_items               OK
```

Public catalog smoke test:

```text
products endpoint: OK, returned 3 rows
services endpoint: OK, returned 3 rows
```

## Fixes Applied

Added an auth trigger migration:

```text
supabase/migrations/20260512170341_add_profile_auth_trigger.sql
```

This creates `public.profiles` rows automatically whenever a Supabase Auth user is created.

Updated:

```text
lib/core/services/supabase_service.dart
```

Added:

```text
createOrder()
```

Updated:

```text
lib/features/cart/screens/checkout_screen.dart
```

Checkout now writes to Supabase `orders` and `order_items` before clearing the cart and routing to order success.

## Migration Status

Local and remote migrations are synced:

```text
20260512042939_ace_backend.sql
20260512170341_add_profile_auth_trigger.sql
```

## Local Tooling Note

`dart analyze` and `dart format` could not run because the local Flutter/Dart toolchain calls `git`, but `git` is not available on PATH:

```text
Error: Unable to determine engine version
git: The term 'git' is not recognized
```

Install Git or add it to PATH, then run:

```powershell
dart format lib
flutter analyze
flutter test
```

