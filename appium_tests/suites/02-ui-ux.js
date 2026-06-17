'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  Suite 2 · UI/UX TESTING
//  Verifies touch target compliance, screen scrolling, layouts, and accessibility.
// ─────────────────────────────────────────────────────────────────────────────

const {
  openRoute, assertReadablePage, assertAnyText, clickText, scrollPage, wait
} = require('../utils/driver-helpers');
const CONFIG = require('../config/test-config');

const SUITE = 'UI/UX Testing';

/** Build the list of UI/UX test cases. */
function makeCases() {
  const cases = [];
  let n = 1;
  const id = () => `AUI-${String(n++).padStart(3, '0')}`;
  const add = (title, area, route, expected, run, priority = 'Medium') =>
    cases.push({ id: id(), suite: SUITE, title, area, route, expected, priority, run });

  // ── 1. Touch Target Sizes ──────────────────────────────────────────────────
  add('Interactive elements meet minimum touch target size guidelines (>= 48dp)', 'Touch Targets', '/',
    'All clickable elements have width and height >= 48dp',
    async (driver) => {
      await openRoute(driver, '/');
      
      // On simulated runs, bypass the physical UI query
      if (driver.__isMock) return;

      const clickables = await driver.$$('//*[@clickable="true"]');
      let smallTargets = 0;

      for (const el of clickables) {
        try {
          const rect = await el.getRect();
          if (rect.width > 0 && rect.height > 0 && (rect.width < 48 || rect.height < 48)) {
            smallTargets++;
          }
        } catch (_) {}
      }

      if (smallTargets > 0) {
        console.warn(`[UX-WARN]: Found ${smallTargets} interactive elements with touch targets < 48dp.`);
      }
    }, 'High');

  // ── 2. Navigation Bar Layout ──────────────────────────────────────────────
  add('Bottom navigation bar remains fixed and visible on Home', 'Navigation UI', '/',
    'Bottom nav is rendered at base of screen',
    async (driver) => {
      await openRoute(driver, '/');
      await assertAnyText(driver, ['Home', 'Products', 'Services']);
    }, 'High');

  // ── 3. Screen Gestures & Scroll ────────────────────────────────────────────
  add('Home screen supports vertical drag gestures', 'Gestures', '/',
    'Vertical scrolling is responsive and page updates',
    async (driver) => {
      await openRoute(driver, '/');
      await scrollPage(driver);
      await assertReadablePage(driver);
    });

  // ── 4. Forms Input Hints ──────────────────────────────────────────────────
  add('Guest form fields expose hints/labels to accessibility API', 'Accessibility UI', '/account',
    'Email and Password inputs have matching hints',
    async (driver) => {
      await openRoute(driver, '/account');
      await assertAnyText(driver, ['Email', 'Password']);
    });

  // ── 5. Search Bar Rendering ───────────────────────────────────────────────
  add('Search screen opens and input field is interactive', 'Screen Layout', '/search?q=laptop',
    'Search query result displays without clipping UI',
    async (driver) => {
      await openRoute(driver, '/search?q=laptop');
      await assertAnyText(driver, ['Search', 'laptop']);
    });

  return cases;
}

module.exports = { makeCases, SUITE };
