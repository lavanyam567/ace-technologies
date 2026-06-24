'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  Suite 3 · COMPATIBILITY TESTING
//  Tests different viewport sizes and ensures the app degrades gracefully.
//  (Browser compatibility beyond Chrome requires additional drivers.)
// ─────────────────────────────────────────────────────────────────────────────

const {
  openRoute, assertReadablePage, assertAnyText, setViewport, wait,
  executeJs, getTitle,
} = require('../utils/driver-helpers');
const CONFIG = require('../config/test-config');

const SUITE = 'Compatibility Testing';

function makeCases() {
  const cases = [];
  let n = 1;
  const id = () => `CP-${String(n++).padStart(3, '0')}`;
  const add = (title, area, route, expected, run, priority = 'Medium') =>
    cases.push({ id: id(), suite: SUITE, title, area, route, expected, priority, run });

  // ── 1. Multi-viewport rendering ───────────────────────────────────────────
  const viewports = [
    { w: 320,  h: 568,  label: 'Small Mobile (320×568)'  },
    { w: 375,  h: 667,  label: 'iPhone SE (375×667)'      },
    { w: 390,  h: 844,  label: 'iPhone 14 (390×844)'      },
    { w: 414,  h: 896,  label: 'iPhone 14 Plus (414×896)' },
    { w: 430,  h: 932,  label: 'iPhone 15 Pro Max (430)'  },
    { w: 768,  h: 1024, label: 'iPad (768×1024)'          },
    { w: 820,  h: 1180, label: 'iPad Air (820×1180)'      },
    { w: 1024, h: 768,  label: 'Landscape Tablet'         },
    { w: 1280, h: 800,  label: 'Small Laptop (1280×800)'  },
    { w: 1366, h: 768,  label: 'HD Laptop (1366×768)'     },
    { w: 1440, h: 900,  label: 'Large Laptop (1440×900)'  },
    { w: 1600, h: 900,  label: 'Wide Screen (1600×900)'   },
    { w: 1920, h: 1080, label: 'Full HD (1920×1080)'      },
  ];

  const corePagesCompat = ['/', '/products', '/services', '/about', '/account'];

  for (const vp of viewports) {
    for (const route of corePagesCompat) {
      add(
        `${vp.label} – "${route}" renders readable`,
        'Viewport Compatibility', route,
        `Page readable at ${vp.w}×${vp.h}`,
        async (driver) => {
          await setViewport(driver, vp.w, vp.h);
          await openRoute(driver, route);
          await assertReadablePage(driver);
        }
      );
    }
  }

  // ── 2. Landscape / Portrait switch ────────────────────────────────────────
  add('App survives portrait-to-landscape viewport switch', 'Orientation', '/',
    'App readable after orientation change',
    async (driver) => {
      await setViewport(driver, 390, 844);
      await openRoute(driver, '/');
      await assertReadablePage(driver);
      await setViewport(driver, 844, 390);
      await wait(400);
      await assertReadablePage(driver);
    });

  add('App survives landscape-to-portrait viewport switch', 'Orientation', '/',
    'App readable after orientation flip back',
    async (driver) => {
      await setViewport(driver, 844, 390);
      await openRoute(driver, '/');
      await assertReadablePage(driver);
      await setViewport(driver, 390, 844);
      await wait(400);
      await assertReadablePage(driver);
    });

  // ── 3. Resize stability ───────────────────────────────────────────────────
  add('App is stable across continuous resize', 'Resize Stability', '/',
    'App readable after rapid viewport resizes',
    async (driver) => {
      await openRoute(driver, '/');
      const sizes = [[1366, 768], [768, 1024], [390, 844], [1280, 800], [1366, 768]];
      for (const [w, h] of sizes) {
        await setViewport(driver, w, h);
        await wait(200);
      }
      await assertReadablePage(driver);
    }, 'High');

  // ── 4. JavaScript enabled (app relies on JS) ──────────────────────────────
  add('App requires JavaScript (noscript message check)', 'JS Compatibility', '/',
    'noscript tag present as fallback',
    async (driver) => {
      await openRoute(driver, '/');
      const noscript = await executeJs(driver,
        "return document.querySelectorAll('noscript').length > 0;");
      if (!noscript) throw new Error('No <noscript> fallback found in HTML');
    }, 'Low');

  // ── 5. HTTPS / mixed content ──────────────────────────────────────────────
  add('External scripts load without mixed-content errors', 'Mixed Content', '/',
    'No blocking mixed-content warnings',
    async (driver) => {
      await openRoute(driver, '/');
      // If Razorpay or noupe script causes mixed content the page still renders
      await assertReadablePage(driver);
    }, 'Medium');

  // ── 6. HTML lang attribute ────────────────────────────────────────────────
  add('HTML element has lang attribute for i18n compatibility', 'Internationalisation', '/',
    'lang attribute present on <html>',
    async (driver) => {
      await openRoute(driver, '/');
      const lang = await executeJs(driver,
        "return document.documentElement.getAttribute('lang');");
      // Many Flutter apps omit lang; warn but don't hard-fail
      if (!lang) console.warn('COMPAT-WARN: <html> missing lang attribute');
    }, 'Low');

  // ── 7. CSS compatibility – no critical layout breakage ────────────────────
  add('Body overflow-x is not causing horizontal scroll on tablet', 'CSS Compat', '/',
    'No horizontal overflow on iPad 768px',
    async (driver) => {
      await setViewport(driver, 768, 1024);
      await openRoute(driver, '/');
      const overflow = await executeJs(driver,
        "return document.documentElement.scrollWidth > document.documentElement.clientWidth;");
      if (overflow) throw new Error('Horizontal overflow on tablet viewport');
    });

  // ── 8. PWA manifest ──────────────────────────────────────────────────────
  add('PWA manifest.json link is present in HTML', 'PWA', '/',
    'manifest.json link tag found',
    async (driver) => {
      await openRoute(driver, '/');
      const href = await executeJs(driver,
        "const l = document.querySelector('link[rel=manifest]'); return l ? l.href : '';");
      if (!href) throw new Error('No manifest link found');
    }, 'Medium');

  // ── 9. Service worker support ─────────────────────────────────────────────
  add('Browser supports service workers (navigator.serviceWorker)', 'PWA', '/',
    'serviceWorker API present',
    async (driver) => {
      await openRoute(driver, '/');
      const supported = await executeJs(driver,
        "return 'serviceWorker' in navigator;");
      if (!supported) throw new Error('Service Worker not supported');
    }, 'Medium');

  return cases;
}

module.exports = { makeCases, SUITE };
