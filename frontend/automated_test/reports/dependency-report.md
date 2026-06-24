# Dependency Report

- Technology Detected: Supabase Edge Functions + PostgREST + SQL migrations
- Review Mode: Offline manifest and source inspection
- Critical Findings: 0
- High Findings: 0

| Dependency | Source | Status | Notes |
|---|---|---|---|
| @supabase/supabase-js@2 | `supabase/functions/_shared/auth.ts` | Review needed | Remote ESM import is pinned only to major version 2, so patch-level drift is possible without repo-visible lock data. |
| Supabase Edge Runtime (Deno 2) | `supabase/config.toml` | Review needed | The runtime is pinned to major version 2 but not to a specific patch level in source control. |
| Razorpay Orders API | `supabase/functions/create-razorpay-order/index.ts` | Review needed | External payment dependency is invoked directly and should be covered by timeout, retry, and signature-handling standards. |
| Supabase Auth email confirmations | `supabase/config.toml` | Configured weakly | Email confirmation is disabled in local auth config, which is acceptable for dev but worth tracking in security reviews. |
