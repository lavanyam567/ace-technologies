'use strict';

const {
  clickText,
  fillInputByPlaceholder,
  assertAnyText,
  assertReadablePage,
  wait,
} = require('../utils/driver-helpers');
const { prepareRoute, visitAndAssert, loginIfNeeded, logoutIfNeeded } = require('../utils/session-helpers');
const { screenCatalog, coreNavPairs, authInputCases } = require('../config/mobile-test-catalog');

const SUITE = 'Functional Testing';

function makeCases() {
  const cases = [];
  let n = 1;
  const id = () => `AFN-${String(n++).padStart(3, '0')}`;
  const add = (title, area, route, expected, run, priority = 'High') =>
    cases.push({ id: id(), suite: SUITE, title, area, route, expected, priority, run });

  for (const screen of screenCatalog) {
    add(
      `${screen.area} screen renders with readable content`,
      'Route Rendering',
      screen.route,
      screen.anchors.join(' | '),
      async (driver) => {
        await visitAndAssert(driver, screen);
      },
      screen.loginRequired ? 'Critical' : 'High'
    );

    for (const anchor of screen.anchors) {
      add(
        `${screen.area} screen exposes "${anchor}"`,
        'Content Anchors',
        screen.route,
        anchor,
        async (driver) => {
          await prepareRoute(driver, screen);
          await assertAnyText(driver, anchor);
        },
        'Medium'
      );
    }
  }

  for (const [fromRoute, label, toRoute] of coreNavPairs) {
    add(
      `Navigation label "${label}" moves from ${fromRoute} to ${toRoute}`,
      'Primary Navigation',
      fromRoute,
      label,
      async (driver) => {
        const fromScreen = screenCatalog.find((item) => item.route === fromRoute) || screenCatalog[0];
        const toScreen = screenCatalog.find((item) => item.route === toRoute) || screenCatalog[0];
        await prepareRoute(driver, fromScreen);
        await clickText(driver, label);
        await assertAnyText(driver, toScreen.anchors);
      }
    );
  }

  for (const testInput of authInputCases) {
    add(
      `Authentication validation path: ${testInput.label}`,
      'Authentication',
      '/account',
      testInput.expected,
      async (driver) => {
        await logoutIfNeeded(driver);
        await prepareRoute(driver, screenCatalog.find((item) => item.route === '/account'));
        if (testInput.email) {
          await fillInputByPlaceholder(driver, 'Email', testInput.email);
        }
        if (testInput.password) {
          await fillInputByPlaceholder(driver, 'Password', testInput.password);
        }
        await clickText(driver, 'Login');
        await wait(500);
        await assertAnyText(driver, testInput.expected);
      }
    );
  }

  add(
    'Guest user can open sign-up screen from account',
    'Authentication',
    '/account',
    'Sign Up',
    async (driver) => {
      await logoutIfNeeded(driver);
      await prepareRoute(driver, screenCatalog.find((item) => item.route === '/account'));
      await clickText(driver, 'Create account');
      await assertAnyText(driver, ['Sign Up', 'Create Account', 'Signup']);
    }
  );

  add(
    'Valid user can log in and profile shell becomes visible',
    'Authentication',
    '/account',
    'Profile or Logout',
    async (driver) => {
      await logoutIfNeeded(driver);
      await loginIfNeeded(driver);
      await assertReadablePage(driver);
      await assertAnyText(driver, ['Profile', 'Logout', 'Account']);
      await logoutIfNeeded(driver);
    },
    'Critical'
  );

  add(
    'Logged-in user can open each account feature screen in sequence',
    'Account Features',
    '/profile',
    'Profile, Wishlist, Compare, Recent, Settings, Orders, Service History',
    async (driver) => {
      await loginIfNeeded(driver);
      const featureRoutes = ['/profile', '/wishlist', '/compare', '/recent', '/settings', '/orders', '/service-history'];
      for (const route of featureRoutes) {
        const screen = screenCatalog.find((item) => item.route === route);
        await prepareRoute(driver, screen);
        await assertAnyText(driver, screen.anchors);
      }
      await logoutIfNeeded(driver);
    },
    'Critical'
  );

  add(
    'Checkout shell routes remain readable for guest users',
    'Checkout',
    '/checkout',
    'Checkout route family remains readable',
    async (driver) => {
      const checkoutRoutes = ['/cart', '/checkout', '/checkout/address', '/checkout/payment'];
      for (const route of checkoutRoutes) {
        const screen = screenCatalog.find((item) => item.route === route);
        await prepareRoute(driver, screen);
        await assertReadablePage(driver);
      }
    }
  );

  return cases;
}

module.exports = { makeCases, SUITE };
