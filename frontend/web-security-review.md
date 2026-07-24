# Web Security Detailed Review

### [WEB-001] Auth - Low
- **Issue:** PII stored in localStorage
- **Recommendation:** Use sessionStorage or HttpOnly cookies for PII

### [WEB-002] Session - Low
- **Issue:** No session TTL enforced on client
- **Recommendation:** Implement idle timeout logouts

### [WEB-003] Headers - Low
- **Issue:** Missing CSP meta tag
- **Recommendation:** Add Content-Security-Policy header

### [WEB-004] Headers - Low
- **Issue:** Missing X-Frame-Options
- **Recommendation:** Add X-Frame-Options: DENY

### [WEB-005] Config - Low
- **Issue:** Hardcoded base URL in config
- **Recommendation:** Use environment variables

### [WEB-006] Forms - Low
- **Issue:** Autocomplete enabled on sensitive fields
- **Recommendation:** Set autocomplete="off"

### [WEB-007] Dependencies - Low
- **Issue:** Outdated react-router version
- **Recommendation:** Update to latest minor version

### [WEB-008] Logging - Low
- **Issue:** Excessive console.log in prod
- **Recommendation:** Strip console statements in build

### [WEB-009] Network - Low
- **Issue:** Missing preconnect for third-party scripts
- **Recommendation:** Add rel="preconnect"

### [WEB-010] Storage - Low
- **Issue:** Excessive local storage usage
- **Recommendation:** Implement local storage limits

### [WEB-011] UI - Low
- **Issue:** Missing error boundaries
- **Recommendation:** Add global React error boundary

### [WEB-012] Routing - Low
- **Issue:** Unprotected generic 404 handler
- **Recommendation:** Sanitize URL paths in 404 display

### [WEB-013] Auth - Low
- **Issue:** Verbose login error messages
- **Recommendation:** Use generic "Invalid credentials"

### [WEB-014] Assets - Low
- **Issue:** Images lacking lazy loading attributes
- **Recommendation:** Add loading="lazy" to imgs

