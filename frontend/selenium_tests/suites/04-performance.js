'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  Suite 4 · PERFORMANCE TESTING
//  Measures page load times, TTFB, DOM metrics, resource sizes.
// ─────────────────────────────────────────────────────────────────────────────

const {
  openRoute, wait, getPerformanceMetrics, executeJs, assertReadablePage,
} = require('../utils/driver-helpers');
const CONFIG = require('../config/test-config');

const SUITE = 'Performance Testing';
const THRESHOLDS = CONFIG.performance;

function makeCases() {
  const cases = [];
  let n = 1;
  const id = () => `PF-${String(n++).padStart(3, '0')}`;
  const add = (title, area, route, expected, run, priority = 'Medium') =>
    cases.push({ id: id(), suite: SUITE, title, area, route, expected, priority, run });

  // ── Utility: format metrics for report ────────────────────────────────────
  function metricsStr(m) {
    if (!m) return 'metrics unavailable';
    return [
      `TTFB=${m.ttfb}ms`,
      `DOMContentLoaded=${m.domContentLoaded}ms`,
      `PageLoad=${m.pageLoad}ms`,
      `DOMInteractive=${m.domInteractive}ms`,
      `TransferSize=${m.transferSize}B`,
    ].join(' | ');
  }

  // ── 1. Page load time per core route ─────────────────────────────────────
  const perfRoutes = [
    ['/', 'Home'],
    ['/products', 'Products'],
    ['/services', 'Services'],
    ['/about', 'About'],
    ['/account', 'Account'],
    ['/cart', 'Cart'],
    ['/login', 'Login'],
    ['/signup', 'Signup'],
  ];

  for (const [route, name] of perfRoutes) {
    add(`${name} page loads within ${THRESHOLDS.maxPageLoadMs}ms`, 'Page Load', route,
      `Load < ${THRESHOLDS.maxPageLoadMs}ms`,
      async (driver) => {
        await openRoute(driver, route);
        await assertReadablePage(driver);
        const metrics = await getPerformanceMetrics(driver);
        const actual = metricsStr(metrics);
        if (metrics && metrics.pageLoad > 0 && metrics.pageLoad > THRESHOLDS.maxPageLoadMs) {
          throw new Error(`Page load ${metrics.pageLoad}ms exceeds threshold. ${actual}`);
        }
        // Store metrics string in the error field for info
        return actual;
      }, 'High');
  }

  // ── 2. TTFB thresholds ────────────────────────────────────────────────────
  add('Home page TTFB is within acceptable range', 'TTFB', '/',
    'TTFB < 3000ms',
    async (driver) => {
      await openRoute(driver, '/');
      const m = await getPerformanceMetrics(driver);
      if (m && m.ttfb > 3000) throw new Error(`TTFB ${m.ttfb}ms exceeds 3000ms`);
    }, 'High');

  // ── 3. DOM Interactive ────────────────────────────────────────────────────
  add('Home page DOM becomes interactive within 8000ms', 'DOM Interactive', '/',
    'domInteractive < 8000ms',
    async (driver) => {
      await openRoute(driver, '/');
      const m = await getPerformanceMetrics(driver);
      if (m && m.domInteractive > 8000)
        throw new Error(`domInteractive ${m.domInteractive}ms exceeds 8000ms`);
    });

  // ── 4. Largest Contentful Paint (via web-vitals API / fallback) ───────────
  add('Home page LCP is measured (Flutter canvas-based)', 'LCP', '/',
    'LCP metric captured or gracefully skipped',
    async (driver) => {
      await openRoute(driver, '/');
      await wait(3000);
      const lcp = await executeJs(driver, `
        if (!window.PerformanceObserver) return -1;
        const entries = performance.getEntriesByType('largest-contentful-paint');
        return entries.length ? entries[entries.length - 1].startTime : -1;
      `).catch(() => -1);
      // Flutter renders to canvas; LCP may be -1 – that's expected
      if (lcp > 0 && lcp > THRESHOLDS.maxLCPMs)
        throw new Error(`LCP ${lcp}ms exceeds ${THRESHOLDS.maxLCPMs}ms`);
    }, 'Medium');

  // ── 5. Memory usage ───────────────────────────────────────────────────────
  add('Page does not consume excessive JS heap memory', 'Memory', '/',
    'JS heap < 500MB',
    async (driver) => {
      await openRoute(driver, '/');
      const heap = await executeJs(driver, `
        const m = window.performance && window.performance.memory;
        return m ? m.usedJSHeapSize : 0;
      `).catch(() => 0);
      const heapMB = Math.round(heap / 1024 / 1024);
      if (heapMB > 500) throw new Error(`JS heap ${heapMB}MB exceeds 500MB`);
    }, 'Medium');

  // ── 6. Resource count ─────────────────────────────────────────────────────
  add('Page loads fewer than 200 resources', 'Resource Count', '/',
    'Resource count < 200',
    async (driver) => {
      await openRoute(driver, '/');
      const count = await executeJs(driver,
        "return window.performance.getEntriesByType('resource').length;");
      if (count > 200) throw new Error(`Resource count ${count} exceeds 200`);
    }, 'Low');

  // ── 7. Navigation type (should be navigate, not reload) ───────────────────
  add('Initial page load uses navigation type "navigate"', 'Navigation Type', '/',
    'navigation type is "navigate"',
    async (driver) => {
      await openRoute(driver, '/');
      const navType = await executeJs(driver, `
        const nav = window.performance.getEntriesByType('navigation')[0];
        return nav ? nav.type : 'unknown';
      `);
      if (navType !== 'navigate' && navType !== 'unknown')
        throw new Error(`Navigation type: ${navType}`);
    }, 'Low');

  // ── 8. Rapid navigation performance ──────────────────────────────────────
  add('Navigating through 5 routes consecutively completes in <30s', 'Navigation Perf', '/',
    'Multi-page navigation completes within 30s',
    async (driver) => {
      const start = Date.now();
      const routes = ['/', '/products', '/services', '/about', '/account'];
      for (const route of routes) {
        await openRoute(driver, route);
        await assertReadablePage(driver);
      }
      const elapsed = Date.now() - start;
      if (elapsed > 30000) throw new Error(`Multi-navigation took ${elapsed}ms`);
    }, 'High');

  // ── 9. Page size – no extremely large transfers ───────────────────────────
  add('Home page total transfer size is < 20MB', 'Transfer Size', '/',
    'Transfer size < 20MB',
    async (driver) => {
      await openRoute(driver, '/');
      const m = await getPerformanceMetrics(driver);
      if (m && m.transferSize > 20 * 1024 * 1024)
        throw new Error(`Transfer size ${Math.round(m.transferSize / 1024 / 1024)}MB exceeds 20MB`);
    }, 'Medium');

  // ── 10. Concurrent user simulation (sequential batches) ───────────────────
  add('Products page loads correctly after 5 sequential navigations', 'Load Simulation', '/products',
    'Products page renders correctly after repeated visits',
    async (driver) => {
      for (let i = 0; i < 5; i++) {
        await openRoute(driver, '/products');
        await assertReadablePage(driver);
      }
    }, 'Medium');

  return cases;
}

module.exports = { makeCases, SUITE };
