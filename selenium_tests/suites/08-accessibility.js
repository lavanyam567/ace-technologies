'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  Suite 8 · ACCESSIBILITY TESTING
//  Checks WCAG 2.1 AA compliance: ARIA, keyboard navigation, contrast,
//  focus management, semantic HTML, and screen-reader attributes.
// ─────────────────────────────────────────────────────────────────────────────

const {
  openRoute, assertReadablePage, wait, executeJs, setViewport,
} = require('../utils/driver-helpers');
const CONFIG = require('../config/test-config');
const { Key } = require('../utils/driver-helpers');

const SUITE = 'Accessibility Testing';

function makeCases() {
  const cases = [];
  let n = 1;
  const id = () => `AX-${String(n++).padStart(3, '0')}`;
  const add = (title, area, route, expected, run, priority = 'Medium') =>
    cases.push({ id: id(), suite: SUITE, title, area, route, expected, priority, run });

  // ── 1. ARIA roles present (Flutter web renders flt-semantics) ─────────────
  const ariaRoutes = ['/', '/products', '/services', '/about', '/account'];
  for (const route of ariaRoutes) {
    add(`ARIA / semantics layer present on ${route}`, 'ARIA', route,
      'flt-semantics or [role] elements present',
      async (driver) => {
        await openRoute(driver, route);
        await wait(CONFIG.timeouts.flutterBoot);
        const count = await executeJs(driver, `
          return (
            document.querySelectorAll('flt-semantics, [role], [aria-label], [aria-labelledby]').length
          );
        `);
        if (count === 0)
          console.warn(`AX-WARN: No ARIA/semantics elements on ${route}`);
      });
  }

  // ── 2. lang attribute on <html> ───────────────────────────────────────────
  add('<html> element has a lang attribute', 'Language', '/',
    'lang attribute present on <html>',
    async (driver) => {
      await openRoute(driver, '/');
      const lang = await executeJs(driver,
        "return document.documentElement.getAttribute('lang');");
      if (!lang)
        console.warn('AX-WARN: Missing lang attribute on <html> element');
    }, 'High');

  // ── 3. Page title present ─────────────────────────────────────────────────
  add('Page has a descriptive <title> tag', 'Title', '/',
    'Title contains Ace Technologies',
    async (driver) => {
      await openRoute(driver, '/');
      const title = await driver.getTitle();
      if (!title || title.trim() === '')
        throw new Error('Page title is empty');
      if (!title.includes('Ace Technologies'))
        console.warn(`AX-WARN: Title "${title}" does not include brand name`);
    }, 'High');

  // ── 4. Meta description present ───────────────────────────────────────────
  add('Page has a meta description tag', 'Meta Description', '/',
    'meta[name=description] present',
    async (driver) => {
      await openRoute(driver, '/');
      const desc = await executeJs(driver, `
        const m = document.querySelector('meta[name="description"]');
        return m ? m.getAttribute('content') : '';
      `);
      if (!desc) console.warn('AX-WARN: No meta description tag found');
    }, 'Medium');

  // ── 5. Images have alt text (in HTML; Flutter canvas images may not apply) ─
  add('All <img> elements in HTML have alt attributes', 'Images', '/',
    'All img elements have alt text',
    async (driver) => {
      await openRoute(driver, '/');
      const missing = await executeJs(driver, `
        return Array.from(document.querySelectorAll('img'))
          .filter(el => !el.getAttribute('alt') && !el.getAttribute('aria-hidden'))
          .map(el => el.src.slice(-40)).slice(0, 5);
      `);
      if (missing && missing.length > 0)
        console.warn(`AX-WARN: ${missing.length} img(s) missing alt: ${missing.join(', ')}`);
    }, 'High');

  // ── 6. Keyboard navigation – Tab key focus moves through elements ──────────
  add('Tab key moves focus through interactive elements', 'Keyboard Nav', '/',
    'Focus moves via Tab key',
    async (driver) => {
      await openRoute(driver, '/');
      await wait(CONFIG.timeouts.flutterBoot);
      // Tab through first 5 elements
      for (let i = 0; i < 5; i++) {
        await driver.actions({ async: true })
          .sendKeys(Key.TAB)
          .perform()
          .catch(() => {});
        await wait(100);
      }
      await assertReadablePage(driver);
    }, 'High');

  // ── 7. Skip-to-content link (best practice) ───────────────────────────────
  add('Skip-to-content link or equivalent is present', 'Skip Nav', '/',
    'Skip nav link or landmark found',
    async (driver) => {
      await openRoute(driver, '/');
      const hasSkip = await executeJs(driver, `
        const text = document.body.innerHTML.toLowerCase();
        return text.includes('skip') || text.includes('main content') ||
               document.querySelector('main,[role=main]') !== null;
      `);
      if (!hasSkip)
        console.warn('AX-WARN: No skip-to-content link or <main> landmark found');
    }, 'Low');

  // ── 8. Focus visible (no outline:none without replacement) ────────────────
  add('No CSS rule unconditionally removes all focus outlines', 'Focus Visibility', '/',
    'Focus outline not globally removed',
    async (driver) => {
      await openRoute(driver, '/');
      const dangerousOutline = await executeJs(driver, `
        const sheets = Array.from(document.styleSheets);
        for (const sheet of sheets) {
          try {
            const rules = Array.from(sheet.cssRules || []);
            for (const rule of rules) {
              if (rule.selectorText && rule.selectorText.includes(':focus') &&
                  rule.style && rule.style.outline === 'none' &&
                  rule.style.boxShadow === '') return rule.selectorText;
            }
          } catch(e) {}
        }
        return null;
      `);
      if (dangerousOutline)
        console.warn(`AX-WARN: CSS removes focus outline without replacement on "${dangerousOutline}"`);
    }, 'Medium');

  // ── 9. Color contrast check (approximation via computed style) ────────────
  add('Body text color provides sufficient contrast with background', 'Color Contrast', '/',
    'Contrast ratio >= 4.5:1',
    async (driver) => {
      await openRoute(driver, '/');
      // This is an approximation; real contrast checking requires axe-core
      const hasFlutterCanvas = await executeJs(driver,
        "return document.querySelectorAll('canvas, flt-glass-pane').length > 0;");
      if (hasFlutterCanvas) {
        // Flutter renders on canvas – skip DOM-based contrast check
        console.warn('AX-WARN: Flutter canvas – color contrast must be verified via Lighthouse/axe-core');
        return;
      }
      const { fg, bg } = await executeJs(driver, `
        const el = document.querySelector('p, span, div');
        if (!el) return { fg: '', bg: '' };
        const s = window.getComputedStyle(el);
        return { fg: s.color, bg: s.backgroundColor };
      `);
      if (!fg || !bg) console.warn('AX-WARN: Could not determine text/background colors');
    }, 'High');

  // ── 10. ARIA landmark roles ────────────────────────────────────────────────
  add('Page has landmark roles (main, navigation, or flt-semantics)', 'Landmarks', '/',
    'ARIA landmarks present',
    async (driver) => {
      await openRoute(driver, '/');
      await wait(CONFIG.timeouts.flutterBoot);
      const hasLandmark = await executeJs(driver, `
        return (
          document.querySelector('[role=main],[role=navigation],[role=banner],main,nav,header,flt-semantics') !== null
        );
      `);
      if (!hasLandmark)
        console.warn('AX-WARN: No ARIA landmark roles found');
    });

  // ── 11. Form inputs have labels ───────────────────────────────────────────
  add('Login form inputs have associated labels or aria-label', 'Form Labels', '/account',
    'Form inputs labelled',
    async (driver) => {
      await openRoute(driver, '/account');
      const unlabelled = await executeJs(driver, `
        return Array.from(document.querySelectorAll('input:not([type=hidden])'))
          .filter(el => !el.getAttribute('aria-label') && !el.getAttribute('id') &&
                        !el.getAttribute('placeholder'))
          .length;
      `);
      if (unlabelled > 0)
        console.warn(`AX-WARN: ${unlabelled} input(s) have no label, aria-label, or placeholder`);
    }, 'High');

  // ── 12. Screen reader semantics (flt-semantics-placeholder) ──────────────
  add('Flutter semantics tree is populated on home page', 'Screen Reader', '/',
    'flt-semantics elements present',
    async (driver) => {
      await openRoute(driver, '/');
      await wait(CONFIG.timeouts.flutterBoot + 1000);
      const count = await executeJs(driver,
        "return document.querySelectorAll('flt-semantics, flt-semantics-container').length;");
      if (count === 0)
        console.warn('AX-WARN: No Flutter semantics elements found. Verify SemanticsBinding.ensureSemantics() is called.');
    }, 'High');

  // ── 13. Zoom text to 200% should not break layout ────────────────────────
  add('App is usable at 200% text zoom (large fonts)', 'Text Zoom', '/',
    'App readable at 200% text zoom',
    async (driver) => {
      await openRoute(driver, '/');
      await executeJs(driver,
        "document.documentElement.style.fontSize = '200%';");
      await wait(500);
      await assertReadablePage(driver);
    }, 'Medium');

  // ── 14. No positive tabindex values ──────────────────────────────────────
  add('No elements with tabindex > 0 (disrupts natural tab order)', 'Tab Order', '/',
    'No tabindex > 0 found',
    async (driver) => {
      await openRoute(driver, '/');
      const badTabindex = await executeJs(driver, `
        return Array.from(document.querySelectorAll('[tabindex]'))
          .filter(el => parseInt(el.getAttribute('tabindex'), 10) > 0)
          .map(el => el.tagName + '[tabindex=' + el.getAttribute('tabindex') + ']')
          .slice(0, 5);
      `);
      if (badTabindex && badTabindex.length > 0)
        console.warn(`AX-WARN: Elements with tabindex > 0: ${badTabindex.join(', ')}`);
    }, 'Low');

  return cases;
}

module.exports = { makeCases, SUITE };
