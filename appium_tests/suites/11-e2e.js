'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  Suite 11 · END-TO-END (E2E) TESTING
//  Full user journeys: browse, search, auth validation, checkout, and admin.
// ─────────────────────────────────────────────────────────────────────────────

const {
  openRoute, assertReadablePage, assertAnyText, assertAllText,
  clickText, fillInputByPlaceholder, wait, scrollPage, setOrientation
} = require('../utils/driver-helpers');
const CONFIG = require('../config/test-config');

const SUITE = 'End-to-End (E2E) Testing';

/** Build the list of E2E test cases. */
function makeCases() {
  const cases = [];
  let n = 1;
  const id = () => `AE2E-${String(n++).padStart(3, '0')}`;
  const add = (title, area, route, expected, run, priority = 'Critical') =>
    cases.push({ id: id(), suite: SUITE, title, area, route, expected, priority, run });

  // ── JOURNEY 1: Guest Browse & Bottom Navigation ───────────────────────────
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
  add('E2E: Guest user searches for products using search route',
    'Search Journey', '/', 'Search renders results or empty state',
    async (driver) => {
      await openRoute(driver, '/');
      await assertReadablePage(driver);

      // Navigate to search
      await openRoute(driver, '/search?q=laptop');
      await assertReadablePage(driver);
      await assertAnyText(driver, ['Search', 'laptop']);
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
      await clickText(driver, 'Create account');
      await assertAnyText(driver, ['Sign Up', 'Create Account', 'Signup']);
    });

  add('E2E: User logs in successfully with valid credentials and views profile',
    'Auth Journey', '/account', 'Successfully logged in and showing profile details',
    async (driver) => {
      await openRoute(driver, '/account');
      await assertAnyText(driver, ['Login to your account', 'Email', 'Login']);

      // Put credentials into the mobile app inputs
      await fillInputByPlaceholder(driver, 'Email', CONFIG.credentials.validEmail);
      await fillInputByPlaceholder(driver, 'Password', CONFIG.credentials.validPassword);

      // Click login button to trigger authentication
      await clickText(driver, 'Login');

      // Verify profile screen shows logged-in status
      await wait(1000);
      await assertAnyText(driver, ['Profile', 'Account', 'Logout']);

      // Cleanup: logout
      await clickText(driver, 'Logout');
    }, 'Critical');

  // ── JOURNEY 4: Cart Journey (Guest) ───────────────────────────────────────
  add('E2E: Guest user views empty cart',
    'Cart Journey', '/cart', 'Cart renders for guest and shows empty state',
    async (driver) => {
      await openRoute(driver, '/cart');
      await assertAnyText(driver, ['Shopping Cart', 'Your cart is empty']);
    });

  // ── JOURNEY 5: Product Discovery Flow ─────────────────────────────────────
  add('E2E: User filter search by categories',
    'Product Discovery', '/products', 'Product filters display correctly',
    async (driver) => {
      await openRoute(driver, '/products');
      await assertReadablePage(driver);

      await openRoute(driver, '/products/filter');
      await assertAnyText(driver, ['Filter', 'Sort']);
    });

  // ── JOURNEY 6: Checkout Flow (Guest) ──────────────────────────────────────
  add('E2E: Guest user accesses checkout address and payment details',
    'Checkout Journey', '/checkout', 'Checkout flow steps load',
    async (driver) => {
      // Add a product to the cart first so the Checkout button becomes visible/active
      await openRoute(driver, '/product/sample-product');
      await clickText(driver, 'Add to Cart');
      await wait(1000);

      await openRoute(driver, '/checkout');
      await assertReadablePage(driver);

      await openRoute(driver, '/checkout/address');
      await assertAnyText(driver, ['Address', 'Select Address']);

      await openRoute(driver, '/checkout/payment');
      await assertAnyText(driver, ['Payment']);
    });

  // ── JOURNEY 7: Wishlist and Compare Flow ──────────────────────────────────
  add('E2E: User views wishlist and compare page',
    'Wishlist Journey', '/wishlist', 'Wishlist and compare screens display',
    async (driver) => {
      // Log in first to make Wishlist and Compare screens accessible from Account
      await openRoute(driver, '/account');
      await fillInputByPlaceholder(driver, 'Email', CONFIG.credentials.validEmail);
      await fillInputByPlaceholder(driver, 'Password', CONFIG.credentials.validPassword);
      await clickText(driver, 'Login');
      await wait(1000);

      await openRoute(driver, '/wishlist');
      await assertReadablePage(driver);

      await openRoute(driver, '/compare');
      await assertAnyText(driver, ['Compare Products', 'Compare']);

      // Cleanup: logout
      await openRoute(driver, '/account');
      await clickText(driver, 'Logout');
    });

  // ── JOURNEY 8: Service Booking Flow ───────────────────────────────────────
  add('E2E: User views service list and schedules a service booking',
    'Service Journey', '/services', 'Service booking flow accessible',
    async (driver) => {
      await openRoute(driver, '/services');
      await assertReadablePage(driver);

      await openRoute(driver, '/service/sample-service');
      await assertReadablePage(driver);
    });

  // ── JOURNEY 9: Orders and Tracking ────────────────────────────────────────
  add('E2E: User views order listings and order tracking details',
    'Orders Journey', '/orders', 'Order details and tracking page displays',
    async (driver) => {
      await openRoute(driver, '/orders');
      await assertReadablePage(driver);

      await openRoute(driver, '/order/test-order/track');
      await assertReadablePage(driver);
    });

  // ── JOURNEY 10: Product Gallery & Write Review Flow ───────────────────────
  add('E2E: User views product details, gallery, and write-review screen',
    'Product Detail Journey', '/product/sample-product', 'Reviews and gallery load',
    async (driver) => {
      await openRoute(driver, '/product/sample-product');
      await assertReadablePage(driver);

      await openRoute(driver, '/product/sample-product/gallery');
      await assertReadablePage(driver);

      await openRoute(driver, '/product/sample-product/write-review');
      await assertReadablePage(driver);
    });

  // ── JOURNEY 11: Admin Control Flow ────────────────────────────────────────
  add('E2E: Admin dashboard screens are accessible',
    'Admin Journey', '/admin/orders', 'Admin order console renders',
    async (driver) => {
      await openRoute(driver, '/admin/orders');
      await assertReadablePage(driver);
    });

  // ── JOURNEY 12: Settings & Profile Flow ───────────────────────────────────
  add('E2E: User navigates through application settings and profile edit views',
    'Settings Journey', '/settings', 'Settings and profile load',
    async (driver) => {
      await openRoute(driver, '/settings');
      await assertReadablePage(driver);

      await openRoute(driver, '/profile');
      await assertReadablePage(driver);
    });

  // ── JOURNEY 13: Rapid Navigation Stability ────────────────────────────────
  add('E2E: Rapid screens switching does not crash Flutter engine',
    'Screen Stability', '/', 'App survives fast route changes',
    async (driver) => {
      const routes = ['/', '/products', '/services', '/about', '/cart', '/account', '/'];
      for (const route of routes) {
        await openRoute(driver, route);
        await wait(200);
      }
      await assertReadablePage(driver);
    }, 'High');

  return cases;
}

module.exports = { makeCases, SUITE };
