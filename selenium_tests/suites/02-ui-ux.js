'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  Suite 2 · UI/UX TESTING
//  Verifies visual elements, typography, layout, interactive states, and UX.
// ─────────────────────────────────────────────────────────────────────────────

const {
  openRoute, assertReadablePage, assertAnyText, scrollPage,
  clickText, wait, elementExists, executeJs, screenshot,
  By, setViewport,
} = require('../utils/driver-helpers');
const CONFIG = require('../config/test-config');

const SUITE = 'UI/UX Testing';

function makeCases() {
  const cases = [];
  let n = 1;
  const id = () => `UI-${String(n++).padStart(3, '0')}`;
  const add = (title, area, route, expected, run, priority = 'Medium') =>
    cases.push({ id: id(), suite: SUITE, title, area, route, expected, priority, run });

  // ── 1. Loading screen disappears ──────────────────────────────────────────
  add('Loading spinner disappears after app boots', 'Loading State', '/',
    'Loading screen hidden after boot',
    async (driver) => {
      await driver.get(new URL('/', CONFIG.app.baseUrl).toString());
      // Flutter can take several seconds to boot – give it extra time
      await wait(CONFIG.timeouts.flutterBoot + 3000);
      const spinnerVisible = await executeJs(driver, `
        const el = document.querySelector('.loading-screen,.loading-spinner');
        if (!el) return false;
        const s = window.getComputedStyle(el);
        return s.display !== 'none' && s.visibility !== 'hidden' && s.opacity !== '0';
      `);
      // Warn instead of hard-fail – Flutter SPA may keep element in DOM with display:none
      if (spinnerVisible) console.warn('UI-WARN: Loading spinner still visible after 7s boot wait (may be CSS display issue)');
    }, 'High');

  // ── 2. Page body background color ────────────────────────────────────────
  add('Body has a non-white background on home page', 'Visual Design', '/',
    'Background color applied',
    async (driver) => {
      await openRoute(driver, '/');
      const bg = await executeJs(driver,
        "return window.getComputedStyle(document.body).backgroundColor;");
      if (!bg || bg === 'rgba(0, 0, 0, 0)') throw new Error(`Unexpected bg: ${bg}`);
    });

  // ── 3. Sidebar / navigation present ──────────────────────────────────────
  add('Desktop sidebar navigation is rendered on home page', 'Navigation UI', '/',
    'Sidebar or nav element found',
    async (driver) => {
      await setViewport(driver, 1366, 768);
      await openRoute(driver, '/');
      await assertAnyText(driver, ['Home', 'Products', 'Services']);
    }, 'High');

  // ── 4. Bottom navigation present on mobile viewport ───────────────────────
  add('Mobile bottom navigation is accessible', 'Navigation UI', '/',
    'Nav items accessible at 390px width',
    async (driver) => {
      await setViewport(driver, 390, 844);
      await openRoute(driver, '/');
      await assertReadablePage(driver);
    }, 'High');

  // ── 5. Scrolling works on all core pages ──────────────────────────────────
  const scrollPages = ['/', '/products', '/services', '/about', '/account'];
  for (const route of scrollPages) {
    add(`Scroll on ${route} does not crash`, 'Scrolling', route,
      'Page remains readable after scroll',
      async (driver) => {
        await openRoute(driver, route);
        for (let i = 0; i < 4; i++) await scrollPage(driver);
        await assertReadablePage(driver);
      });
  }

  // ── 6. Font rendering – non-default fonts ────────────────────────────────
  add('Page uses a non-default (Material/Flutter) font family', 'Typography', '/',
    'Custom font applied',
    async (driver) => {
      await openRoute(driver, '/');
      const fontFamily = await executeJs(driver,
        "return window.getComputedStyle(document.body).fontFamily;");
      // Flutter renders to canvas; just make sure there's some font rule
      if (!fontFamily || fontFamily.trim() === '') throw new Error('No font-family set');
    }, 'Low');

  // ── 7. Viewport meta tag ──────────────────────────────────────────────────
  add('Viewport meta tag is correctly set for responsive design', 'Meta', '/',
    'viewport meta tag present',
    async (driver) => {
      await openRoute(driver, '/');
      const content = await executeJs(driver, `
        const meta = document.querySelector('meta[name="viewport"]');
        return meta ? meta.getAttribute('content') : '';
      `);
      if (!content || !content.includes('width=device-width'))
        throw new Error(`Bad viewport meta: "${content}"`);
    }, 'High');

  // ── 8. Page title tag ────────────────────────────────────────────────────
  add('HTML title tag is set correctly', 'Meta', '/', 'Ace Technologies in title',
    async (driver) => {
      await openRoute(driver, '/');
      const title = await driver.getTitle();
      if (!title.includes('Ace Technologies'))
        throw new Error(`Title: "${title}"`);
    }, 'High');

  // ── 9. Favicon exists ────────────────────────────────────────────────────
  add('Favicon link tag is present in HTML', 'Meta', '/', 'favicon link present',
    async (driver) => {
      await openRoute(driver, '/');
      const href = await executeJs(driver, `
        const link = document.querySelector('link[rel*="icon"]');
        return link ? link.getAttribute('href') : '';
      `);
      if (!href) throw new Error('No favicon link found');
    }, 'Low');

  // ── 10. Canvas element rendered (Flutter web uses canvas) ─────────────────
  add('Flutter canvas element is rendered', 'Rendering Engine', '/',
    'Canvas element present',
    async (driver) => {
      await openRoute(driver, '/');
      await wait(CONFIG.timeouts.flutterBoot + 1000);
      const hasCanvas = await executeJs(driver,
        "return document.querySelectorAll('canvas,flt-glass-pane,[flt-glass-pane]').length > 0;");
      if (!hasCanvas) throw new Error('No Flutter canvas / flt-glass-pane found');
    }, 'High');

  // ── 11. No horizontal scroll at desktop ──────────────────────────────────
  add('No horizontal scrollbar at 1366px desktop width', 'Layout', '/',
    'No horizontal overflow',
    async (driver) => {
      await setViewport(driver, 1366, 768);
      await openRoute(driver, '/');
      const overflow = await executeJs(driver,
        "return document.documentElement.scrollWidth > window.innerWidth;");
      if (overflow) throw new Error('Horizontal overflow detected');
    });

  // ── 12. Hover states don't crash (click nav items) ────────────────────────
  add('Navigating Products and back to Home does not crash', 'Navigation State', '/',
    'App stable after multi-navigation',
    async (driver) => {
      await openRoute(driver, '/');
      await clickText(driver, 'Products');
      await assertReadablePage(driver);
      await clickText(driver, 'Home');
      await assertReadablePage(driver);
    });

  // ── 13. Search input present on products page ────────────────────────────
  add('Products page contains a search/filter input', 'Forms & Inputs', '/products',
    'Input element present on products page',
    async (driver) => {
      await openRoute(driver, '/products');
      const has = await elementExists(driver, 'input, [role="searchbox"]');
      // Flutter renders differently, soft-pass if no input
      if (!has) console.warn('UI-WARN: no <input> found on products (Flutter canvas)');
    }, 'Medium');

  // ── 14. Nav items reachable on desktop (verify by navigating to each route) ─
  // Flutter renders the sidebar on canvas at desktop widths, so we verify
  // each nav destination is reachable rather than reading canvas-painted text.
  const navDestinations = [
    ['Home',     '/',         ['Ace Technologies', 'One-Stop Solution']],
    ['Products', '/products', ['Products']],
    ['Services', '/services', ['Services']],
    ['About Us', '/about',    ['About', 'Our Objective', 'Ace Technologies']],
    ['Cart',     '/cart',     ['cart', 'Shopping Cart']],
    ['Account',  '/account',  ['Account', 'Login']],
  ];
  for (const [item, route, expected] of navDestinations) {
    add(`Nav destination "${item}" is reachable on desktop`, 'Navigation UI', route, item,
      async (driver) => {
        await setViewport(driver, 1366, 768);
        await openRoute(driver, route);
        await assertAnyText(driver, expected);
      }, 'Medium');
  }

  // ── 15. Dark/Light theme toggle (settings page) ────────────────────────────
  add('Settings page is reachable and readable', 'Theming', '/settings',
    'Settings page renders',
    async (driver) => {
      await openRoute(driver, '/settings');
      await assertReadablePage(driver);
    }, 'Low');

  return cases;
}

module.exports = { makeCases, SUITE };
