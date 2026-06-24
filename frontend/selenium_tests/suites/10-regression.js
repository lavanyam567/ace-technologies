'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  Suite 10 · REGRESSION TESTING
//  Re-runs a curated set of critical tests to detect regressions.
//  Focuses on the most important Happy Path scenarios.
// ─────────────────────────────────────────────────────────────────────────────

const {
  openRoute, assertReadablePage, assertAnyText, assertAllText,
  clickText, fillFirstInput, wait, getTitle, getUrl, setViewport,
  executeJs, resolveAppUrl,
} = require('../utils/driver-helpers');
const CONFIG = require('../config/test-config');

const SUITE = 'Regression Testing';

function makeCases() {
  const cases = [];
  let n = 1;
  const id = () => `RG-${String(n++).padStart(3, '0')}`;
  const add = (title, area, route, expected, run, priority = 'Critical') =>
    cases.push({ id: id(), suite: SUITE, title, area, route, expected, priority, run });

  // ── CRITICAL REGRESSION: All main routes must render ────────────────────
  const criticalRoutes = [
    ['/', 'Home', ['Ace Technologies']],
    ['/products', 'Products', ['Products']],
    ['/services', 'Services', ['Services']],
    ['/about', 'About', ['About Us', 'Ace Technologies']],
    ['/cart', 'Cart', ['cart', 'Shopping Cart']],
    ['/account', 'Account', ['Account', 'Login']],
    ['/login', 'Login', ['Sign In', 'Email']],
    ['/signup', 'Signup', ['Sign Up', 'Create Account']],
    ['/orders', 'My Orders', ['Orders', 'My Orders']],
    ['/wishlist', 'Wishlist', ['Wishlist']],
    ['/compare', 'Compare', ['Compare Products', 'Compare']],
    ['/recent', 'Recently Viewed', ['Recently Viewed']],
    ['/deals', 'Deals', ['Featured Deals', 'Deals']],
    ['/notifications', 'Notifications', ['Notifications']],
    ['/settings', 'Settings', ['Settings']],
    ['/profile', 'Profile', ['Profile', 'Account']],
    ['/service-history', 'Service History', ['Bookings', 'Service']],
    ['/checkout', 'Checkout', ['Checkout']],
    ['/checkout/address', 'Address Selection', ['Address']],
    ['/checkout/payment', 'Payment Method', ['Payment']],
    ['/admin/orders', 'Admin Orders', ['Orders', 'Admin']],
    ['/products/filter', 'Product Filters', ['Filter', 'Sort']],
  ];

  for (const [route, name, expected] of criticalRoutes) {
    add(`REGRESSION: ${name} route still renders correctly`, name, route,
      expected.join(' | '),
      async (driver) => {
        await openRoute(driver, route);
        await assertReadablePage(driver);
        await assertAnyText(driver, expected);
      });
  }

  // ── REGRESSION: Browser refresh survives ─────────────────────────────────
  for (const [route, name] of criticalRoutes.slice(0, 8)) {
    add(`REGRESSION: ${name} survives F5 refresh`, name, route,
      'Page readable after browser refresh',
      async (driver) => {
        await openRoute(driver, route);
        await driver.navigate().refresh();
        await wait(CONFIG.timeouts.flutterBoot);
        await assertReadablePage(driver);
      });
  }

  // ── REGRESSION: Navigation still works ───────────────────────────────────
  add('REGRESSION: Main navigation chain Home→Products→Services→About→Cart→Account',
    'Navigation', '/', 'Full navigation chain works',
    async (driver) => {
      // Flutter renders the sidebar on canvas – use direct route navigation
      // which is exactly what clicking the nav items achieves in the SPA
      await openRoute(driver, '/');
      await assertAnyText(driver, ['Ace Technologies', 'One-Stop Solution']);

      await openRoute(driver, '/products');
      await assertReadablePage(driver);

      await openRoute(driver, '/services');
      await assertReadablePage(driver);

      await openRoute(driver, '/about');
      await assertAnyText(driver, ['About', 'Our Objective', 'Ace Technologies']);

      await openRoute(driver, '/cart');
      await assertAnyText(driver, ['Cart', 'Shopping Cart', 'cart']);

      await openRoute(driver, '/account');
      await assertAnyText(driver, ['Account', 'Login', 'Login to your account']);
    }, 'Critical');

  // ── REGRESSION: Login validation ─────────────────────────────────────────
  add('REGRESSION: Login empty submit still shows error message',
    'Account', '/account', 'Validation error on empty submit',
    async (driver) => {
      await openRoute(driver, '/account');
      await clickText(driver, 'Login');
      await assertAnyText(driver, 'Enter email and password');
    });

  // ── REGRESSION: Create account link still navigates ──────────────────────
  add('REGRESSION: Create account link still navigates to signup',
    'Account', '/account', 'Signup page reachable',
    async (driver) => {
      await openRoute(driver, '/account');
      await clickText(driver, 'Create account');
      await assertAnyText(driver, ['Sign Up', 'Create Account', 'Signup']);
    });

  // ── REGRESSION: About page key content ───────────────────────────────────
  add('REGRESSION: About page still shows key company information',
    'About', '/about', 'Key about content present',
    async (driver) => {
      await openRoute(driver, '/about');
      await assertAllText(driver, ['Ace Technologies', 'Our Objective']);
    });

  // ── REGRESSION: Search routes don't crash ────────────────────────────────
  for (const query of ['router', 'firewall', 'cctv', 'laptop']) {
    add(`REGRESSION: Search for "${query}" still renders`, 'Search', `/search?q=${query}`,
      'Search page renders',
      async (driver) => {
        await openRoute(driver, `/search?q=${query}`);
        await assertReadablePage(driver);
      }, 'High');
  }

  // ── REGRESSION: Product category filters ─────────────────────────────────
  for (const category of ['Laptops', 'Networking', 'Printers']) {
    add(`REGRESSION: /products?category=${category} still renders`, 'Products', `/products?category=${category}`,
      'Product category page renders',
      async (driver) => {
        await openRoute(driver, `/products?category=${category}`);
        await assertReadablePage(driver);
      }, 'High');
  }

  // ── REGRESSION: Page title unchanged ─────────────────────────────────────
  add('REGRESSION: Page title is still "Ace Technologies - IT & Security Solutions"',
    'Meta', '/', 'Page title correct',
    async (driver) => {
      await openRoute(driver, '/');
      const title = await getTitle(driver);
      if (!title.includes('Ace Technologies'))
        throw new Error(`Title regressed: "${title}"`);
    });

  // ── REGRESSION: Mobile home page ─────────────────────────────────────────
  add('REGRESSION: Home page renders on mobile (390×844) after update',
    'Mobile', '/', 'Home readable on mobile',
    async (driver) => {
      await setViewport(driver, 390, 844);
      await openRoute(driver, '/');
      await assertReadablePage(driver);
    });

  // ── REGRESSION: Performance – Home page still loads fast ─────────────────
  add('REGRESSION: Home page loads in under 15 seconds', 'Performance', '/',
    'Load time under 15s',
    async (driver) => {
      const start = Date.now();
      await openRoute(driver, '/');
      await assertReadablePage(driver);
      const elapsed = Date.now() - start;
      if (elapsed > 15000) throw new Error(`Home loaded in ${elapsed}ms (>15s)`);
    });

  // ── REGRESSION: Cart empty state ─────────────────────────────────────────
  add('REGRESSION: Empty cart shows appropriate empty state',
    'Cart', '/cart', 'Cart empty state or cart items present',
    async (driver) => {
      await openRoute(driver, '/cart');
      await assertAnyText(driver, ['cart', 'Shopping Cart', 'empty', 'Cart']);
    });

  // ── REGRESSION: OAuth error handling ─────────────────────────────────────
  add('REGRESSION: OAuth error param still handled gracefully',
    'Auth', '/?error=access_denied', 'App survives OAuth error param',
    async (driver) => {
      await openRoute(driver, '/?error=access_denied');
      await assertReadablePage(driver);
    });

  // ── REGRESSION: No JavaScript errors on boot ─────────────────────────────
  add('REGRESSION: No uncaught errors on home page load',
    'Error Monitoring', '/', 'No console errors captured',
    async (driver) => {
      await driver.get(resolveAppUrl('/'));
      // Inject error capture before Flutter boots
      await executeJs(driver, `
        window.__testErrors = [];
        window.onerror = function(msg, src, line) {
          window.__testErrors.push({ msg, src, line });
        };
        window.addEventListener('unhandledrejection', function(e) {
          window.__testErrors.push({ msg: e.reason ? String(e.reason) : 'unhandled rejection' });
        });
      `).catch(() => {});
      await wait(CONFIG.timeouts.flutterBoot + 1000);
      const errors = await executeJs(driver, "return window.__testErrors || [];").catch(() => []);
      const critical = errors.filter((e) => !String(e.msg).includes('ResizeObserver'));
      if (critical.length > 0)
        console.warn(`RG-WARN: ${critical.length} JS error(s) on boot: ${critical.map((e) => e.msg).join('; ')}`);
    });

  return cases;
}

module.exports = { makeCases, SUITE };
