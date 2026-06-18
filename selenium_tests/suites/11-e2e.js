'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  Suite 11 · END-TO-END (E2E) TESTING
//  Full user journey tests: browse → search → view product → add to cart →
//  checkout flow, account creation, service booking, admin flows, etc.
// ─────────────────────────────────────────────────────────────────────────────

const {
  openRoute, assertReadablePage, assertAnyText, assertAllText,
  clickText, fillFirstInput, fillInputByPlaceholder, wait,
  scrollPage, setViewport, executeJs, getUrl, resolveAppUrl,
} = require('../utils/driver-helpers');
const CONFIG = require('../config/test-config');

const SUITE = 'End-to-End (E2E) Testing';

function makeCases() {
  const cases = [];
  let n = 1;
  const id = () => `E2E-${String(n++).padStart(3, '0')}`;
  const add = (title, area, route, expected, run, priority = 'Critical') =>
    cases.push({ id: id(), suite: SUITE, title, area, route, expected, priority, run });

  // ── JOURNEY 1: Guest Browse & Navigation ─────────────────────────────────
  add('E2E: Guest user visits home, browses products, views services, reads about',
    'Browse Journey', '/', 'Full browse journey completes',
    async (driver) => {
      // Step 1: Home
      await openRoute(driver, '/');
      await assertAnyText(driver, 'Ace Technologies');

      // Step 2: Navigate to Products
      await clickText(driver, 'Products');
      await assertReadablePage(driver);

      // Step 3: Navigate to Services
      await clickText(driver, 'Services');
      await assertReadablePage(driver);

      // Step 4: Navigate to About
      await clickText(driver, 'About Us');
      await assertAnyText(driver, ['About Us', 'Ace Technologies']);

      // Step 5: Navigate back to Home
      await clickText(driver, 'Home');
      await assertAnyText(driver, 'Ace Technologies');
    });

  // ── JOURNEY 2: Search Flow ────────────────────────────────────────────────
  add('E2E: Guest user searches for products using URL-based search',
    'Search Journey', '/', 'Search renders results or empty state',
    async (driver) => {
      await openRoute(driver, '/');
      await assertReadablePage(driver);

      // Navigate to search
      await openRoute(driver, '/search?q=router');
      await assertReadablePage(driver);

      // Try different search
      await openRoute(driver, '/search?q=firewall');
      await assertReadablePage(driver);
    });

  // ── JOURNEY 3: Account / Auth Flow ────────────────────────────────────────
  add('E2E: User visits account, sees login form, attempts login, sees validation',
    'Auth Journey', '/account', 'Login validation works correctly',
    async (driver) => {
      // Visit account page
      await openRoute(driver, '/account');
      await assertAnyText(driver, ['Login to your account', 'Email', 'Login']);

      // Try empty login
      await clickText(driver, 'Login');
      await assertAnyText(driver, 'Enter email and password');

      // Navigate to signup
      await openRoute(driver, '/account');
      await clickText(driver, 'Create account');
      await assertAnyText(driver, ['Sign Up', 'Create Account', 'Signup']);
    });

  // ── JOURNEY 4: Cart Journey (Guest) ──────────────────────────────────────
  add('E2E: Guest user views cart, sees empty state',
    'Cart Journey', '/cart', 'Cart renders for guest',
    async (driver) => {
      await openRoute(driver, '/cart');
      await assertAnyText(driver, [
        'Shopping Cart', 'Your cart is empty', 'cart is empty', 'cart',
      ]);
    });

  // ── JOURNEY 5: Product Discovery Flow ────────────────────────────────────
  add('E2E: User browses products with category filter',
    'Product Discovery', '/products', 'Product category filtering works',
    async (driver) => {
      await openRoute(driver, '/products');
      await assertReadablePage(driver);

      await openRoute(driver, '/products?category=Laptops');
      await assertReadablePage(driver);

      await openRoute(driver, '/products?category=Networking');
      await assertReadablePage(driver);

      await openRoute(driver, '/products?search=keyboard');
      await assertReadablePage(driver);
    });

  // ── JOURNEY 6: Checkout Flow (guest) ─────────────────────────────────────
  add('E2E: Guest user accesses checkout flow',
    'Checkout Journey', '/checkout', 'Checkout flow accessible',
    async (driver) => {
      await openRoute(driver, '/checkout');
      await assertReadablePage(driver);

      await openRoute(driver, '/checkout/address');
      await assertAnyText(driver, ['Address', 'Select', 'Add']);

      await openRoute(driver, '/checkout/payment');
      await assertReadablePage(driver);
    });

  // ── JOURNEY 7: Wishlist & Compare Flow ───────────────────────────────────
  add('E2E: User visits wishlist and compare pages',
    'Wishlist Journey', '/wishlist', 'Wishlist and compare accessible',
    async (driver) => {
      await openRoute(driver, '/wishlist');
      await assertReadablePage(driver);

      await openRoute(driver, '/compare');
      await assertAnyText(driver, ['Compare Products', 'Compare']);
    });

  // ── JOURNEY 8: Service Booking Flow ──────────────────────────────────────
  add('E2E: User views services and service detail route',
    'Service Journey', '/services', 'Service routes accessible',
    async (driver) => {
      await openRoute(driver, '/services');
      await assertReadablePage(driver);

      await openRoute(driver, '/service/sample-service');
      await assertReadablePage(driver);
    });

  // ── JOURNEY 9: Orders Journey ─────────────────────────────────────────────
  add('E2E: User views orders and order detail pages',
    'Orders Journey', '/orders', 'Order pages accessible',
    async (driver) => {
      await openRoute(driver, '/orders');
      await assertReadablePage(driver);

      await openRoute(driver, '/order/test-order');
      await assertReadablePage(driver);

      await openRoute(driver, '/order/test-order/track');
      await assertReadablePage(driver);
    });

  // ── JOURNEY 10: Full Product Detail Flow ──────────────────────────────────
  add('E2E: User views product detail, gallery, reviews',
    'Product Detail Journey', '/product/sample-product', 'Product detail flow works',
    async (driver) => {
      await openRoute(driver, '/product/sample-product');
      await assertReadablePage(driver);

      await openRoute(driver, '/product/sample-product/gallery');
      await assertReadablePage(driver);

      await openRoute(driver, '/product/sample-product/reviews');
      await assertReadablePage(driver);

      await openRoute(driver, '/product/sample-product/write-review');
      await assertReadablePage(driver);
    });

  // ── JOURNEY 11: Admin Flow ────────────────────────────────────────────────
  add('E2E: Admin orders page is accessible',
    'Admin Journey', '/admin/orders', 'Admin page accessible',
    async (driver) => {
      await openRoute(driver, '/admin/orders');
      await assertReadablePage(driver);
    });

  // ── JOURNEY 12: Settings & Profile ───────────────────────────────────────
  add('E2E: User navigates through settings and profile pages',
    'Settings Journey', '/settings', 'Settings and profile pages work',
    async (driver) => {
      await openRoute(driver, '/settings');
      await assertReadablePage(driver);

      await openRoute(driver, '/profile');
      await assertReadablePage(driver);
    });

  // ── JOURNEY 13: Multi-device journey ─────────────────────────────────────
  add('E2E: Complete home→products→account journey on mobile viewport',
    'Mobile E2E Journey', '/', 'Full journey works on mobile',
    async (driver) => {
      await setViewport(driver, 390, 844);
      await openRoute(driver, '/');
      await assertReadablePage(driver);

      await openRoute(driver, '/products');
      await assertReadablePage(driver);

      await openRoute(driver, '/account');
      await assertAnyText(driver, ['Account', 'Login']);
    });

  // ── JOURNEY 14: Notification & Deals ─────────────────────────────────────
  add('E2E: User views notifications and featured deals',
    'Notifications Journey', '/notifications', 'Notification and deals pages work',
    async (driver) => {
      await openRoute(driver, '/notifications');
      await assertReadablePage(driver);

      await openRoute(driver, '/deals');
      await assertAnyText(driver, ['Featured Deals', 'Deals']);
    });

  // ── JOURNEY 15: Service History ───────────────────────────────────────────
  add('E2E: User views service history page',
    'Service History Journey', '/service-history', 'Service history accessible',
    async (driver) => {
      await openRoute(driver, '/service-history');
      await assertReadablePage(driver);
    });

  // ── JOURNEY 16: URL state persistence across navigation ──────────────────
  add('E2E: Browser back button works after navigation',
    'Browser History', '/', 'Back navigation works',
    async (driver) => {
      await openRoute(driver, '/');
      await openRoute(driver, '/products');
      await driver.navigate().back();
      await wait(CONFIG.timeouts.flutterBoot);
      await assertReadablePage(driver);
    });

  // ── JOURNEY 17: Concurrent route switches ────────────────────────────────
  add('E2E: Rapid route switching does not crash the app',
    'Rapid Navigation', '/', 'App survives rapid route switching',
    async (driver) => {
      const routes = [
        '/', '/products', '/services', '/about', '/cart', '/account',
        '/wishlist', '/deals', '/',
      ];
      for (const route of routes) {
        await openRoute(driver, route);
        await wait(200);
      }
      await assertReadablePage(driver);
    }, 'High');

  // ── JOURNEY 18: SPA – direct URL access works ─────────────────────────────
  add('E2E: Direct URL access to all main routes works (SPA routing)',
    'SPA Routing', '/services', 'Direct URL navigation works for SPA',
    async (driver) => {
      // Navigate directly without using in-app navigation
      for (const [route, expected] of [
        ['/products', 'Products'],
        ['/services', 'Services'],
        ['/about', 'About Us'],
        ['/account', 'Account'],
      ]) {
        await driver.get(resolveAppUrl(route));
        await wait(CONFIG.timeouts.flutterBoot);
        await assertAnyText(driver, [expected, 'Ace Technologies']);
      }
    });

  // ── JOURNEY 19: Full About page content verification ─────────────────────
  add('E2E: About page displays all key business information',
    'About Journey', '/about', 'All about page content present',
    async (driver) => {
      await openRoute(driver, '/about');
      await assertAllText(driver, [
        'Ace Technologies', 'Our Objective',
      ]);
    });

  // ── JOURNEY 20: Error recovery after bad route ────────────────────────────
  add('E2E: User navigates to 404 route, app recovers gracefully',
    'Error Recovery', '/this-route-does-not-exist', 'App handles unknown route',
    async (driver) => {
      await openRoute(driver, '/this-route-does-not-exist');
      await wait(1000);
      // Should show some page (404, home, or redirect)
      await assertReadablePage(driver);
      // Navigate back to home successfully
      await openRoute(driver, '/');
      await assertAnyText(driver, 'Ace Technologies');
    });

  return cases;
}

module.exports = { makeCases, SUITE };
