'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  Suite 3 · COMPATIBILITY TESTING
//  Verifies layout responsive behaviour when changing screen orientation.
// ─────────────────────────────────────────────────────────────────────────────

const {
  openRoute, assertReadablePage, setOrientation, wait
} = require('../utils/driver-helpers');
const CONFIG = require('../config/test-config');

const SUITE = 'Compatibility Testing';

/** Build the list of compatibility test cases. */
function makeCases() {
  const cases = [];
  let n = 1;
  const id = () => `ACP-${String(n++).padStart(3, '0')}`;
  const add = (title, area, route, expected, run, priority = 'Medium') =>
    cases.push({ id: id(), suite: SUITE, title, area, route, expected, priority, run });

  // ── 1. Portrait Mode Layout ───────────────────────────────────────────────
  add('Portrait Mode: Home screen renders readable content', 'Screen Layout', '/',
    'App renders in portrait orientation',
    async (driver) => {
      await setOrientation(driver, 'PORTRAIT');
      await openRoute(driver, '/');
      await assertReadablePage(driver);
    });

  // ── 2. Landscape Mode Layout ──────────────────────────────────────────────
  add('Landscape Mode: Home screen scales and reflows layout', 'Screen Layout', '/',
    'App layout rotates into landscape and remains readable',
    async (driver) => {
      await setOrientation(driver, 'LANDSCAPE');
      await openRoute(driver, '/');
      await assertReadablePage(driver);
      
      // Reset back to portrait for subsequent tests
      await setOrientation(driver, 'PORTRAIT');
    });

  // ── 3. Screen Rotation Integrity ──────────────────────────────────────────
  add('App survives rapid orientation rotation toggle', 'Screen Stability', '/',
    'Rotates between modes and remains stable',
    async (driver) => {
      await openRoute(driver, '/');
      await setOrientation(driver, 'LANDSCAPE');
      await wait(400);
      await setOrientation(driver, 'PORTRAIT');
      await wait(400);
      await assertReadablePage(driver);
    });

  return cases;
}

module.exports = { makeCases, SUITE };
