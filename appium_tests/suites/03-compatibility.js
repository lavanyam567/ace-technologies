'use strict';

const {
  assertReadablePage,
  setOrientation,
  wait,
} = require('../utils/driver-helpers');
const { prepareRoute } = require('../utils/session-helpers');
const { screenCatalog, orientationRoutes } = require('../config/mobile-test-catalog');

const SUITE = 'Compatibility Testing';

function makeCases() {
  const cases = [];
  let n = 1;
  const id = () => `ACP-${String(n++).padStart(3, '0')}`;
  const add = (title, area, route, expected, run, priority = 'Medium') =>
    cases.push({ id: id(), suite: SUITE, title, area, route, expected, priority, run });

  for (const route of orientationRoutes) {
    const screen = screenCatalog.find((item) => item.route === route) || screenCatalog[0];

    add(
      `${screen.area} remains readable in portrait orientation`,
      'Orientation',
      route,
      'Portrait rendering remains readable',
      async (driver) => {
        await setOrientation(driver, 'PORTRAIT');
        await prepareRoute(driver, screen);
        await assertReadablePage(driver);
      },
      'High'
    );

    add(
      `${screen.area} remains readable in landscape orientation`,
      'Orientation',
      route,
      'Landscape rendering remains readable',
      async (driver) => {
        await setOrientation(driver, 'LANDSCAPE');
        await prepareRoute(driver, screen);
        await assertReadablePage(driver);
        await setOrientation(driver, 'PORTRAIT');
      },
      'High'
    );

    add(
      `${screen.area} survives rapid rotation on the same screen`,
      'Rotation Stability',
      route,
      'No crash when switching orientation rapidly',
      async (driver) => {
        await prepareRoute(driver, screen);
        await setOrientation(driver, 'LANDSCAPE');
        await wait(300);
        await setOrientation(driver, 'PORTRAIT');
        await wait(300);
        await setOrientation(driver, 'LANDSCAPE');
        await wait(300);
        await setOrientation(driver, 'PORTRAIT');
        await assertReadablePage(driver);
      }
    );

    add(
      `${screen.area} remains stable after orientation change plus route reopen`,
      'Rotation Stability',
      route,
      'Readable after reopen following rotation',
      async (driver) => {
        await setOrientation(driver, 'LANDSCAPE');
        await prepareRoute(driver, screen);
        await setOrientation(driver, 'PORTRAIT');
        await prepareRoute(driver, screen);
        await assertReadablePage(driver);
      }
    );
  }

  return cases;
}

module.exports = { makeCases, SUITE };
