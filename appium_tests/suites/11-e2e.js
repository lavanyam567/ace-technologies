'use strict';

const {
  assertAnyText,
  assertReadablePage,
  clickText,
  wait,
} = require('../utils/driver-helpers');
const { prepareRoute, loginIfNeeded, logoutIfNeeded } = require('../utils/session-helpers');
const { screenCatalog, journeyDefinitions } = require('../config/mobile-test-catalog');

const SUITE = 'End-to-End (E2E) Testing';

function makeCases() {
  const cases = [];
  let n = 1;
  const id = () => `AE2E-${String(n++).padStart(3, '0')}`;
  const add = (title, area, route, expected, run, priority = 'Critical') =>
    cases.push({ id: id(), suite: SUITE, title, area, route, expected, priority, run });

  for (const journey of journeyDefinitions) {
    add(
      `Journey: ${journey.title}`,
      'Multi-screen Journey',
      journey.steps[0],
      journey.steps.join(' -> '),
      async (driver) => {
        if (journey.loginRequired) {
          await loginIfNeeded(driver);
        } else {
          await logoutIfNeeded(driver);
        }

        for (const route of journey.steps) {
          const screen = screenCatalog.find((item) => item.route === route) || screenCatalog[0];
          await prepareRoute(driver, screen);
          await assertAnyText(driver, screen.anchors);
        }

        if (journey.loginRequired) {
          await logoutIfNeeded(driver);
        }
      }
    );
  }

  const pairableScreens = screenCatalog.filter((screen) => !screen.loginRequired);
  for (let index = 0; index < pairableScreens.length - 1; index++) {
    const first = pairableScreens[index];
    const second = pairableScreens[index + 1];
    add(
      `Guest can move from ${first.area} to ${second.area} without losing readable state`,
      'Transition Stability',
      first.route,
      `${first.route} -> ${second.route}`,
      async (driver) => {
        await logoutIfNeeded(driver);
        await prepareRoute(driver, first);
        await assertReadablePage(driver);
        await prepareRoute(driver, second);
        await assertReadablePage(driver);
      },
      'High'
    );
  }

  const signedInScreens = screenCatalog.filter((screen) => screen.loginRequired);
  for (const screen of signedInScreens) {
    add(
      `Signed-in user reaches ${screen.area} screen and returns to account shell`,
      'Authenticated Journeys',
      screen.route,
      `${screen.route} reachable after login`,
      async (driver) => {
        await loginIfNeeded(driver);
        await prepareRoute(driver, screen);
        await assertAnyText(driver, screen.anchors);
        await prepareRoute(driver, screenCatalog.find((item) => item.route === '/account'));
        await assertReadablePage(driver);
        await logoutIfNeeded(driver);
      }
    );
  }

  const loopRoutes = ['/', '/products', '/services', '/about', '/cart', '/account'];
  for (let start = 0; start < loopRoutes.length; start++) {
    add(
      `Rapid navigation loop starting from ${loopRoutes[start]} does not destabilize the app`,
      'Stress Journey',
      loopRoutes[start],
      'App stays readable through rapid route changes',
      async (driver) => {
        await logoutIfNeeded(driver);
        const orderedRoutes = loopRoutes.slice(start).concat(loopRoutes.slice(0, start));
        for (const route of orderedRoutes) {
          const screen = screenCatalog.find((item) => item.route === route);
          await prepareRoute(driver, screen);
          await wait(150);
        }
        await assertReadablePage(driver);
      },
      'High'
    );
  }

  const entryPoints = [
    { route: '/', cta: 'Products', expectedRoute: '/products' },
    { route: '/', cta: 'Services', expectedRoute: '/services' },
    { route: '/', cta: 'About Us', expectedRoute: '/about' },
    { route: '/', cta: 'Cart', expectedRoute: '/cart' },
    { route: '/', cta: 'Account', expectedRoute: '/account' },
    { route: '/account', cta: 'Create account', expectedRoute: '/signup' },
    { route: '/cart', cta: 'Checkout', expectedRoute: '/checkout' },
  ];
  for (const entry of entryPoints) {
    add(
      `Entry CTA "${entry.cta}" opens the expected next experience`,
      'Entry Points',
      entry.route,
      entry.expectedRoute,
      async (driver) => {
        const fromScreen = screenCatalog.find((item) => item.route === entry.route) || screenCatalog[0];
        const toScreen = screenCatalog.find((item) => item.route === entry.expectedRoute) || screenCatalog[0];
        await prepareRoute(driver, fromScreen);
        await clickText(driver, entry.cta);
        await assertAnyText(driver, toScreen.anchors);
      }
    );
  }

  for (const screen of screenCatalog) {
    add(
      `Route ${screen.route} remains readable after returning through Home`,
      'Re-entry Journeys',
      screen.route,
      `Home -> ${screen.route}`,
      async (driver) => {
        if (screen.loginRequired) {
          await loginIfNeeded(driver);
        } else {
          await logoutIfNeeded(driver);
        }
        await prepareRoute(driver, screenCatalog[0]);
        await prepareRoute(driver, screen);
        await assertReadablePage(driver);
        await assertAnyText(driver, screen.anchors);
        if (screen.loginRequired) {
          await logoutIfNeeded(driver);
        }
      },
      screen.loginRequired ? 'High' : 'Medium'
    );
  }

  const guestJourneyPairs = [
    ['/', '/products', '/search?q=laptop'],
    ['/', '/services', '/about'],
    ['/', '/cart', '/account'],
    ['/products', '/products/filter', '/cart'],
    ['/about', '/', '/services'],
    ['/cart', '/checkout', '/checkout/payment'],
    ['/account', '/signup', '/account'],
    ['/deals', '/', '/notifications'],
    ['/search?q=laptop', '/products', '/about'],
    ['/services', '/cart', '/account'],
  ];
  for (const steps of guestJourneyPairs) {
    add(
      `Guest short journey covers ${steps.join(' -> ')}`,
      'Guest Journeys',
      steps[0],
      steps.join(' -> '),
      async (driver) => {
        await logoutIfNeeded(driver);
        for (const route of steps) {
          const screen = screenCatalog.find((item) => item.route === route) || screenCatalog[0];
          await prepareRoute(driver, screen);
          await assertReadablePage(driver);
        }
      },
      'High'
    );
  }

  return cases;
}

module.exports = { makeCases, SUITE };
