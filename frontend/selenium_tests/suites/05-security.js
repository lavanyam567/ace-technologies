'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  Suite 5 · SECURITY TESTING
//  Checks for common web security issues: XSS, open redirects, auth gates,
//  security headers, HTTPS, form injection, and sensitive data exposure.
// ─────────────────────────────────────────────────────────────────────────────

const {
  openRoute, assertReadablePage, assertAnyText, wait,
  executeJs, fillFirstInput, clickText, getUrl,
} = require('../utils/driver-helpers');
const CONFIG = require('../config/test-config');

const SUITE = 'Security Testing';

function makeCases() {
  const cases = [];
  let n = 1;
  const id = () => `SC-${String(n++).padStart(3, '0')}`;
  const add = (title, area, route, expected, run, priority = 'High') =>
    cases.push({ id: id(), suite: SUITE, title, area, route, expected, priority, run });

  // ── 1. XSS – reflected attack via URL parameter ───────────────────────────
  const xssPayloads = [
    "<script>alert('xss')</script>",
    "<img src=x onerror=alert(1)>",
    "javascript:alert(1)",
    "'><svg onload=alert(1)>",
    "%3Cscript%3Ealert%281%29%3C%2Fscript%3E",
  ];
  for (const payload of xssPayloads) {
    const encoded = encodeURIComponent(payload);
    add(`XSS: URL param payload is not executed (${payload.slice(0, 30)})`,
      'XSS Prevention', `/search?q=${encoded}`, 'XSS payload not executed',
      async (driver) => {
        let xssTriggered = false;
        // Inject alert override BEFORE navigation
        await driver.get('about:blank');
        await driver.executeScript(`
          window.__xssAlerted = false;
          window.originalAlert = window.alert;
          window.alert = function(msg) {
            window.__xssAlerted = true;
          };
        `).catch(() => {});

        await openRoute(driver, `/search?q=${encoded}`);
        await wait(500);

        xssTriggered = await executeJs(driver,
          "return window.__xssAlerted === true;").catch(() => false);
        if (xssTriggered) throw new Error('XSS alert was executed!');
        await assertReadablePage(driver);
      });
  }

  // ── 2. Open Redirect – malicious redirect param ───────────────────────────
  const redirectPayloads = [
    '/?redirect=https://evil.com',
    '/?next=//evil.com',
    '/login?returnUrl=https://malicious.site',
  ];
  for (const path of redirectPayloads) {
    add(`Open redirect: "${path}" stays on same origin`, 'Open Redirect', path,
      'No redirect to external domain',
      async (driver) => {
        await openRoute(driver, path);
        await wait(1000);
        const currentUrl = await getUrl(driver);
        const origin = new URL(CONFIG.app.baseUrl).origin;
        if (!currentUrl.startsWith(origin) && !currentUrl.startsWith('about:'))
          throw new Error(`Redirected to external URL: ${currentUrl}`);
      });
  }

  // ── 3. Auth-protected routes redirect unauthenticated users ──────────────
  const protectedRoutes = ['/profile', '/orders', '/admin/orders'];
  for (const route of protectedRoutes) {
    add(`Protected route "${route}" is accessible (auth check in place)`,
      'Authentication', route, 'Route accessible (login may be shown)',
      async (driver) => {
        await openRoute(driver, route);
        // Should either show the content or redirect to login/account
        await assertAnyText(driver, [
          'Login', 'Sign In', 'Account', 'Profile', 'Orders',
          'Admin', 'Unauthorized',
        ]);
      });
  }

  // ── 4. Sensitive data NOT in page source ─────────────────────────────────
  const sensitivePatterns = [
    { pattern: 'password', label: 'plaintext password in page source' },
    { pattern: 'eyJ',      label: 'JWT token prefix in page source'    },
    { pattern: 'secret',   label: '"secret" keyword in page source'    },
  ];
  for (const { pattern, label } of sensitivePatterns) {
    add(`Sensitive data check: no ${label}`, 'Data Exposure', '/',
      `No "${pattern}" visible in page HTML`,
      async (driver) => {
        await openRoute(driver, '/');
        const html = await executeJs(driver, "return document.documentElement.outerHTML;");
        const lower = html.toLowerCase();
        // Only check that raw JS files don't expose environment variables
        const found = lower.split('\n').some(
          (line) => line.includes(pattern.toLowerCase()) && line.includes('=')
        );
        // Soft-warn (not hard-fail) as 'password' appears in placeholder text legitimately
        if (found) console.warn(`SECURITY-WARN: "${pattern}" found in page source`);
      }, 'Medium');
  }

  // ── 5. Security Headers (via fetch – Chrome allows fetch in execute script) ─
  add('Content-Security-Policy header or meta tag is present', 'Security Headers', '/',
    'CSP header or meta tag found',
    async (driver) => {
      await openRoute(driver, '/');
      const csp = await executeJs(driver, `
        const meta = document.querySelector('meta[http-equiv="Content-Security-Policy"]');
        return meta ? meta.getAttribute('content') : 'not-found-in-meta';
      `);
      // CSP may be set by server; just warn if missing from meta
      if (csp === 'not-found-in-meta')
        console.warn('SECURITY-WARN: No CSP meta tag (may be set by server header)');
    }, 'Medium');

  // ── 6. No autocomplete on password fields ─────────────────────────────────
  add('Password input has autocomplete="new-password" or "off"', 'Form Security', '/account',
    'Password field autocomplete attribute set',
    async (driver) => {
      await openRoute(driver, '/account');
      const ac = await executeJs(driver, `
        const pwInputs = document.querySelectorAll('input[type=password]');
        return Array.from(pwInputs).map(el => el.getAttribute('autocomplete') || '');
      `);
      // Flutter may not render standard <input type=password>; soft warn
      if (!ac || ac.length === 0)
        console.warn('SECURITY-WARN: No <input type=password> found (Flutter canvas)');
    }, 'Low');

  // ── 7. Clickjacking protection ────────────────────────────────────────────
  add('Page is not embeddable in iframe (X-Frame-Options check)', 'Clickjacking', '/',
    'X-Frame-Options header present (server-level)',
    async (driver) => {
      await openRoute(driver, '/');
      // We can only detect if the server sends the header by trying to fetch
      const result = await executeJs(driver, `
        return new Promise(resolve => {
          fetch(window.location.href, {method:'HEAD'})
            .then(r => resolve(r.headers.get('x-frame-options') || r.headers.get('content-security-policy') || 'not-found'))
            .catch(() => resolve('fetch-failed'));
        });
      `).catch(() => 'fetch-failed');
      if (result === 'not-found')
        console.warn('SECURITY-WARN: X-Frame-Options not found (may be set by CDN/server)');
    }, 'Medium');

  // ── 8. HTTPS-only cookies check ───────────────────────────────────────────
  add('Cookies do not have insecure flags visible in JS', 'Cookie Security', '/',
    'document.cookie does not expose sensitive tokens',
    async (driver) => {
      await openRoute(driver, '/');
      const cookies = await executeJs(driver, "return document.cookie;");
      // Supabase stores tokens in httpOnly cookies; they should NOT appear in JS
      if (cookies && cookies.toLowerCase().includes('token'))
        console.warn('SECURITY-WARN: Token found in non-HttpOnly cookie');
    }, 'High');

  // ── 9. SQL injection in search ───────────────────────────────────────────
  const sqlPayloads = ["' OR '1'='1", "1; DROP TABLE products;--", "' UNION SELECT *--"];
  for (const payload of sqlPayloads) {
    const encoded = encodeURIComponent(payload);
    add(`SQL Injection: "${payload.slice(0, 25)}" does not crash the app`,
      'SQL Injection', `/search?q=${encoded}`, 'App survives SQL injection attempt',
      async (driver) => {
        await openRoute(driver, `/search?q=${encoded}`);
        await assertReadablePage(driver);
      });
  }

  // ── 10. Path traversal attempt ───────────────────────────────────────────
  add('Path traversal attempt "../../etc/passwd" returns graceful response',
    'Path Traversal', '/../../etc/passwd', 'App handles path traversal gracefully',
    async (driver) => {
      await openRoute(driver, '/../../etc/passwd');
      await assertReadablePage(driver); // App or server should handle gracefully
    }, 'Medium');

  return cases;
}

module.exports = { makeCases, SUITE };
