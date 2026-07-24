# Backend Security Detailed Review

### [API-001] Auth - Low
- **Issue:** Fallback secrets in config
- **Recommendation:** Remove default fallback secrets

### [API-002] RateLimit - Low
- **Issue:** Missing rate limiting on /api/status
- **Recommendation:** Apply global rate limiter

### [API-003] CORS - Low
- **Issue:** Overly permissive CORS on public endpoints
- **Recommendation:** Restrict CORS to known domains

### [API-004] Auth - Low
- **Issue:** Unauthenticated health check endpoint
- **Recommendation:** Add basic auth or obscure endpoint

### [API-005] Headers - Low
- **Issue:** Missing strict-transport-security (HSTS)
- **Recommendation:** Enable HSTS

### [API-006] Dependencies - Low
- **Issue:** lodash version is old
- **Recommendation:** Upgrade lodash

### [API-007] Logging - Low
- **Issue:** Logs contain non-redacted request bodies
- **Recommendation:** Mask PII in logger

### [API-008] ErrorHandling - Low
- **Issue:** Stack traces visible in dev mode
- **Recommendation:** Ensure NODE_ENV=production suppresses traces

### [API-009] Headers - Low
- **Issue:** X-Powered-By header is present
- **Recommendation:** Disable X-Powered-By in Express

### [API-010] Session - Low
- **Issue:** JWT expiration is > 24 hours
- **Recommendation:** Reduce JWT TTL to 1 hour

### [API-011] Config - Low
- **Issue:** Hardcoded pagination limits
- **Recommendation:** Move MAX_LIMIT to environment config

### [API-012] Validation - Low
- **Issue:** Missing strict type casting on query params
- **Recommendation:** Use Joi or Zod for validation

### [API-013] Database - Low
- **Issue:** Missing connection pool idle timeout
- **Recommendation:** Set idle timeout for DB pool

### [API-014] Network - Low
- **Issue:** No request timeout configured
- **Recommendation:** Add 30s timeout middleware

