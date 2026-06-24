# Backend Security Review

- Technology Detected: Supabase Edge Functions + PostgREST + SQL migrations
- Security Score: 72/100
- Risk Rating: Low Risk
- Critical Findings: 0
- High Findings: 0
- Medium Findings: 0
- Low Findings: 14
- Endpoint Inventory Count: 37

## Endpoint Inventory Snapshot

| Method | Path | Auth Coverage | Source |
|---|---|---|---|
| POST | `/functions/v1/create-razorpay-order` | JWT required | `supabase/functions/create-razorpay-order/index.ts` |
| POST | `/functions/v1/razorpay-webhook` | Signature protected | `supabase/functions/razorpay-webhook/index.ts` |
| POST | `/functions/v1/verify-razorpay-payment` | JWT required | `supabase/functions/verify-razorpay-payment/index.ts` |
| GET | `/rest/v1/addresses` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| INSERT | `/rest/v1/addresses` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| UPDATE | `/rest/v1/addresses` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| DELETE | `/rest/v1/addresses` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| GET | `/rest/v1/cart_items` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| UPSERT | `/rest/v1/cart_items` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| DELETE | `/rest/v1/cart_items` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| GET | `/rest/v1/compare_items` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| UPSERT | `/rest/v1/compare_items` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| DELETE | `/rest/v1/compare_items` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| GET | `/rest/v1/order_items` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| INSERT | `/rest/v1/order_items` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| GET | `/rest/v1/orders` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| UPDATE | `/rest/v1/orders` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| INSERT | `/rest/v1/orders` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| GET | `/rest/v1/products` | Public read path in RLS | `lib/core/services/supabase_service.dart` |
| UPDATE | `/rest/v1/products` | Public read path in RLS | `lib/core/services/supabase_service.dart` |
| UPSERT | `/rest/v1/profiles` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| GET | `/rest/v1/profiles` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| GET | `/rest/v1/recently_viewed_products` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| UPSERT | `/rest/v1/recently_viewed_products` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| DELETE | `/rest/v1/recently_viewed_products` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| GET | `/rest/v1/reviews` | Public read path in RLS | `lib/core/services/supabase_service.dart` |
| INSERT | `/rest/v1/reviews` | Public read path in RLS | `lib/core/services/supabase_service.dart` |
| POST | `/rest/v1/rpc/create_order_with_items` | Authenticated grant detected | `supabase\migrations\20260526093000_create_order_rpc.sql` |
| POST | `/rest/v1/rpc/is_admin` | Authenticated grant detected | `supabase\migrations\20260526103000_admin_order_management.sql` |
| POST | `/rest/v1/rpc/update_admin_order_status` | Authenticated grant detected | `supabase\migrations\20260530103000_admin_update_order_status_rpc.sql` |
| GET | `/rest/v1/service_bookings` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| INSERT | `/rest/v1/service_bookings` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| UPDATE | `/rest/v1/service_bookings` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| GET | `/rest/v1/services` | Public read path in RLS | `lib/core/services/supabase_service.dart` |
| GET | `/rest/v1/wishlist_items` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| UPSERT | `/rest/v1/wishlist_items` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |
| DELETE | `/rest/v1/wishlist_items` | Authenticated or owner-scoped path | `lib/core/services/supabase_service.dart` |

## Findings

### API-001. Edge functions allow all origins
- Severity: Low
- Category: CORS
- Evidence: `supabase/functions/_shared/cors.ts:2`
- Description: Shared CORS headers set `Access-Control-Allow-Origin` to `*`, which keeps integration simple but does not enforce an origin allowlist.
- Recommendation: Restrict allowed origins per environment, especially for production payment routes.

```text
export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
```

### API-002. No rate limiting logic is present in edge functions
- Severity: Low
- Category: Abuse Prevention
- Evidence: `supabase/functions:1`
- Description: The reviewed payment-related edge functions do not enforce per-user or per-IP throttling before performing work.
- Recommendation: Apply rate limiting at the edge gateway or within the function handlers for payment and auth-adjacent routes.

```text
No throttling or rate limiting checks were found in the reviewed edge function handlers.
```

### API-003. Order creation accepts client-supplied currency values
- Severity: Low
- Category: Input Validation
- Evidence: `supabase/functions/create-razorpay-order/index.ts:31`
- Description: The order creation function lets the request body set the currency with only a default fallback, which increases the need for server-side allowlisting.
- Recommendation: Restrict currency to an allowlist and reject unsupported values explicitly.

```text
const amountInPaise = Math.round(amount * 100);
    const currency = body.currency ?? "INR";
    const receipt = `ace_${crypto.randomUUID()}`;
```

### API-004. Order creation trusts client-supplied amounts
- Severity: Low
- Category: Business Logic
- Evidence: `supabase/functions/create-razorpay-order/index.ts:25`
- Description: The order creation function forwards a client-provided amount to Razorpay without reconciling it against server-side cart totals.
- Recommendation: Recalculate the payable amount from trusted order data before creating payment orders.

```text
const body = (await req.json()) as CreateOrderBody;
    const amount = Number(body.amount ?? 0);
    if (!Number.isFinite(amount) || amount <= 0) {
```

### API-005. Edge function error responses expose raw exception text
- Severity: Low
- Category: Error Handling
- Evidence: `supabase/functions/create-razorpay-order/index.ts:63`
- Description: Payment edge functions serialize raw error messages back to callers, which can leak operational details about configuration and validation logic.
- Recommendation: Return smaller user-safe error classes and keep full diagnostics in logs only.

```text
JSON.stringify({
        error: error instanceof Error ? error.message : String(error),
      }),
```

### API-006. Outbound Razorpay requests do not declare a timeout
- Severity: Low
- Category: Availability
- Evidence: `supabase/functions/create-razorpay-order/index.ts:34`
- Description: The payment order function calls Razorpay without an AbortController or explicit timeout, which can leave handlers waiting longer than intended during upstream latency.
- Recommendation: Wrap outbound payment requests in explicit timeout and retry policies.

```text
const razorpayResponse = await fetch("https://api.razorpay.com/v1/orders", {
      method: "POST",
```

### API-007. Webhook processing does not record replay protection metadata
- Severity: Low
- Category: Webhook Security
- Evidence: `supabase/functions/razorpay-webhook/index.ts:38`
- Description: The webhook handler validates the signature but does not store event IDs, timestamps, or nonce data to detect repeated deliveries.
- Recommendation: Persist a delivery identifier or hash and reject duplicate webhook payloads.

```text
const event = JSON.parse(rawBody) as RazorpayWebhookEvent;
    const payment = event.payload?.payment?.entity;
```

### API-008. Edge functions do not enforce content-length or payload size limits
- Severity: Low
- Category: Request Validation
- Evidence: `supabase/functions/verify-razorpay-payment/index.ts:23`
- Description: The reviewed handlers accept request bodies through `req.json()` or `req.text()` without visible size checks.
- Recommendation: Add payload size guards before parsing bodies and pair them with upstream gateway limits.

```text
const body = (await req.json()) as VerifyPaymentBody;
    const orderId = body.razorpay_order_id;
```

### API-009. Local Supabase auth keeps the minimum password length at six
- Severity: Low
- Category: Configuration
- Evidence: `supabase/config.toml:177`
- Description: The current auth config accepts six-character passwords, which is functional but lighter than modern guidance for production-grade credentials.
- Recommendation: Raise the minimum password length and align it with the frontend validation rules.

```text
# Passwords shorter than this value will be rejected as weak. Minimum 6, recommended 8 or more.
minimum_password_length = 6
# Passwords that do not meet the following requirements will be rejected as weak. Supported values
```

### API-010. No additional password composition requirements are configured
- Severity: Low
- Category: Configuration
- Evidence: `supabase/config.toml:180`
- Description: The auth config leaves `password_requirements` empty, so the platform minimum relies only on length.
- Recommendation: Enable stronger password rules or compensate with breached-password screening and MFA.

```text
# are: `letters_digits`, `lower_upper_letters_digits`, `lower_upper_letters_digits_symbols`
password_requirements = ""
```

### API-011. Email confirmations are disabled in the checked-in auth config
- Severity: Low
- Category: Configuration
- Evidence: `supabase/config.toml:221`
- Description: The repository config disables email confirmations, which is common for local development but should be tracked because it weakens account verification if mirrored elsewhere.
- Recommendation: Verify production auth settings separately and keep security review notes explicit about environment differences.

```text
# If enabled, users need to confirm their email address before signing in.
enable_confirmations = false
# If enabled, users will need to reauthenticate or have logged in recently to change their password.
```

### API-012. Secure password change reauthentication is disabled in config
- Severity: Low
- Category: Configuration
- Evidence: `supabase/config.toml:223`
- Description: The checked-in auth config does not require a fresh sign-in before password changes, reducing friction but also reducing assurance for sensitive account updates.
- Recommendation: Enable secure password change in production-facing environments.

```text
# If enabled, users will need to reauthenticate or have logged in recently to change their password.
secure_password_change = false
# Controls the minimum amount of time that must pass before sending another signup confirmation or password reset email.
```

### API-013. Shared auth helper imports supabase-js by floating major version only
- Severity: Low
- Category: Dependency Review
- Evidence: `supabase/functions/_shared/auth.ts:1`
- Description: The edge auth helper pulls `@supabase/supabase-js@2` from esm.sh without a patch-level pin, leaving exact dependency drift outside the repository.
- Recommendation: Pin the remote import to an exact version or document the acceptable update cadence.

```text
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
```

### API-014. Edge runtime version is pinned only at the major level
- Severity: Low
- Category: Dependency Review
- Evidence: `supabase/config.toml:378`
- Description: The Supabase config fixes the edge runtime to Deno major version 2 but does not capture a specific patch level for repeatable security review baselines.
- Recommendation: Track runtime patch upgrades explicitly as part of the dependency review process.

```text
# The Deno major version to use.
deno_version = 2
```
