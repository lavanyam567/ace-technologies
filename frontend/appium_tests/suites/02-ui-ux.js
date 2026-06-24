'use strict';

const {
  assertAnyText,
  assertReadablePage,
  clickText,
  scrollPage,
} = require('../utils/driver-helpers');
const { prepareRoute, visitAndAssert } = require('../utils/session-helpers');
const { screenCatalog } = require('../config/mobile-test-catalog');

const SUITE = 'UI/UX Testing';

function makeCases() {
  const cases = [];
  let n = 1;
  const id = () => `AUI-${String(n++).padStart(3, '0')}`;
  const add = (title, area, route, expected, run, priority = 'Medium') =>
    cases.push({ id: id(), suite: SUITE, title, area, route, expected, priority, run });

  const primaryRoutes = screenCatalog.filter((screen) => ['/', '/products', '/services', '/about', '/cart', '/account'].includes(screen.route));

  for (const screen of primaryRoutes) {
    add(
      `${screen.area} page remains readable after downward scroll`,
      'Scroll Behavior',
      screen.route,
      'Readable content after scroll',
      async (driver) => {
        await prepareRoute(driver, screen);
        await scrollPage(driver);
        await assertReadablePage(driver);
      },
      'High'
    );

    add(
      `${screen.area} page remains readable after upward recovery scroll`,
      'Scroll Behavior',
      screen.route,
      'Readable content after reverse scroll',
      async (driver) => {
        await prepareRoute(driver, screen);
        await scrollPage(driver);
        await scrollPage(driver, 'up');
        await assertReadablePage(driver);
      }
    );
  }

  for (const screen of primaryRoutes) {
    for (const cta of screen.ctas) {
      add(
        `${screen.area} page exposes CTA "${cta}"`,
        'CTA Discoverability',
        screen.route,
        cta,
        async (driver) => {
          await prepareRoute(driver, screen);
          await assertAnyText(driver, cta);
        }
      );
    }
  }

  const navLabels = ['Home', 'Products', 'Services', 'About Us', 'Cart', 'Account'];
  for (const label of navLabels) {
    add(
      `Bottom navigation label "${label}" stays visible on mobile shell screens`,
      'Navigation UI',
      '/',
      label,
      async (driver) => {
        await prepareRoute(driver, screenCatalog[0]);
        await assertAnyText(driver, label);
      },
      'High'
    );
  }

  const formRoutes = screenCatalog.filter((screen) => ['/account', '/signup', '/checkout/address', '/checkout/payment'].includes(screen.route));
  for (const screen of formRoutes) {
    for (const anchor of screen.anchors.slice(0, Math.min(4, screen.anchors.length))) {
      add(
        `${screen.area} form surface keeps label "${anchor}" visible`,
        'Form Accessibility',
        screen.route,
        anchor,
        async (driver) => {
          await prepareRoute(driver, screen);
          await assertAnyText(driver, anchor);
        }
      );
    }
  }

  const auditScreens = primaryRoutes.concat(screenCatalog.filter((screen) => ['/search?q=laptop', '/products/filter', '/deals', '/notifications'].includes(screen.route)));
  for (const screen of auditScreens) {
    add(
      `${screen.area} screen touch targets stay above guideline threshold`,
      'Touch Targets',
      screen.route,
      'No interactive element below 48dp where measurable',
      async (driver) => {
        await prepareRoute(driver, screen);
        if (driver.__isMock) {
          await assertReadablePage(driver);
          return;
        }

        const clickables = await driver.$$('//*[@clickable="true"]');
        let undersized = 0;
        for (const el of clickables) {
          try {
            const rect = await el.getRect();
            if (rect.width > 0 && rect.height > 0 && (rect.width < 48 || rect.height < 48)) {
              undersized++;
            }
          } catch (_) {}
        }

        if (undersized > 0) {
          throw new Error(`Found ${undersized} clickable elements smaller than 48dp.`);
        }
      },
      'Medium'
    );
  }

  for (const screen of auditScreens) {
    add(
      `${screen.area} screen preserves readable text after tab revisit`,
      'Navigation Resilience',
      screen.route,
      'Readable content after reopening the same screen',
      async (driver) => {
        await visitAndAssert(driver, screen);
        if (screen.navLabel) {
          await clickText(driver, 'Home');
          await clickText(driver, screen.navLabel);
        } else {
          await prepareRoute(driver, screen);
        }
        await assertReadablePage(driver);
      }
    );
  }

  return cases;
}

module.exports = { makeCases, SUITE };
