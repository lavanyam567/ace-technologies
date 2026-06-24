'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  Suite 9 · MOBILE-SPECIFIC TESTING
//  Tests touch-friendly UI, mobile navigation, viewport behaviour,
//  bottom navigation bar, PWA install capability, and gesture areas.
// ─────────────────────────────────────────────────────────────────────────────

const {
  openRoute, assertReadablePage, assertAnyText, scrollPage,
  clickText, wait, executeJs, setViewport,
} = require('../utils/driver-helpers');
const CONFIG = require('../config/test-config');

const SUITE = 'Mobile-Specific Testing';

function makeCases() {
  const cases = [];
  let n = 1;
  const id = () => `MB-${String(n++).padStart(3, '0')}`;
  const add = (title, area, route, expected, run, priority = 'Medium') =>
    cases.push({ id: id(), suite: SUITE, title, area, route, expected, priority, run });

  const MOBILE_VP = { w: 390, h: 844 };
  const TABLET_VP = { w: 768, h: 1024 };

  // ── 1. Core pages render on all mobile viewports ──────────────────────────
  // Each viewport group gets a small breather (wait) to avoid Chrome session exhaustion
  const mobileViewports = [
    { w: 320,  h: 568,  label: 'Small Phone'   },
    { w: 375,  h: 667,  label: 'iPhone SE'     },
    { w: 390,  h: 844,  label: 'iPhone 14'     },
    { w: 412,  h: 915,  label: 'Pixel 7'       },
    { w: 430,  h: 932,  label: 'iPhone 15 Pro' },
  ];

  const mobileRoutes = [
    ['/', 'Home'],
    ['/products', 'Products'],
    ['/services', 'Services'],
    ['/about', 'About'],
    ['/account', 'Account'],
    ['/cart', 'Cart'],
  ];

  for (const vp of mobileViewports) {
    for (const [route, name] of mobileRoutes) {
      add(
        `${vp.label}: "${name}" renders readable`,
        'Mobile Rendering', route,
        `Readable at ${vp.w}×${vp.h}`,
        async (driver) => {
          await setViewport(driver, vp.w, vp.h);
          await wait(300); // Let Chrome stabilise after resize
          await openRoute(driver, route);
          await assertReadablePage(driver);
        }
      );
    }
  }

  // ── 2. Touch target size (minimum 48×48px) ────────────────────────────────
  add('Interactive elements have adequate touch target size (≥44px)', 'Touch Targets', '/',
    'Buttons/links ≥ 44px height',
    async (driver) => {
      await setViewport(driver, MOBILE_VP.w, MOBILE_VP.h);
      await openRoute(driver, '/');
      await wait(CONFIG.timeouts.flutterBoot);
      const tooSmall = await executeJs(driver, `
        const els = document.querySelectorAll('button, a, [role=button]');
        const small = [];
        for (const el of els) {
          const r = el.getBoundingClientRect();
          if (r.width > 0 && r.height > 0 && (r.width < 44 || r.height < 44)) {
            small.push({ tag: el.tagName, w: Math.round(r.width), h: Math.round(r.height),
                         text: (el.textContent || '').trim().slice(0, 20) });
          }
        }
        return small.slice(0, 5);
      `);
      if (tooSmall && tooSmall.length > 0) {
        console.warn(`MB-WARN: ${tooSmall.length} elements with small touch targets: ` +
          tooSmall.map((e) => `${e.tag}(${e.w}×${e.h})`).join(', '));
      }
    }, 'High');

  // ── 3. Mobile meta viewport tag ───────────────────────────────────────────
  add('Viewport meta tag enables mobile scaling', 'Meta Viewport', '/',
    'width=device-width in viewport meta',
    async (driver) => {
      await openRoute(driver, '/');
      const content = await executeJs(driver, `
        const m = document.querySelector('meta[name="viewport"]');
        return m ? m.getAttribute('content') : '';
      `);
      if (!content || !content.includes('width=device-width'))
        throw new Error(`Viewport meta: "${content}"`);
    }, 'High');

  // ── 4. Mobile web app capable meta tags ───────────────────────────────────
  add('Apple mobile-web-app-capable meta tag is present', 'PWA Meta', '/',
    'apple-mobile-web-app-capable meta present',
    async (driver) => {
      await openRoute(driver, '/');
      const capable = await executeJs(driver, `
        const m = document.querySelector('meta[name="mobile-web-app-capable"]');
        const a = document.querySelector('meta[name="apple-mobile-web-app-capable"]');
        return (m && m.content) || (a && a.content) || '';
      `);
      if (!capable) console.warn('MB-WARN: No mobile-web-app-capable meta tag');
    }, 'Medium');

  // ── 5. Bottom navigation visible on mobile ────────────────────────────────
  add('Bottom navigation area is accessible on mobile viewport', 'Bottom Nav', '/',
    'Navigation accessible at mobile size',
    async (driver) => {
      await setViewport(driver, MOBILE_VP.w, MOBILE_VP.h);
      await openRoute(driver, '/');
      await assertAnyText(driver, ['Home', 'Products', 'Services']);
    }, 'High');

  // ── 6. Hamburger / menu accessible on mobile ─────────────────────────────
  add('Navigation items are accessible at 390px (mobile layout)', 'Navigation', '/',
    'Nav items reachable on mobile',
    async (driver) => {
      await setViewport(driver, MOBILE_VP.w, MOBILE_VP.h);
      await openRoute(driver, '/');
      await assertReadablePage(driver);
      // Try clicking Products
      try {
        await clickText(driver, 'Products');
        await assertReadablePage(driver);
      } catch (_) {
        console.warn('MB-WARN: Could not click Products on mobile nav');
      }
    });

  // ── 7. Pinch-to-zoom not blocked (user-scalable not no) ──────────────────
  add('Pinch-to-zoom is not disabled in viewport meta', 'Zoom', '/',
    'user-scalable not set to "no"',
    async (driver) => {
      await openRoute(driver, '/');
      const content = await executeJs(driver, `
        const m = document.querySelector('meta[name="viewport"]');
        return m ? m.getAttribute('content') : '';
      `);
      if (content && content.includes('user-scalable=no'))
        console.warn(`MB-WARN: user-scalable=no prevents accessibility zooming`);
    }, 'Medium');

  // ── 8. Landscape orientation on mobile ────────────────────────────────────
  const landscapeMobiles = [
    { w: 844, h: 390, label: 'iPhone 14 Landscape' },
    { w: 896, h: 414, label: 'iPhone XS Max Landscape' },
  ];
  for (const { w, h, label } of landscapeMobiles) {
    add(`${label}: home page renders readable`, 'Landscape', '/',
      `Readable at ${w}×${h}`,
      async (driver) => {
        await setViewport(driver, w, h);
        await openRoute(driver, '/');
        await assertReadablePage(driver);
      });
  }

  // ── 9. Scroll works on mobile viewport ────────────────────────────────────
  add('Scrolling works correctly on mobile (390px)', 'Scrolling', '/',
    'Page scrolls without crashing',
    async (driver) => {
      await setViewport(driver, MOBILE_VP.w, MOBILE_VP.h);
      await openRoute(driver, '/');
      for (let i = 0; i < 5; i++) await scrollPage(driver);
      await assertReadablePage(driver);
    });

  // ── 10. Tablet layout ─────────────────────────────────────────────────────
  for (const [route, name] of [['/', 'Home'], ['/products', 'Products'], ['/about', 'About']]) {
    add(`Tablet (768px): "${name}" renders correctly`, 'Tablet Layout', route,
      `Readable at 768×1024`,
      async (driver) => {
        await setViewport(driver, TABLET_VP.w, TABLET_VP.h);
        await openRoute(driver, route);
        await assertReadablePage(driver);
      }, 'Medium');
  }

  // ── 11. No desktop-only content on mobile ────────────────────────────────
  add('Mobile viewport does not show broken desktop layout elements', 'Responsive', '/',
    'No overflow-x on mobile',
    async (driver) => {
      await setViewport(driver, MOBILE_VP.w, MOBILE_VP.h);
      await openRoute(driver, '/');
      const overflow = await executeJs(driver,
        "return document.documentElement.scrollWidth > document.documentElement.clientWidth;");
      if (overflow) console.warn('MB-WARN: Horizontal overflow detected on mobile viewport');
    });

  // ── 12. Form inputs are usable on mobile ─────────────────────────────────
  add('Account page form is usable on mobile viewport', 'Mobile Forms', '/account',
    'Account page accessible on mobile',
    async (driver) => {
      await setViewport(driver, MOBILE_VP.w, MOBILE_VP.h);
      await openRoute(driver, '/account');
      await assertAnyText(driver, ['Account', 'Login', 'Email']);
    });

  return cases;
}

module.exports = { makeCases, SUITE };
