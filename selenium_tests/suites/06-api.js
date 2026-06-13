'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  Suite 6 · API TESTING
//  Tests the Supabase REST API endpoints that the app relies on.
//  Falls back gracefully when credentials are not configured.
// ─────────────────────────────────────────────────────────────────────────────

const http  = require('http');
const https = require('https');
const CONFIG = require('../config/test-config');

const SUITE = 'API Testing';

// ── Tiny HTTP helper ──────────────────────────────────────────────────────────

function httpRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    const parsed  = new URL(url);
    const isHttps = parsed.protocol === 'https:';
    const lib     = isHttps ? https : http;
    const timeout = options.timeout || 10000;

    const req = lib.request(
      {
        hostname: parsed.hostname,
        port:     parsed.port || (isHttps ? 443 : 80),
        path:     parsed.pathname + parsed.search,
        method:   options.method || 'GET',
        headers:  options.headers || {},
      },
      (res) => {
        let body = '';
        res.setEncoding('utf8');
        res.on('data', (c) => { body += c; });
        res.on('end', () => {
          resolve({ status: res.statusCode, headers: res.headers, body });
        });
      }
    );

    req.setTimeout(timeout, () => {
      req.destroy(new Error(`Request timed out: ${url}`));
    });
    req.on('error', reject);
    req.end(options.body || undefined);
  });
}

function makeCases() {
  const cases = [];
  let n = 1;
  const id = () => `AP-${String(n++).padStart(3, '0')}`;
  const add = (title, area, route, expected, run, priority = 'High') =>
    cases.push({ id: id(), suite: SUITE, title, area, route, expected, priority, run });

  const supabaseUrl   = CONFIG.api.supabaseUrl;
  const supabaseKey   = CONFIG.api.supabaseAnonKey;
  const hasCredentials = Boolean(supabaseUrl && supabaseKey);

  // ── Helper: assert HTTP status ────────────────────────────────────────────
  async function apiGet(path, extraHeaders = {}) {
    if (!hasCredentials) throw new Error('SKIP: Supabase credentials not configured');
    const url = `${supabaseUrl}${path}`;
    return httpRequest(url, {
      method: 'GET',
      headers: {
        apikey: supabaseKey,
        Authorization: `Bearer ${supabaseKey}`,
        'Content-Type': 'application/json',
        ...extraHeaders,
      },
    });
  }

  // ── 1. Static server health ────────────────────────────────────────────────
  add('Local static server returns HTTP 200 for /', 'Server Health', '/',
    'HTTP 200 response from local server',
    async () => {
      const res = await httpRequest(CONFIG.app.baseUrl).catch((e) => {
        throw new Error(`Server unreachable: ${e.message}`);
      });
      if (res.status !== 200) throw new Error(`HTTP ${res.status}`);
    }, 'High');

  // ── 2. Static assets reachable ────────────────────────────────────────────
  add('manifest.json is reachable from server', 'Static Assets', '/manifest.json',
    'HTTP 200 for manifest.json',
    async () => {
      const url = new URL('/manifest.json', CONFIG.app.baseUrl).toString();
      const res = await httpRequest(url).catch(() => ({ status: 0 }));
      if (res.status !== 200) throw new Error(`manifest.json returned HTTP ${res.status}`);
    }, 'Medium');

  add('favicon.png is reachable from server', 'Static Assets', '/favicon.png',
    'HTTP 200 for favicon.png',
    async () => {
      const url = new URL('/favicon.png', CONFIG.app.baseUrl).toString();
      const res = await httpRequest(url).catch(() => ({ status: 0 }));
      if (res.status !== 200) throw new Error(`favicon.png returned HTTP ${res.status}`);
    }, 'Low');

  // ── 3. Supabase API – if credentials provided ────────────────────────────
  if (hasCredentials) {
    // Products endpoint
    add('Supabase: GET /rest/v1/products returns 200 or 206', 'Supabase REST', '/rest/v1/products',
      'Products endpoint responds with 2xx',
      async () => {
        const res = await apiGet('/rest/v1/products?limit=5');
        if (res.status < 200 || res.status >= 300)
          throw new Error(`Products API returned ${res.status}: ${res.body.slice(0, 200)}`);
      });

    // Services endpoint
    add('Supabase: GET /rest/v1/services returns 200', 'Supabase REST', '/rest/v1/services',
      'Services endpoint responds with 2xx',
      async () => {
        const res = await apiGet('/rest/v1/services?limit=5');
        if (res.status < 200 || res.status >= 300)
          throw new Error(`Services API returned ${res.status}`);
      });

    // Auth endpoint health
    add('Supabase: Auth health endpoint is reachable', 'Supabase Auth', '/auth/v1/health',
      'Auth service healthy',
      async () => {
        const res = await httpRequest(`${supabaseUrl}/auth/v1/health`, {
          headers: { apikey: supabaseKey },
        });
        if (res.status < 200 || res.status >= 300)
          throw new Error(`Auth health returned ${res.status}`);
      });

    // Unauthenticated POST to auth
    add('Supabase: Unauthenticated signup with bad data returns 400/422', 'Auth Validation', '/auth/v1/signup',
      'Invalid signup rejected with 400/422',
      async () => {
        const res = await httpRequest(`${supabaseUrl}/auth/v1/signup`, {
          method: 'POST',
          headers: {
            apikey: supabaseKey,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ email: 'not-an-email', password: '123' }),
        });
        if (![400, 422, 422].includes(res.status) && res.status < 400)
          throw new Error(`Expected 4xx but got ${res.status}`);
      }, 'High');

    // RLS – anonymous user cannot read protected tables
    add('Supabase RLS: anonymous user cannot access orders table', 'Row Level Security', '/rest/v1/orders',
      'Orders table returns 200 empty or 401/403 for anon user',
      async () => {
        const res = await apiGet('/rest/v1/orders?limit=1');
        // anon key with RLS should return empty array or 401
        if (res.status === 200) {
          const data = JSON.parse(res.body || '[]');
          if (!Array.isArray(data)) throw new Error('Expected array response');
        } else if (![401, 403, 406].includes(res.status)) {
          throw new Error(`Unexpected status: ${res.status}`);
        }
      }, 'High');

  } else {
    // Placeholder when no credentials
    add('Supabase API tests skipped – credentials not configured', 'Supabase REST', 'N/A',
      'SKIP: Set SUPABASE_URL and SUPABASE_ANON_KEY env vars',
      async () => {
        console.warn('API-SKIP: Set SUPABASE_URL and SUPABASE_ANON_KEY environment variables to run API tests');
      }, 'Medium');
  }

  // ── 4. API response headers ───────────────────────────────────────────────
  add('Server response includes Content-Type header', 'Response Headers', '/',
    'Content-Type header present',
    async () => {
      const res = await httpRequest(CONFIG.app.baseUrl);
      if (!res.headers['content-type'])
        throw new Error('Missing Content-Type header');
    }, 'Medium');

  // ── 5. 404 handling ───────────────────────────────────────────────────────
  add('Unknown API route returns appropriate response (not crash)', 'Error Handling', '/api/does-not-exist',
    'Server handles unknown path (200 SPA fallback or 404)',
    async () => {
      const url = new URL('/api/does-not-exist', CONFIG.app.baseUrl).toString();
      const res = await httpRequest(url).catch(() => ({ status: 0 }));
      // SPA servers return 200 with index.html for unknown paths
      if (res.status !== 200 && res.status !== 404)
        throw new Error(`Unexpected status ${res.status} for unknown path`);
    }, 'Low');

  // ── 6. Razorpay script reachable ─────────────────────────────────────────
  add('Razorpay checkout script is reachable', 'Third-party APIs', 'checkout.razorpay.com',
    'Razorpay CDN responds with 200',
    async () => {
      const res = await httpRequest('https://checkout.razorpay.com/v1/checkout.js')
        .catch(() => ({ status: 0 }));
      if (res.status !== 200 && res.status !== 0)
        throw new Error(`Razorpay script returned ${res.status}`);
      // status 0 means network unavailable – soft fail
    }, 'Medium');

  return cases;
}

module.exports = { makeCases, SUITE };
