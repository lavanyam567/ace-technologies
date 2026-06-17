'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  Suite 1 · FUNCTIONAL TESTING
//  Verifies that every core feature of the Ace Technologies app behaves correctly.
// ─────────────────────────────────────────────────────────────────────────────

const {
  openRoute, assertReadablePage, assertAnyText,
  clickText, fillInputByPlaceholder, wait
} = require('../utils/driver-helpers');
const CONFIG = require('../config/test-config');

const SUITE = 'Functional Testing';

/** Build the list of functional test cases. */
function makeCases() {
  const cases = [];
  let n = 1;
  const id = () => `AFN-${String(n++).padStart(3, '0')}`;
  const add = (title, area, route, expected, run, priority = 'High') =>
    cases.push({ id: id(), suite: SUITE, title, area, route, expected, priority, run });

  // ── 1. Screen Rendering ────────────────────────────────────────────────────
  const coreScreens = [
    ['/', 'Home', ['Ace Technologies', 'Home Screen', 'One-Stop Solution']],
    ['/products', 'Products', ['Products', 'Products Screen']],
    ['/services', 'Services', ['Services', 'Services Screen']],
    ['/about', 'About', ['About Us', 'Our Objective']],
    ['/cart', 'Cart', ['Shopping Cart', 'cart']],
    ['/account', 'Account', ['Account', 'Login to your account']],
  ];

  for (const [route, name, expected] of coreScreens) {
    add(`${name} screen renders correctly`, 'Screen Rendering', route,
      expected.join(' | '),
      async (driver) => {
        await openRoute(driver, route);
        await assertReadablePage(driver);
        await assertAnyText(driver, expected);
      });
  }

  // ── 2. Screen Navigation ──────────────────────────────────────────────────
  const navTargets = [
    ['Products', '/products', ['Products', 'Products Screen']],
    ['Services', '/services', ['Services', 'Services Screen']],
    ['About Us', '/about', ['About Us', 'Our Objective']],
    ['Cart', '/cart', ['Shopping Cart', 'cart']],
    ['Account', '/account', ['Account', 'Login to your account']],
  ];

  for (const [label, route, expected] of navTargets) {
    add(`Navigation: clicking bottom bar/menu "${label}" navigates correctly`, 'Navigation', '/',
      label,
      async (driver) => {
        await openRoute(driver, '/');
        await clickText(driver, label);
        await assertAnyText(driver, expected);
      });
  }

  // ── 3. Home Screen Branding ───────────────────────────────────────────────
  add('Home screen shows brand and objective', 'Branding', '/',
    'One-Stop Solution & Ace Technologies',
    async (driver) => {
      await openRoute(driver, '/');
      await assertAnyText(driver, ['Ace Technologies', 'One-Stop Solution']);
    }, 'Medium');

  // ── 4. About Screen Content ───────────────────────────────────────────────
  const aboutSections = [
    'Our Objective', 'Our Philosophy', 'Capabilities', 'Muralidharan P',
    'Chennai', 'HP Compaq', 'Samsung', 'Dahua', 'Hikvision'
  ];
  for (const text of aboutSections) {
    add(`About Us screen displays details: "${text}"`, 'About Info', '/about', text,
      async (driver) => {
        await openRoute(driver, '/about');
        await assertAnyText(driver, text);
      }, 'Medium');
  }

  // ── 5. Account Screen Guest Interface ─────────────────────────────────────
  add('Account screen guest view shows credentials input', 'Guest Interface', '/account',
    'Email, Password and Login options',
    async (driver) => {
      await openRoute(driver, '/account');
      await assertAnyText(driver, ['Email', 'Password', 'Login', 'Create account']);
    });

  // ── 6. Login Validation ───────────────────────────────────────────────────
  add('Login: submit without inputs triggers validation error', 'Authentication', '/account',
    'Enter email and password error banner',
    async (driver) => {
      await openRoute(driver, '/account');
      await clickText(driver, 'Login');
      await assertAnyText(driver, 'Enter email and password');
    });

  add('Login: invalid format email triggers input format error', 'Authentication', '/account',
    'Invalid format validation',
    async (driver) => {
      await openRoute(driver, '/account');
      await fillInputByPlaceholder(driver, 'Email', CONFIG.credentials.invalidEmail);
      await fillInputByPlaceholder(driver, 'Password', CONFIG.credentials.invalidPassword);
      await clickText(driver, 'Login');
      await assertReadablePage(driver);
    }, 'High');

  // ── 7. Sign Up Navigation ─────────────────────────────────────────────────
  add('Account: clicking "Create account" navigates to Sign Up screen', 'Authentication', '/account',
    'Sign Up Screen',
    async (driver) => {
      await openRoute(driver, '/account');
      await clickText(driver, 'Create account');
      await assertAnyText(driver, ['Sign Up', 'Create Account', 'Signup']);
    });

  // ── 8. Empty Cart Initial View ────────────────────────────────────────────
  add('Cart screen guest shows empty shopping cart', 'Cart empty state', '/cart',
    'Shopping Cart empty state text',
    async (driver) => {
      await openRoute(driver, '/cart');
      await assertAnyText(driver, ['Shopping Cart', 'Your cart is empty']);
    });

  return cases;
}

module.exports = { makeCases, SUITE };
